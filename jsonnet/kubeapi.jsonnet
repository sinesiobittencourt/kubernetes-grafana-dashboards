local grafana = import 'grafonnet-lib/grafonnet/grafana.libsonnet';
local template = grafana.template;
local row = grafana.row;
local bitgraf = import 'bitnami_grafana.libsonnet';

bitgraf.dash.new(
  'SLA: Kubernetes API',
  tags=['k8s', 'api', 'sla']
)
.addTemplate(
  template.custom('api_percentile', '50, 90, 99', '90'),
)
.addTemplate(
  template.custom('verb_excl', '(CONNECT|WATCH)', '(CONNECT|WATCH)', hide='variable')
)
.addRow(
  row.new(height='250px', title='API Error rate')
  .addPanel(
    bitgraf.panel.new('API Error ratio 500s/total (except $verb_excl)')
    .addTarget(
      bitgraf.prom(
        |||
          sum by (verb, code)(
            rate(apiserver_request_count{verb!~"$verb_excl", code=~"5.."}[5m])
          ) / ignoring(code) group_left
          sum by (verb)(
            rate(apiserver_request_count[5m])
          )
        |||,
        '{{ verb }} - {{ code }}',
      )
    ) { thresholds: [bitgraf.threshold_gt(0.01)] }
  )
)
.addRow(
  row.new(height='250px', title='API Latency')
  .addPanel(
    bitgraf.panel.new('API $api_percentile-th latency[ms] by verb (except $verb_excl)')
    .addTarget(
      bitgraf.prom(
        |||
          histogram_quantile (
            0.$api_percentile,
            sum by (le, verb)(
              rate(apiserver_request_latencies_bucket{verb!~"$verb_excl"}[5m])
            )
          ) / 1e3 > 0
        |||,
        '{{ verb }}',
      )
    ) { thresholds: [bitgraf.threshold_gt(200)] }
  )
)
.addRow(
  row.new(height='250px', title='etcd Latency')
  .addPanel(
    bitgraf.panel.new('etcd 90th latency[ms] by (operation, instance)')
    .addTarget(
      bitgraf.prom(
        |||
          sum by (operation, instance)(
            rate(etcd_request_latencies_summary{job="kubernetes_apiservers",quantile="0.9"}[5m]) < Inf
          )/ 1e3
        |||,
        '{{ instance }} - {{ operation }}',
      )
    ) { thresholds: [bitgraf.threshold_gt(20)] }
  )
)
