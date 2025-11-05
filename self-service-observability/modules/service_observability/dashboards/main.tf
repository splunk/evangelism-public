locals {
  group_name     = "${var.service_name} - Observability"
  dashboard_name = "${var.service_name} - Overview (${var.env})"
}

resource "signalfx_dashboard_group" "svc_group" {
  name        = local.group_name
  description = "Dashboards for ${var.service_name}."

  lifecycle {
    prevent_destroy = false # Set to true in production to prevent accidental deletion
  }
}

resource "signalfx_dashboard" "svc_dashboard" {
  name            = local.dashboard_name
  description     = "Overview dashboard for ${var.service_name} in ${var.env}."
  dashboard_group = signalfx_dashboard_group.svc_group.id

  chart {
    chart_id = var.chart_id
    column   = 0
    row      = 0
    width    = 12
    height   = 6
  }

  lifecycle {
    prevent_destroy = false # Set to true in production to prevent accidental deletion
  }
}
