# Self-Service Observability

This repository is an Infrastructure as Code (IaC) template for managing observability resources in Splunk Observability Cloud using Terraform/OpenTofu.

## Purpose

This repository provides:
- **Modular observability resources** - reusable modules for charts and dashboards
- [**Provider configuration**](https://registry.terraform.io/providers/splunk-terraform/signalfx/latest/docs) for [Splunk Observability Cloud](https://www.splunk.com/en_us/products/observability-cloud.html)
- **Secure secret handling** patterns via environment variables
- **Production-ready structure** for managing observability at scale

## Prerequisites

- [Terraform](https://www.terraform.io/downloads) or [OpenTofu](https://opentofu.org/) installed
- Access to Splunk Observability Cloud ([free 14-day trial available](https://www.splunk.com/en_us/download/o11y-cloud-free-trial.html))
- Splunk Observability Cloud access token (for managing resources)
- Git for version control

## Repository Structure

```
.
├── README.md                          # This file
├── .gitignore                         # Excludes state files, secrets, and artifacts
├── .editorconfig                      # Consistent code formatting
├── versions.tf                        # Terraform/OpenTofu version and provider requirements
├── providers.tf                       # Splunk Observability provider configuration
├── variables.tf                       # Input variables
├── main.tf                            # Root module orchestration
└── modules/
    └── service_observability/         # Service observability module
        ├── main.tf                    # Module orchestration
        ├── variables.tf               # Module inputs
        ├── outputs.tf                 # Module outputs
        ├── charts/                    # Chart resources
        │   ├── main.tf
        │   ├── variables.tf
        │   ├── outputs.tf
        │   └── versions.tf
        └── dashboards/                # Dashboard resources
            ├── main.tf
            ├── variables.tf
            ├── outputs.tf
            └── versions.tf
```

## Getting Started

### 1. Clone and Initialize

```bash
git clone https://github.com/splunk/evangelism-public.git
cd self-service-observability
terraform init
```

This will download the required providers and initialize the working directory.

### 2. Set Required Variables

Before applying any configuration, set the required variables as environment variables:

```bash
export TF_VAR_splunk_realm="us1"  # or your realm (us0, us1, eu0, etc.)
export TF_VAR_signalfx_access_token="your-access-token-here"
```


### 3. Review and Apply

```bash
# Format code
terraform fmt -recursive

# Validate configuration
terraform validate

# Review planned changes
terraform plan

# Apply changes
terraform apply
```

### 4. View Dashboard

After successful deployment, Terraform will output the dashboard URL. Visit it in your browser to see your observability dashboard.

## Security and Secret Handling

- **Never** commit `.tfvars` files or `.env` files containing secrets
- Use environment variables for sensitive values (`TF_VAR_*` prefix)
- Consider using a secret manager (AWS Secrets Manager, HashiCorp Vault, etc.) for production
- The `.gitignore` is configured to exclude common secret-containing files

## Access Tokens vs Ingest Tokens

- **Ingest Token**: Used for sending metrics, traces, and logs to Splunk Observability Cloud (data plane)
- **Access Token**: Used for managing resources via the API (control plane) - required for this IaC repository

This repository requires a Splunk Observability Cloud **access token** with appropriate permissions to manage resources.

## Current Resources

This repository currently deploys:

- **Dashboard Group**: `self-service-observability - Observability`
- **Dashboard**: `self-service-observability - Overview (dev)`
  - Contains a time chart displaying the `self_service_observability.setup.test` metric
  - Filtered by `service` and `env` dimensions

## Outputs

After applying, the following outputs are available:

- `dashboard_id` - ID of the created dashboard
- `dashboard_url` - Direct URL to view the dashboard in Splunk Observability Cloud
- `chart_id` - ID of the created chart
- `dashboard_group_id` - ID of the dashboard group

## Customization

### Adding More Services

To monitor additional services, you can instantiate the `service_observability` module multiple times in `main.tf`:

```hcl
module "service_observability" {
  source       = "./modules/service_observability"
  service_name = "self-service-observability"
  env          = "dev"
  splunk_realm = var.splunk_realm
}

module "another_service" {
  source       = "./modules/service_observability"
  service_name = "another-service"
  env          = "prod"
  splunk_realm = var.splunk_realm
}
```

### Modifying Charts

Edit `modules/service_observability/charts/main.tf` to customize:
- Chart names and descriptions
- SignalFlow queries
- Metrics and dimensions
- Chart types and visualization options

### Adding More Charts

To add additional charts, create new `signalfx_time_chart` resources in the charts module and pass their IDs to the dashboards module.

## Troubleshooting

### Provider Deprecation Warning

You may see a warning about `api_url` being deprecated. This is informational and can be safely ignored for now. The provider team recommends removing it in future versions, but it's currently required for realm-specific API endpoints.

### Dashboard Not Showing Data

If your dashboard displays but has no data:
1. Verify the metric exists in Splunk Observability Cloud
2. Check that dimensions (`service`, `env`) match your actual metric labels
3. Ensure data is actively being ingested
4. Try adjusting the time range in the dashboard UI

### Authentication Errors

If you receive authentication errors:
1. Verify your access token has API permissions (not just ingest permissions)
2. Check that the token hasn't expired
3. Ensure `TF_VAR_signalfx_access_token` is properly exported
4. Confirm the realm is correct for your organization

## Future Enhancements

Planned additions:
- Detector and alert configurations
- Additional chart types (heatmaps, single values, lists)
- SLO/SLI tracking dashboards
- Multi-environment support patterns
- Pre-commit hooks for validation
- CI/CD pipeline integration


## References

- [OpenTofu Documentation](https://opentofu.org/docs/)
- [Splunk Observability Cloud Provider](https://registry.terraform.io/providers/splunk-terraform/signalfx/latest/docs)
- [Splunk Observability Cloud Documentation](https://docs.splunk.com/Observability)
