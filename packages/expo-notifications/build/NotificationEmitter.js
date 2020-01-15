import { EventEmitter } from '@unimodules/core';
import NotificationsModule from './NotificationsModule';
// Web uses SyntheticEventEmitter
const notificationEmitter = new EventEmitter(NotificationsModule);
const newNotificationEventName = 'onWillPresentNotification';
export function addNotificationListener(listener) {
    return notificationEmitter.addListener(newNotificationEventName, listener);
}
export function removeNotificationSubscription(subscription) {
    notificationEmitter.removeSubscription(subscription);
}
export function removeAllNotificationListeners() {
    notificationEmitter.removeAllListeners(newNotificationEventName);
}
//# sourceMappingURL=NotificationEmitter.js.map