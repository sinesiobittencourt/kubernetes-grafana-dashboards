{
  templates_custom: [
    {
      name: 'api_percentile',
      values: '50, 90, 99',
      default: '90',
      hide: '',
    },
    {
      name: 'verb_excl',
      values: '(CONNECT|WATCH)',
      default: '(CONNECT|WATCH)',
      hide: 'variable',
    },
  ],
  rows: [
    {
      title: 'API Error rate',
      panels: [
        {
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
        },
      ],
    },
    {
      title: 'API Latency',
      panels: [
        {
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
        },
      ],
    },
    {
      title: 'etcd Latency',
      panels: [
        {
          title: 'etcd 90th latency[ms] by (operation, instance)',
          formula: |||
            sum by (operation, instance)(
              rate(etcd_request_latencies_summary{job="kubernetes_apiservers",quantile="0.9"}[5m]) < Inf
            )/ 1e3
          |||,
          legend: '{{ instance }} - {{ operation }}',
          threshold: 20,
        },
      ],

    },
  ],
}
