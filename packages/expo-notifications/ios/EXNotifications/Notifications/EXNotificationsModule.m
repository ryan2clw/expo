// Copyright 2018-present 650 Industries. All rights reserved.

#import <EXNotifications/EXNotificationsModule.h>
#import <EXNotifications/EXNotificationsModule+UNSerializer.h>
#import <EXNotifications/EXNotificationCenterDelegate.h>

#import <UMCore/UMEventEmitterService.h>

static NSString * const onWillPresentNotification = @"onWillPresentNotification";
static NSString * const onDidReceiveNotificationResponse = @"onDidReceiveNotificationResponse";

@interface EXNotificationsModule ()

@property (nonatomic, weak) id<EXNotificationCenterDelegate> notificationCenterDelegate;

@property (nonatomic, assign) BOOL isListening;
@property (nonatomic, assign) BOOL isBeingObserved;

@property (nonatomic, weak) id<UMEventEmitterService> eventEmitter;

@end

@implementation EXNotificationsModule

UM_EXPORT_MODULE(ExpoNotificationsModule);

# pragma mark - Exported methods

# pragma mark - UMModuleRegistryConsumer

- (void)setModuleRegistry:(UMModuleRegistry *)moduleRegistry
{
  _eventEmitter = [moduleRegistry getModuleImplementingProtocol:@protocol(UMEventEmitterService)];
  _notificationCenterDelegate = [moduleRegistry getSingletonModuleForName:@"NotificationCenterDelegate"];
}

# pragma mark - UMEventEmitter

- (NSArray<NSString *> *)supportedEvents
{
  return @[onWillPresentNotification, onDidReceiveNotificationResponse];
}

- (void)startObserving
{
  [self setIsBeingObserved:YES];
}

- (void)stopObserving
{
  [self setIsBeingObserved:NO];
}

- (BOOL)shouldListen
{
  return _isBeingObserved;
}

- (void)updateListeningState
{
  if ([self shouldListen] && !_isListening) {
    [_notificationCenterDelegate addDelegate:self];
    _isListening = YES;
  } else if (![self shouldListen] && _isListening) {
    [_notificationCenterDelegate removeDelegate:self];
    _isListening = NO;
  }
}

# pragma mark - EXNotificationsDelegate

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo fetchCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler
{
  // Background task execution would happen here.
  completionHandler(UIBackgroundFetchResultNoData);
}

- (void)userNotificationCenter:(UNUserNotificationCenter *)center didReceiveNotificationResponse:(UNNotificationResponse *)response withCompletionHandler:(void (^)(void))completionHandler
{
  [_eventEmitter sendEventWithName:onDidReceiveNotificationResponse body:[EXNotificationsModule serializedNotificationResponse:response]];
  completionHandler();
}

- (void)userNotificationCenter:(UNUserNotificationCenter *)center willPresentNotification:(UNNotification *)notification withCompletionHandler:(void (^)(UNNotificationPresentationOptions))completionHandler
{
  [_eventEmitter sendEventWithName:onWillPresentNotification body:[EXNotificationsModule serializedNotification:notification]];
  completionHandler(UNNotificationPresentationOptionAlert);
}

# pragma mark - Internal state

- (void)setIsBeingObserved:(BOOL)isBeingObserved
{
  _isBeingObserved = isBeingObserved;
  [self updateListeningState];
}

@end
