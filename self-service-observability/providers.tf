provider "signalfx" {
  auth_token = var.signalfx_access_token
  api_url    = "https://api.${var.splunk_realm}.signalfx.com"
}
