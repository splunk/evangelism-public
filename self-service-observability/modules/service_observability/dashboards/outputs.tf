output "dashboard_id" {
  description = "Dashboard ID."
  value       = signalfx_dashboard.svc_dashboard.id
}

output "dashboard_group_id" {
  description = "Dashboard group ID."
  value       = signalfx_dashboard_group.svc_group.id
}

output "dashboard_url" {
  description = "Direct URL to the dashboard."
  value       = "https://app.${var.splunk_realm}.signalfx.com/#/dashboard/${signalfx_dashboard.svc_dashboard.id}"
}

output "dashboard_name" {
  description = "Dashboard name."
  value       = signalfx_dashboard.svc_dashboard.name
}

output "dashboard_group_name" {
  description = "Dashboard group name."
  value       = signalfx_dashboard_group.svc_group.name
}
