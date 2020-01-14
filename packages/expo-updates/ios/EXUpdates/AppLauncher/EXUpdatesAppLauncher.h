//  Copyright © 2019 650 Industries. All rights reserved.

#import <EXUpdates/EXUpdatesUpdate.h>
#import <EXUpdates/EXUpdatesSelectionPolicy.h>

NS_ASSUME_NONNULL_BEGIN

typedef void (^EXUpdatesAppLauncherCompletionBlock)(BOOL success);

@interface EXUpdatesAppLauncher : NSObject

@property (nonatomic, strong, readonly) EXUpdatesUpdate * _Nullable launchedUpdate;
@property (nonatomic, strong, readonly) NSURL * _Nullable launchAssetUrl;
@property (nonatomic, strong, readonly) NSDictionary * _Nullable assetFilesMap;

- (void)launchUpdateWithSelectionPolicy:(id<EXUpdatesSelectionPolicy>)selectionPolicy
                             completion:(EXUpdatesAppLauncherCompletionBlock)completion;

+ (EXUpdatesUpdate * _Nullable)launchableUpdateWithSelectionPolicy:(id<EXUpdatesSelectionPolicy>)selectionPolicy;

@end

NS_ASSUME_NONNULL_END
