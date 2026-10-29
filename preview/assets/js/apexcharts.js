const formatters = {
  "chart-3": (options) => {
    options.tooltip = {...options.tooltip, y: {formatter: (val) => "$ " + val + " thousands"}}
  },
  "chart-4": (options) => {
    options.xaxis.labels = {formatter: (_value, timestamp, opts) => opts.dateFormatter(new Date(timestamp), "dd MMM")}
  },
  "chart-7": (options) => {
    options.plotOptions.radialBar.dataLabels.total.formatter = (w) => w.config.series.reduce((s, v) => s + v)
  },
}

window.addEventListener("linea:chart:options", ({target, detail}) => formatters[target.id]?.(detail.options))
