module "charts" {
  source       = "./charts"
  service_name = var.service_name
  env          = var.env
}

module "dashboards" {
  source       = "./dashboards"
  service_name = var.service_name
  env          = var.env
  chart_id     = module.charts.chart_id
  splunk_realm = var.splunk_realm
}
