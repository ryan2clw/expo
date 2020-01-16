import { ProxyNativeModule } from '@unimodules/core';
export interface InstallationIdProvider extends ProxyNativeModule {
    getInstallationIdAsync: () => Promise<string>;
}
declare const _default: InstallationIdProvider;
export default _default;
