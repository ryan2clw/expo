import { NativeModulesProxy, ProxyNativeModule } from '@unimodules/core';

export interface InstallationIdProvider extends ProxyNativeModule {
  getInstallationIdAsync: () => Promise<string>;
}

export default (NativeModulesProxy.NotificationsInstallationIdProvider as any) as InstallationIdProvider;
