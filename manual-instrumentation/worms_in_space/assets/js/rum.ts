import { SplunkRum } from '@splunk/otel-web';

export const initializeRUM = () => {
  const rum = SplunkRum.init({
    realm: 'us1',
    rumAccessToken: 'YOUR_RUM_ACCESS_TOKEN_HERE',
    applicationName: 'worms-in-space-frontend',
    deploymentEnvironment: 'development'
  });

  return rum;
};