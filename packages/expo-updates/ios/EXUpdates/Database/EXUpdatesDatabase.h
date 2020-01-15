//  Copyright © 2019 650 Industries. All rights reserved.

#import <EXUpdates/EXUpdatesAsset.h>
#import <EXUpdates/EXUpdatesUpdate.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, EXUpdatesDatabaseHashType) {
  EXUpdatesDatabaseHashTypeSha1 = 0
};

@interface EXUpdatesDatabase : NSObject

@property (nonatomic, readonly) NSLock *lock;

- (BOOL)openDatabaseWithError:(NSError ** _Nullable)error;
- (void)closeDatabase;

- (void)addUpdate:(EXUpdatesUpdate *)update error:(NSError ** _Nullable)error;
- (void)addNewAssets:(NSArray<EXUpdatesAsset *>*)assets toUpdateWithId:(NSUUID *)updateId error:(NSError ** _Nullable)error;
- (BOOL)addExistingAsset:(EXUpdatesAsset *)asset toUpdateWithId:(NSUUID *)updateId error:(NSError ** _Nullable)error;
- (void)updateAsset:(EXUpdatesAsset *)asset error:(NSError ** _Nullable)error;
- (void)markUpdateReadyWithId:(NSUUID *)updateId error:(NSError ** _Nullable)error;

- (void)markUpdateForDeletionWithId:(NSUUID *)updateId error:(NSError ** _Nullable)error;
- (NSArray<NSDictionary *>* _Nullable)markUnusedAssetsForDeletionWithError:(NSError ** _Nullable)error;
- (void)deleteAssetsWithIds:(NSArray<NSNumber *>*)assetIds error:(NSError ** _Nullable)error;
- (void)deleteUnusedUpdatesWithError:(NSError ** _Nullable)error;

- (NSArray<EXUpdatesUpdate *>* _Nullable)allUpdatesWithError:(NSError ** _Nullable)error;
- (NSArray<EXUpdatesUpdate *>* _Nullable)launchableUpdatesWithError:(NSError ** _Nullable)error;
- (EXUpdatesUpdate * _Nullable)updateWithId:(NSUUID *)updateId error:(NSError ** _Nullable)error;
- (EXUpdatesAsset * _Nullable)launchAssetWithUpdateId:(NSUUID *)updateId error:(NSError ** _Nullable)error;
- (NSArray<EXUpdatesAsset *>* _Nullable)assetsWithUpdateId:(NSUUID *)updateId error:(NSError ** _Nullable)error;

@end

NS_ASSUME_NONNULL_END
