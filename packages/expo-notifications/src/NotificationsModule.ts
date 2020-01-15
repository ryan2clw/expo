import { NativeModulesProxy, ProxyNativeModule } from '@unimodules/core';

export interface NotificationsModule extends ProxyNativeModule {}

export default (NativeModulesProxy.ExpoNotificationsModule as any) as NotificationsModule;
