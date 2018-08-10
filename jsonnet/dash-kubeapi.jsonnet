local grafana = import 'grafonnet-lib/grafonnet/grafana.libsonnet';
local template = grafana.template;
local row = grafana.row;
local bitgraf = import 'bitnami_grafana.libsonnet';

local spec = (import "spec-kubeapi.jsonnet");

bitgraf.dash.new(
  'SLA: Kubernetes API',
  tags=['k8s', 'api', 'sla']
)
.addRows([
  row.new(height='250px', title=x.title)
  .addPanel(
    bitgraf.panel.new(x.panel_title)
    .addTarget(
      bitgraf.prom(x.formula, x.graf_legend)
    ) { thresholds: [bitgraf.threshold_gt(x.threshold)] }
  )
  for x in spec.rows
]) {
  templates+: [
    template.custom(x.name, x.values, x.default, hide=x.hide)
    for x in spec.templates_custom
  ]
}
