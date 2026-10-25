const months = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]
const pad = (n) => String(n).padStart(2, "0")
const stamp = (value) => {
  const date = new Date(value)
  return `${months[date.getMonth()]} ${pad(date.getDate())} ${pad(date.getHours())}:${pad(date.getMinutes())}`
}

const formatters = {
  "chart-3": (options) => {
    options.tooltip = {...options.tooltip, y: {formatter: (val) => "$ " + val + " thousands"}}
  },
  "chart-4": (options) => {
    options.xaxis.labels = {formatter: (_value, timestamp, opts) => opts.dateFormatter(new Date(timestamp), "dd MMM")}
  },
  "chart-5": (options) => {
    options.xaxis.labels = {formatter: (val) => stamp(val)}
  },
  "chart-7": (options) => {
    options.plotOptions.radialBar.dataLabels.total.formatter = (w) => w.config.series.reduce((s, v) => s + v)
  },
}

window.addEventListener("linea:chart:options", ({target, detail}) => formatters[target.id]?.(detail.options))
