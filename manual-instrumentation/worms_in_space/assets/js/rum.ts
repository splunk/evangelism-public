import { SplunkRum } from '@splunk/otel-web';

export const initializeRUM = () => {
  // Use OTLP exporter to send traces to OpenTelemetry Collector
  const rum = SplunkRum.init({
    beaconEndpoint: 'http://localhost:4318/v1/traces',
    applicationName: 'worms-in-space-frontend',
    deploymentEnvironment: 'development',
    exporter: {
      otlp: true
    },
    // Disable direct authentication since Collector handles it
    allowInsecureBeacon: true
  });

  return rum;
};