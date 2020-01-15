// Copyright 2018-present 650 Industries. All rights reserved.

#import <UMCore/UMUtilities.h>
#import <EXFirebaseApp/EXFirebaseApp.h>
#import <EXFirebaseApp/EXFirebaseApp+FIROptions.h>
#import <UMConstantsInterface/UMConstantsInterface.h>

@interface EXFirebaseApp ()

@property (nonatomic, weak) UMModuleRegistry *moduleRegistry;
@property (nonatomic, weak) id<UMConstantsInterface> constants;

@end

@implementation EXFirebaseApp

UM_EXPORT_MODULE(ExpoFirebaseApp);

- (void)setModuleRegistry:(UMModuleRegistry *)moduleRegistry
{
  _moduleRegistry = moduleRegistry;
  _constants = [moduleRegistry getModuleImplementingProtocol:@protocol(UMConstantsInterface)];
  FIROptions* firOptions = [self.class firOptionsWithGoogleServicesFile:_constants.constants[@"googleServicesFile"]];
  [self.class updateFirAppWithOptions:firOptions name:nil completion:^(BOOL success) {
    // nop
    /*if (!success) {
      reject(@"ERR_FIREBASE_APP", @"Failed to initialize Firebase App", nil);
    }*/
  }];
}

- (void)reject:(UMPromiseRejectBlock)reject withException:(NSException *)exception {
  NSError *error = [NSError errorWithDomain:@"ERR_FIREBASE_APP" code:4815162342 userInfo:@{
        @"message": exception.reason,
        @"code": exception.name,
    }];
  reject(exception.name, exception.reason, error);
}

- (nullable FIRApp *)getAppOrReject:(NSString*)name reject:(UMPromiseRejectBlock)reject
{
  FIRApp *app = name ? [FIRApp appNamed:name] : [FIRApp defaultApp];
  if (app != nil) return app;
  reject(@"ERR_FIREBASE_APP", @"The 'default' Firebase app is not initialized. Ensure your app has a valid GoogleService-Info.plist bundled and your project has react-native-unimodules installed. Optionally in the Expo client you can initialized the default app with initializeAppDangerously().", nil);
  return nil;
}

UM_EXPORT_METHOD_AS(initializeAppAsync,
                    initializeAppAsync:(nullable NSDictionary *)config
                    name:(nullable NSString*)name
                    resolve:(UMPromiseResolveBlock)resolve
                    reject:(UMPromiseRejectBlock)reject)
{
  [UMUtilities performSynchronouslyOnMainThread:^{
    FIROptions* firOptions = config
      ? [self.class firOptionsWithJSON:config]
      : [self.class firOptionsWithGoogleServicesFile:self->_constants.constants[@"googleServicesFile"]];
    [self.class updateFirAppWithOptions:firOptions name:name completion:^(BOOL success) {
      if (success) {
        resolve([NSNull null]);
      } else {
        reject(@"ERR_FIREBASE_APP", @"Failed to initialize Firebase App", nil);
      }
    }];
  }];
}

UM_EXPORT_METHOD_AS(getAppAsync,
                    getAppAsync:(NSString*)name
                    resolve:(UMPromiseResolveBlock)resolve
                    reject:(UMPromiseRejectBlock)reject)
{
  FIRApp* app = [self getAppOrReject:name reject:reject];
  if (!app) return;
  resolve(app.name);
}

UM_EXPORT_METHOD_AS(getAppsAsync,
                    resolve:(UMPromiseResolveBlock)resolve
                    reject:(UMPromiseRejectBlock)reject)
{
  @try {
    resolve([[FIRApp allApps]allKeys]);
  } @catch (NSException *exception) {
    [self reject:reject withException:exception];
  }
}

UM_EXPORT_METHOD_AS(deleteAppAsync,
                    deleteAppAsync:(NSString*)name
                    resolve:(UMPromiseResolveBlock)resolve
                    reject:(UMPromiseRejectBlock)reject)
{
  FIRApp* app = [self getAppOrReject:name reject:reject];
  if (!app) return;
  [app deleteApp:^(BOOL success) {
    if (success) {
      resolve([NSNull null]);
    } else {
      reject(@"ERR_FIREBASE_APP", @"Failed to delete Firebase App", nil);
    }
  }];
}

UM_EXPORT_METHOD_AS(getAppOptionsAsync,
                    getAppOptionsAsync:(NSString*)name
                    resolve:(UMPromiseResolveBlock)resolve
                    reject:(UMPromiseRejectBlock)reject)
{
  FIRApp* app = [self getAppOrReject:name reject:reject];
  if (!app) return;
  @try {
    resolve([self.class firOptionsToJSON:app.options]);
  } @catch (NSException *exception) {
    [self reject:reject withException:exception];
  }
}

@end
