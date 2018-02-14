# kubernetes-grafana-dashboards

Bitnami grafana dashboards, follow up from https://grafana.com/dashboards/3119
for easier code tracking and sharing.


## Dashboards

* all dashboards use a `$datasource` selector, to ease multi-DS setups
  - FYI in Bitnami we use it to drive a prometheus "federated" setup,
    where we add a `cluster` to scraped prometheis
    [external_labels](https://prometheus.io/docs/prometheus/latest/configuration/configuration/#<scrape_config>)
* the dashboards are linked together, so that you can navigate them as:

  k8s_resource_usage_cluster -> (click up-right) ->
    k8s_resource_usage_namespace -> (select namespace, click up-right) ->
      k8s_resource_usage_namespace_pods

## Prometheus setup

We try to follow latest upstream prometheus, using `prometheus-2.0.1`
on several `kubernetes-1.8.x` clusters at the time of this writing
(Feb/2018).

Prometheus `scrape_configs` excerpt:

~~~~
scrape_configs:
- job_name: kubernetes_apiservers
  scrape_interval: 1m
  scrape_timeout: 30s
  metrics_path: /metrics
  scheme: https
  kubernetes_sd_configs:
  - api_server: null
    role: endpoints
    namespaces:
      names: []
  bearer_token_file: /var/run/secrets/kubernetes.io/serviceaccount/token
  tls_config:
    ca_file: /var/run/secrets/kubernetes.io/serviceaccount/ca.crt
  relabel_configs:
  - source_labels: [__meta_kubernetes_namespace, __meta_kubernetes_service_name, __meta_kubernetes_endpoint_port_name]
    separator: ;
    regex: default;kubernetes;https
    replacement: $1
    action: keep
- job_name: kubernetes_cadvisor
  scrape_interval: 1m
  scrape_timeout: 30s
  metrics_path: /metrics
  scheme: https
  kubernetes_sd_configs:
  - api_server: null
    role: node
    namespaces:
      names: []
  bearer_token_file: /var/run/secrets/kubernetes.io/serviceaccount/token
  tls_config:
    ca_file: /var/run/secrets/kubernetes.io/serviceaccount/ca.crt
  relabel_configs:
  - separator: ;
    regex: __meta_kubernetes_node_label_(.+)
    replacement: $1
    action: labelmap
  - separator: ;
    regex: (.*)
    target_label: __address__
    replacement: kubernetes.default.svc.cluster.local:443
    action: replace
  - separator: ;
    regex: (.*)
    target_label: __scheme__
    replacement: https
    action: replace
  - source_labels: [__meta_kubernetes_node_name]
    separator: ;
    regex: (.+)
    target_label: __metrics_path__
    replacement: /api/v1/nodes/${1}/proxy/metrics/cadvisor
    action: replace
- job_name: kubernetes_nodes
  scrape_interval: 1m
  scrape_timeout: 30s
  metrics_path: /metrics
  scheme: https
  kubernetes_sd_configs:
  - api_server: null
    role: node
    namespaces:
      names: []
  bearer_token_file: /var/run/secrets/kubernetes.io/serviceaccount/token
  tls_config:
    ca_file: /var/run/secrets/kubernetes.io/serviceaccount/ca.crt
  relabel_configs:
  - separator: ;
    regex: __meta_kubernetes_node_label_(.+)
    replacement: $1
    action: labelmap
  - separator: ;
    regex: (.*)
    target_label: __address__
    replacement: kubernetes.default.svc.cluster.local:443
    action: replace
  - separator: ;
    regex: (.*)
    target_label: __scheme__
    replacement: https
    action: replace
  - source_labels: [__meta_kubernetes_node_name]
    separator: ;
    regex: (.+)
    target_label: __metrics_path__
    replacement: /api/v1/nodes/${1}/proxy/metrics
    action: replace
- job_name: kubernetes_pods
  scrape_interval: 1m
  scrape_timeout: 30s
  metrics_path: /metrics
  scheme: http
  kubernetes_sd_configs:
  - api_server: null
    role: pod
    namespaces:
      names: []
  relabel_configs:
  - source_labels: [__meta_kubernetes_pod_annotation_prometheus_io_scrape]
    separator: ;
    regex: "true"
    replacement: $1
    action: keep
  - source_labels: [__meta_kubernetes_pod_annotation_prometheus_io_path]
    separator: ;
    regex: (.+)
    target_label: __metrics_path__
    replacement: $1
    action: replace
  - source_labels: [__address__, __meta_kubernetes_pod_annotation_prometheus_io_port]
    separator: ;
    regex: (.+):(?:\d+);(\d+)
    target_label: __address__
    replacement: ${1}:${2}
    action: replace
  - separator: ;
    regex: __meta_kubernetes_pod_label_(.+)
    replacement: $1
    action: labelmap
  - source_labels: [__meta_kubernetes_namespace]
    separator: ;
    regex: (.*)
    target_label: kubernetes_namespace
    replacement: $1
    action: replace
  - source_labels: [__meta_kubernetes_pod_name]
    separator: ;
    regex: (.*)
    target_label: kubernetes_pod_name
    replacement: $1
    action: replace
- job_name: kubernetes_service_endpoints
  scrape_interval: 1m
  scrape_timeout: 30s
  metrics_path: /metrics
  scheme: http
  kubernetes_sd_configs:
  - api_server: null
    role: endpoints
    namespaces:
      names: []
  relabel_configs:
  - source_labels: [__meta_kubernetes_service_annotation_prometheus_io_scrape]
    separator: ;
    regex: "true"
    replacement: $1
    action: keep
  - source_labels: [__meta_kubernetes_service_annotation_prometheus_io_scheme]
    separator: ;
    regex: (https?)
    target_label: __scheme__
    replacement: $1
    action: replace
  - source_labels: [__meta_kubernetes_service_annotation_prometheus_io_path]
    separator: ;
    regex: (.+)
    target_label: __metrics_path__
    replacement: $1
    action: replace
  - source_labels: [__address__, __meta_kubernetes_service_annotation_prometheus_io_port]
    separator: ;
    regex: (.+)(?::\d+);(\d+)
    target_label: __address__
    replacement: $1:$2
    action: replace
  - separator: ;
    regex: __meta_kubernetes_service_label_(.+)
    replacement: $1
    action: labelmap
  - source_labels: [__meta_kubernetes_namespace]
    separator: ;
    regex: (.*)
    target_label: kubernetes_namespace
    replacement: $1
    action: replace
  - source_labels: [__meta_kubernetes_service_name]
    separator: ;
    regex: (.*)
    target_label: kubernetes_name
    replacement: $1
    action: replace
- job_name: kubernetes_services
  params:
    module:
    - http_2xx
  scrape_interval: 1m
  scrape_timeout: 30s
  metrics_path: /probe
  scheme: http
  kubernetes_sd_configs:
  - api_server: null
    role: service
    namespaces:
      names: []
  relabel_configs:
  - source_labels: [__meta_kubernetes_service_annotation_prometheus_io_probe]
    separator: ;
    regex: "true"
    replacement: $1
    action: keep
  - separator: ;
    regex: __meta_kubernetes_service_label_(.+)
    replacement: $1
    action: labelmap
  - source_labels: [__meta_kubernetes_service_namespace]
    separator: ;
    regex: (.*)
    target_label: kubernetes_namespace
    replacement: $1
    action: replace
  - source_labels: [__meta_kubernetes_service_name]
    separator: ;
    regex: (.*)
    target_label: kubernetes_name
    replacement: $1
    action: replace
  - separator: ;
    regex: __meta_kubernetes_service_annotation_bitnami_com_(.+)
    replacement: $1
    action: labelmap
  - source_labels: [__meta_kubernetes_service_annotation_bitnami_com_vhost]
    separator: ;
    regex: (.*)
    target_label: __param_target
    replacement: $1
    action: replace
  - separator: ;
    regex: (.*)
    target_label: __address__
    replacement: blackbox:9115
    action: replace
- job_name: prometheus
  scrape_interval: 1m
  scrape_timeout: 30s
  metrics_path: /metrics
  scheme: http
  static_configs:
  - targets:
    - localhost:9090
~~~~
