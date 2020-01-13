//  Copyright © 2019 650 Industries. All rights reserved.

#import <EXUpdates/EXUpdatesConfig.h>
#import <EXUpdates/EXUpdatesAppController.h>
#import <EXUpdates/EXUpdatesAppLoaderEmbedded.h>
#import <EXUpdates/EXUpdatesAppLoaderRemote.h>
#import <EXUpdates/EXUpdatesReaper.h>
#import <EXUpdates/EXUpdatesSelectionPolicyNewest.h>
#import <SystemConfiguration/SystemConfiguration.h>
#import <arpa/inet.h>

NS_ASSUME_NONNULL_BEGIN

static NSString * const kEXUpdatesEventName = @"Expo.nativeUpdatesEvent";
static NSString * const kEXUpdatesUpdateAvailableEventName = @"updateAvailable";
static NSString * const kEXUpdatesNoUpdateAvailableEventName = @"noUpdateAvailable";
static NSString * const kEXUpdatesErrorEventName = @"error";

@interface EXUpdatesAppController ()

@property (nonatomic, readwrite, strong) EXUpdatesAppLauncher *launcher;
@property (nonatomic, readwrite, strong) EXUpdatesDatabase *database;
@property (nonatomic, readwrite, strong) id<EXUpdatesSelectionPolicy> selectionPolicy;
@property (nonatomic, readwrite, strong) EXUpdatesAppLoaderEmbedded *embeddedAppLoader;
@property (nonatomic, readwrite, strong) EXUpdatesAppLoaderRemote *remoteAppLoader;

@property (nonatomic, readwrite, strong) NSURL *updatesDirectory;
@property (nonatomic, readwrite, assign) BOOL isEnabled;

@property (nonatomic, strong) EXUpdatesAppLauncher *candidateLauncher;
@property (nonatomic, strong) NSTimer *timer;
@property (nonatomic, assign) BOOL isReadyToLaunch;
@property (nonatomic, assign) BOOL isTimeoutFinished;
@property (nonatomic, assign) BOOL hasLaunched;

@end

@implementation EXUpdatesAppController

+ (instancetype)sharedInstance
{
  static EXUpdatesAppController *theController;
  static dispatch_once_t once;
  dispatch_once(&once, ^{
    if (!theController) {
      theController = [[EXUpdatesAppController alloc] init];
    }
  });
  return theController;
}

- (instancetype)init
{
  if (self = [super init]) {
    _launcher = [[EXUpdatesAppLauncher alloc] init];
    _database = [[EXUpdatesDatabase alloc] init];
    _selectionPolicy = [[EXUpdatesSelectionPolicyNewest alloc] init];
    _embeddedAppLoader = [[EXUpdatesAppLoaderEmbedded alloc] init];
    _isEnabled = NO;
    _isReadyToLaunch = NO;
    _isTimeoutFinished = NO;
    _hasLaunched = NO;
  }
  return self;
}

- (void)start
{
  _isEnabled = YES;
  [_database openDatabaseWithError:nil];

  NSNumber *launchWaitMs = [EXUpdatesConfig sharedInstance].launchWaitMs;
  if ([launchWaitMs isEqualToNumber:@(0)]) {
    _isTimeoutFinished = YES;
  } else {
    NSDate *fireDate = [NSDate dateWithTimeIntervalSinceNow:[launchWaitMs doubleValue] / 1000];
    _timer = [[NSTimer alloc] initWithFireDate:fireDate interval:0 target:self selector:@selector(_timerDidFire) userInfo:nil repeats:NO];
    [[NSRunLoop mainRunLoop] addTimer:_timer forMode:NSDefaultRunLoopMode];
  }

  [self _maybeLoadEmbeddedUpdate];

  _launcher.delegate = self;
  [_launcher launchUpdateWithSelectionPolicy:_selectionPolicy];
}

- (void)startAndShowLaunchScreen:(UIWindow *)window
{
  UIViewController *rootViewController = [UIViewController new];
  NSArray *views;
  @try {
    NSString *launchScreen = (NSString *)[[NSBundle mainBundle] objectForInfoDictionaryKey:@"UILaunchStoryboardName"] ?: @"LaunchScreen";
    views = [[NSBundle mainBundle] loadNibNamed:launchScreen owner:self options:nil];
  } @catch (NSException *_) {
    NSLog(@"LaunchScreen.xib is missing. Unexpected loading behavior may occur.");
  }
  if (views) {
    rootViewController.view = views.firstObject;
    rootViewController.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
  } else {
    UIView *view = [UIView new];
    view.backgroundColor = [UIColor whiteColor];;
    rootViewController.view = view;
  }
  window.rootViewController = rootViewController;
  [window makeKeyAndVisible];

  [self start];
}

- (BOOL)reloadBridge
{
  if (_bridge) {
    [_bridge reload];
    return true;
  } else {
    NSLog(@"EXUpdatesAppController: Failed to reload because bridge was nil. Did you set the bridge property on the controller singleton?");
    return false;
  }
}

- (NSURL * _Nullable)launchAssetUrl
{
  return _launcher.launchAssetUrl ?: nil;
}

- (NSURL *)updatesDirectory
{
  if (!_updatesDirectory) {
    NSFileManager *fileManager = NSFileManager.defaultManager;
    NSURL *applicationDocumentsDirectory = [[fileManager URLsForDirectory:NSApplicationSupportDirectory inDomains:NSUserDomainMask] lastObject];
    _updatesDirectory = [applicationDocumentsDirectory URLByAppendingPathComponent:@".expo-internal"];
    NSString *updatesDirectoryPath = [_updatesDirectory path];

    BOOL isDir;
    BOOL exists = [fileManager fileExistsAtPath:updatesDirectoryPath isDirectory:&isDir];
    if (!exists || !isDir) {
      if (!isDir) {
        NSError *err;
        BOOL wasRemoved = [fileManager removeItemAtPath:updatesDirectoryPath error:&err];
        if (!wasRemoved) {
          // TODO: handle error
        }
      }
      NSError *err;
      BOOL wasCreated = [fileManager createDirectoryAtPath:updatesDirectoryPath withIntermediateDirectories:YES attributes:nil error:&err];
      if (!wasCreated) {
        // TODO: handle error
      }
    }
  }
  return _updatesDirectory;
}

# pragma mark - internal

- (void)_maybeFinish
{
  NSAssert([NSThread isMainThread], @"EXUpdatesAppController:_maybeFinish should only be called on the main thread");
  if (!_isTimeoutFinished || !_isReadyToLaunch) {
    // too early, bail out
    return;
  }
  if (_hasLaunched) {
    // we've already fired once, don't do it again
    return;
  }

  _hasLaunched = YES;
  if (self->_delegate) {
    [self->_delegate appController:self didStartWithSuccess:YES];
  }
}

- (void)_timerDidFire
{
  _isTimeoutFinished = YES;
  [self _maybeFinish];
}

- (void)_maybeLoadEmbeddedUpdate
{
  if ([_selectionPolicy shouldLoadNewUpdate:_embeddedAppLoader.embeddedManifest withLaunchedUpdate:[_launcher launchableUpdateWithSelectionPolicy:_selectionPolicy]]) {
    [_embeddedAppLoader loadUpdateFromEmbeddedManifest];
  }
}

- (void)_sendEventToBridgeWithType:(NSString *)eventType body:(NSDictionary *)body
{
  if (_bridge) {
    NSMutableDictionary *mutableBody = [body mutableCopy];
    mutableBody[@"type"] = eventType;
    [_bridge enqueueJSCall:@"RCTDeviceEventEmitter.emit" args:@[kEXUpdatesEventName, mutableBody]];
  } else {
    NSLog(@"EXUpdatesAppController: Could not emit %@ event. Did you set the bridge property on the controller singleton?", eventType);
  }
}

+ (BOOL)_shouldCheckForUpdate
{
  EXUpdatesConfig *config = [EXUpdatesConfig sharedInstance];
  switch (config.checkOnLaunch) {
    case EXUpdatesCheckAutomaticallyConfigNever:
      return NO;
    case EXUpdatesCheckAutomaticallyConfigWifiOnly: {
      struct sockaddr_in zeroAddress;
      bzero(&zeroAddress, sizeof(zeroAddress));
      zeroAddress.sin_len = sizeof(zeroAddress);
      zeroAddress.sin_family = AF_INET;

      SCNetworkReachabilityRef reachability = SCNetworkReachabilityCreateWithAddress(kCFAllocatorDefault, (const struct sockaddr *) &zeroAddress);
      SCNetworkReachabilityFlags flags;
      SCNetworkReachabilityGetFlags(reachability, &flags);

      return (flags & kSCNetworkReachabilityFlagsIsWWAN) == 0;
    }
    case EXUpdatesCheckAutomaticallyConfigAlways:
    default:
      return YES;
  }
}

# pragma mark - EXUpdatesAppLoaderDelegate

- (BOOL)appLoader:(EXUpdatesAppLoader *)appLoader shouldStartLoadingUpdate:(EXUpdatesUpdate *)update
{
  BOOL shouldStartLoadingUpdate = [_selectionPolicy shouldLoadNewUpdate:update withLaunchedUpdate:_launcher.launchedUpdate];
  NSLog(@"manifest downloaded, shouldStartLoadingUpdate is %@", shouldStartLoadingUpdate ? @"YES" : @"NO");
  return shouldStartLoadingUpdate;
}

- (void)appLoader:(EXUpdatesAppLoader *)appLoader didFinishLoadingUpdate:(EXUpdatesUpdate * _Nullable)update
{
  dispatch_async(dispatch_get_main_queue(), ^{
    if (self->_timer) {
      [self->_timer invalidate];
    }
    self->_isTimeoutFinished = YES;

    if (update) {
      if (!self->_hasLaunched) {
        self->_candidateLauncher = [[EXUpdatesAppLauncher alloc] init];
        self->_candidateLauncher.delegate = self;
        [self->_candidateLauncher launchUpdateWithSelectionPolicy:self->_selectionPolicy];
      } else {
        [self _sendEventToBridgeWithType:kEXUpdatesUpdateAvailableEventName
                                    body:@{@"manifest": update.rawManifest}];
        [EXUpdatesReaper reapUnusedUpdatesWithSelectionPolicy:self->_selectionPolicy
                                               launchedUpdate:self->_launcher.launchedUpdate];
      }
    } else {
      NSLog(@"No update available");
      // there's no update, so signal we're ready to launch
      [self _maybeFinish];
      [self _sendEventToBridgeWithType:kEXUpdatesNoUpdateAvailableEventName body:@{}];
      [EXUpdatesReaper reapUnusedUpdatesWithSelectionPolicy:self->_selectionPolicy
                                             launchedUpdate:self->_launcher.launchedUpdate];
    }
  });
}

- (void)appLoader:(EXUpdatesAppLoader *)appLoader didFailWithError:(NSError *)error
{
  dispatch_async(dispatch_get_main_queue(), ^{
    if (self->_timer) {
      [self->_timer invalidate];
    }
    self->_isTimeoutFinished = YES;
    NSLog(@"update failed to load: %@", error.localizedDescription);
    [self _maybeFinish];
    [self _sendEventToBridgeWithType:kEXUpdatesErrorEventName body:@{@"message": error.localizedDescription}];
  });
}

# pragma mark - EXUpdatesAppLauncherDelegate

- (void)appLauncher:(EXUpdatesAppLauncher *)appLauncher didFinishWithSuccess:(BOOL)success
{
  dispatch_async(dispatch_get_main_queue(), ^{
    if (success) {
      self->_isReadyToLaunch = YES;
      if (!self->_hasLaunched) {
        self->_launcher = appLauncher;
        [self _maybeFinish];
      }

      if (!self->_remoteAppLoader && [[self class] _shouldCheckForUpdate]) {
        self->_remoteAppLoader = [[EXUpdatesAppLoaderRemote alloc] init];
        self->_remoteAppLoader.delegate = self;
        [self->_remoteAppLoader loadUpdateFromUrl:[EXUpdatesConfig sharedInstance].remoteUrl];
      } else {
        [EXUpdatesReaper reapUnusedUpdatesWithSelectionPolicy:self->_selectionPolicy
                                               launchedUpdate:self->_launcher.launchedUpdate];
      }
    } else {
      // TODO: emergency launch
    }
  });
}

@end

NS_ASSUME_NONNULL_END
