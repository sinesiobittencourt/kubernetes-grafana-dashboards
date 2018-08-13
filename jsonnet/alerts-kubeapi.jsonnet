local spec = import 'spec-kubeapi.jsonnet';

local ALERTS_NAME = 'kubeapi';
local ALERTS_FOR = '15m';
local ALERTS_LABELS = { severity: 'critical' };

// Get rid of \n and duplicated whitespaces
local cleanupWhiteSpace(str) = (
  std.join(' ', [
    x
    for x in std.split(std.strReplace(str, '\n', ' '), ' ')
    if x != ''
  ])
);

{
  // Pre-process row->panel fields to create `checks` for easier
  // referencing from `rules`
  checks:: [
    {
      formula: panel.formula,
      alert: panel.alert,
      alert_expr: panel.alert_expr,
      threshold: panel.threshold,
      annotations: panel.annotations,
    }
    for row in spec.rows
    for panel in row.panels
  ],
  // Emited `rules` as needed by prometheus alert entries
  rules:: [
    {
      alert: check.alert,
      expr: cleanupWhiteSpace(check.alert_expr),
      'for': ALERTS_FOR,
      labels: ALERTS_LABELS,
      annotations: check.annotations,
    }
    for check in $.checks
  ],
  // See https://prometheus.io/docs/prometheus/latest/configuration/alerting_rules/
  groups: [
    {
      name: ALERTS_NAME,
      rules: $.rules,
    },
  ],
}
