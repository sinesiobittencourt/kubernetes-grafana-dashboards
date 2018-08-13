{
  local runbook_url = 'https://engineering-handbook.nami.run/sre/runbooks/kubeapi',
  templates_custom: {
    api_percentile: {
      values: '50, 90, 99',
      default: '90',
      hide: '',
    },
    verb_excl: {
      values: '(CONNECT|WATCH)',
      default: '(CONNECT|WATCH)',
      hide: 'variable',
    },
  },
  rows: [
    local t = $.templates_custom;
    {
      title: 'Kube API',
      panels: [
        {
          local this = self,
          title: 'API Error ratio 500s/total (except $verb_excl)',
          formula: |||
            sum by (verb, code)(
              rate(apiserver_request_count{verb!~"$verb_excl", code=~"5.."}[5m])
            ) / ignoring(code) group_left
            sum by (verb)(
              rate(apiserver_request_count[5m])
            )
          |||,
          legend: '{{ verb }} - {{ code }}',
          threshold: 0.01,
          alert: 'KubeAPIErrorRatioHigh',
          alert_expr: |||
            sum by (instance)(
              rate(apiserver_request_count{verb!~"%s", code=~"5.."}[5m])
            ) /
            sum by (instance)(
              rate(apiserver_request_count[5m])
            ) > %s
          ||| % [t.verb_excl.default, this.threshold],
          annotations: {
            summary: 'Kube API 500s ratio is High',
            description: |||
              Issue: Kube API Error ratio on {{ $labels.instance }} is above %s: {{ $value }}
              Playbook: %s#%s
            ||| % [this.threshold, runbook_url, this.alert],
          },
        },

        {
          local this = self,
          title: 'API $api_percentile-th latency[ms] by verb (except $verb_excl)',
          formula: |||
            histogram_quantile (
              0.$api_percentile,
              sum by (le, verb)(
                rate(apiserver_request_latencies_bucket{verb!~"$verb_excl"}[5m])
              )
            ) / 1e3 > 0
          |||,
          legend: '{{ verb }}',
          threshold: 200,
          alert: 'KubeAPILatencyHigh',
          alert_expr: |||
            histogram_quantile (
              0.%s,
              sum by (le, instance)(
                rate(apiserver_request_latencies_bucket{verb!~"%s"}[5m])
              )
            ) / 1e3 > %s
          ||| % [t.api_percentile.default, t.verb_excl.default, this.threshold],
          annotations: {
            summary: 'Kube API Latency is High',
            description: |||
              Issue: Kube API Latency on {{ $labels.instance }} is above %s: {{ $value }}
              Playbook: %s#%s
            ||| % [this.threshold, runbook_url, this.alert],
          },
        },
      ],
    },
    {
      title: 'Kube Control Manager',
      panels: [
        {
          local this = self,
          title: '',
          formula: |||
            sum by (instance)(
              APIServiceRegistrationController_work_duration{quantile="0.9"}
            )
          |||,
          legend: '{{ instance }}',
          threshold: 100,
          alert: 'KubeControllerWorkDurationHigh',
          alert_expr: |||
            sum by (instance)(
              APIServiceRegistrationController_work_duration{quantile="0.9"}
            ) > %s
          ||| % [this.threshold],
          annotations: {
            summary: 'Kube Control Manager workqueue processing is slow',
            description: |||
              Issue: Kube Control Manager on {{ $labels.instance }} work duration is above %s: {{ $value }}
              Playbook: %s#%s
            ||| % [this.threshold, runbook_url, this.alert],
          },
        },
      ],
    },
    {
      title: 'Kube Etcd',
      panels: [
        {
          local this = self,
          title: 'etcd 90th latency[ms] by (operation, instance)',
          formula: |||
            max by (operation, instance)(
              rate(etcd_request_latencies_summary{job="kubernetes_apiservers",quantile="0.9"}[5m]) < Inf
            )/ 1e3
          |||,
          legend: '{{ instance }} - {{ operation }}',
          threshold: 20,
          alert: 'KubeEtcdLatencyHigh',
          alert_expr: |||
            max by (instance)(
              rate(etcd_request_latencies_summary{job="kubernetes_apiservers",quantile="0.9"}[5m]) < Inf
            )/ 1e3 > %s
          ||| % [this.threshold],
          annotations: {
            summary: 'Etcd Latency is High',
            description: |||
              Issue: Kube Etcd latency on {{ $labels.instance }} above %s: {{ $value }}
              Playbook: %s#%s
            ||| % [this.threshold, runbook_url, this.alert],
          },
        },
      ],
    },
  ],
}
