# Evangelism-Public
Public content from Developer Evangelists

This repository contains educational resources, sample applications, and templates to help developers and organizations implement observability best practices with Splunk Observability Cloud.

## Contents

### Manual Instrumentation (`manual-instrumentation/`)

A comprehensive guide and sample application demonstrating how to manually instrument full-stack applications with Splunk Observability Cloud. This section includes:

- **Sample Application**: "Worms in Space" - A complete React TypeScript frontend with Elixir/Phoenix GraphQL backend for scheduling astronaut spacewalks
- **Working Code Examples**: Fully functional application with commit-by-commit instrumentation history
- **Best Practices**: Real-world patterns for custom spans, error handling, and observability

**Key Features Demonstrated**:
- Backend: OpenTelemetry SDK setup, automatic instrumentation (Phoenix, Ecto, GraphQL), custom business logic spans
- Frontend: Splunk RUM integration, Core Web Vitals monitoring, custom user workflow tracking
- Full-stack trace correlation between frontend RUM and backend APM

**Getting Started**: Navigate to `manual-instrumentation/worms_in_space/` and follow the instrumentation guide to see observability implementation in action.

### Observability Center of Excellence (`o11y-center-of-excellence/`)

Resources for establishing and promoting observability initiatives within organizations:

- **`Observability_CoE_Pitch_template.pptx`**: A comprehensive presentation template for pitching an Observability Center of Excellence to leadership and stakeholders. This template helps you articulate the business value, technical benefits, and implementation strategy for enterprise observability programs.

This presentation template is referenced in the Splunk blog post about establishing observability centers of excellence and taking your observability strategy to the next level.

## How to Use This Repository

1. **Learning Manual Instrumentation**: Start with the `manual-instrumentation/` directory to see practical examples of adding observability to real applications
2. **Building Organizational Buy-in**: Use the templates in `o11y-center-of-excellence/` to present observability initiatives to your organization
3. **Reference Implementation**: Use the sample code as a starting point for your own instrumentation projects

## Contributing

This repository contains public educational content from Splunk Developer Evangelists. For questions or contributions, please refer to the Splunk community guidelines.
