import { EventEmitter, Subscription } from '@unimodules/core';
import NotificationsModule from './NotificationsModule';

type Notification = any;
export type NotificationListener = (notification: Notification) => void;

// Web uses SyntheticEventEmitter
const notificationEmitter = new EventEmitter(NotificationsModule);
const newNotificationEventName = 'onWillPresentNotification';

export function addNotificationListener(listener: NotificationListener): Subscription {
  return notificationEmitter.addListener(newNotificationEventName, listener);
}

export function removeNotificationSubscription(subscription: Subscription) {
  notificationEmitter.removeSubscription(subscription);
}

export function removeAllNotificationListeners() {
  notificationEmitter.removeAllListeners(newNotificationEventName);
}
