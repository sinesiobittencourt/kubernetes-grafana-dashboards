local grafana = import 'grafonnet-lib/grafonnet/grafana.libsonnet';
local template = grafana.template;
local row = grafana.row;
local bitgraf = import 'bitnami_grafana.libsonnet';

local spec = (import 'spec-kubeapi.jsonnet');

bitgraf.dash.new(
  'SLA: Kubernetes API',
  tags=['k8s', 'api', 'sla']
)
.addRows([
  row.new(height='250px', title=x.title)
  .addPanels([
    bitgraf.panel.new(p.title)
    .addTarget(
      bitgraf.prom(p.formula, p.legend)
    ) { thresholds: [bitgraf.threshold_gt(p.threshold)] }
    for p in x.panels
  ])
  for x in spec.rows
]) {
  templates+: [
    template.custom(x.name, x.values, x.default, hide=x.hide)
    for x in spec.templates_custom
  ],
}
