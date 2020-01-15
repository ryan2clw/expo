//  Copyright © 2019 650 Industries. All rights reserved.

#import <EXUpdates/EXUpdatesAppLoader.h>
#import <EXUpdates/EXUpdatesAppLoaderEmbedded.h>
#import <EXUpdates/EXUpdatesDatabase.h>
#import <EXUpdates/EXUpdatesSelectionPolicy.h>
#import <React/RCTBridge.h>

NS_ASSUME_NONNULL_BEGIN

@class EXUpdatesAppController;

@protocol EXUpdatesAppControllerDelegate <NSObject>

- (void)appController:(EXUpdatesAppController *)appController didStartWithSuccess:(BOOL)success;

@end

@interface EXUpdatesAppController : NSObject <EXUpdatesAppLoaderDelegate>

@property (nonatomic, weak) id<EXUpdatesAppControllerDelegate> delegate;
@property (nonatomic, weak) RCTBridge *bridge;

@property (nonatomic, readonly, strong) EXUpdatesUpdate * _Nullable launchedUpdate;
@property (nonatomic, readonly, strong) NSURL * _Nullable launchAssetUrl;
@property (nonatomic, readonly, strong) NSDictionary * _Nullable assetFilesMap;

@property (nonatomic, readonly) EXUpdatesDatabase *database;
@property (nonatomic, readonly) id<EXUpdatesSelectionPolicy> selectionPolicy;
@property (nonatomic, readonly) NSURL *updatesDirectory;
@property (nonatomic, readonly, assign) BOOL isEnabled;
@property (nonatomic, readonly, assign) BOOL isEmergencyLaunch;

+ (instancetype)sharedInstance;

- (void)start;
- (void)startAndShowLaunchScreen:(UIWindow *)window;
- (BOOL)requestRelaunch;

@end

NS_ASSUME_NONNULL_END
