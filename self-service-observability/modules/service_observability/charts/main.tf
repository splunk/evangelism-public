locals {
  chart_title = "${var.service_name} - Test Metric (${var.env})"
  dim_service = var.service_name
  dim_env     = var.env
}

resource "signalfx_time_chart" "service_test_metric" {
  name        = local.chart_title
  description = "Baseline chart for ${var.service_name} (${var.env})."

  program_text = <<-EOF
A = data('self_service_observability.setup.test', filter=(filter('service', '${local.dim_service}') and filter('env', '${local.dim_env}'))).publish()
EOF
}
