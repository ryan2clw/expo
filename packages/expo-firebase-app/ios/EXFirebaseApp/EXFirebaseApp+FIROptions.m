//  Copyright © 2020 650 Industries. All rights reserved.

#import <EXFirebaseApp/EXFirebaseApp+FIROptions.h>

@implementation EXFirebaseApp (FIROptions)

+ (nullable FIROptions*) firOptionsWithGoogleServicesFile:(nullable NSDictionary*)plist
{
  if (!plist) return nil;
  
  FIROptions *firOptions = [[FIROptions alloc] initWithGoogleAppID:plist[@"GOOGLE_APP_ID"] GCMSenderID:plist[@"GCM_SENDER_ID"]];
         
  firOptions.APIKey = plist[@"API_KEY"];
  firOptions.projectID = plist[@"PROJECT_ID"];
  firOptions.clientID = plist[@"CLIENT_ID"];
  firOptions.databaseURL = plist[@"DATABASE_URL"];
  firOptions.storageBucket = plist[@"STORAGE_BUCKET"];
  //firOptions.trackingID = plist[@"trackingId"];
  //firOptions.androidClientID = plist[@"ANDROID_CLIENT_ID"];
  //firOptions.deepLinkURLScheme = plist[@"DEEP_LINK_URL_SCHEMA"];
  
  return firOptions;
}

+ (BOOL) compareString:(NSString*) str1 str2:(NSString*) str2 {
  if (str1 == str2) return YES;
  if (!str1 || !str2) return NO;
  return [str2 isEqualToString:str2];
}

+ (BOOL) firOptionsIsEqualTo:(nonnull FIROptions*)options1 compareTo:(nonnull FIROptions*)options2
{
  return [self.class compareString:options1.androidClientID str2:options2.androidClientID]
    && [self.class compareString:options1.APIKey str2:options2.APIKey]
    && [self.class compareString:options1.appGroupID str2:options2.appGroupID]
    && [self.class compareString:options1.bundleID str2:options2.bundleID]
    && [self.class compareString:options1.clientID str2:options2.clientID]
    && [self.class compareString:options1.databaseURL str2:options2.databaseURL]
    && [self.class compareString:options1.deepLinkURLScheme str2:options2.deepLinkURLScheme]
    && [self.class compareString:options1.GCMSenderID str2:options2.GCMSenderID]
    && [self.class compareString:options1.googleAppID str2:options2.googleAppID]
    && [self.class compareString:options1.projectID str2:options2.projectID]
    && [self.class compareString:options1.storageBucket str2:options2.storageBucket]
    && [self.class compareString:options1.trackingID str2:options2.trackingID];
}

+ (nonnull NSDictionary *)firOptionsToJSON:(nonnull FIROptions *)options
{
  NSMutableDictionary* json = [NSMutableDictionary dictionary];
  
  if (options.androidClientID) [json setValue:options.androidClientID forKey:@"androidClientID"];
  if (options.APIKey) [json setValue:options.APIKey forKey:@"apiKey"];
  if (options.googleAppID) [json setValue:options.googleAppID forKey:@"appId"];
  if (options.clientID) [json setValue:options.clientID forKey:@"clientId"];
  if (options.databaseURL) [json setValue:options.databaseURL forKey:@"databaseURL"];
  if (options.deepLinkURLScheme) [json setValue:options.deepLinkURLScheme forKey:@"deepLinkUrlScheme"];
  if (options.GCMSenderID) [json setValue:options.GCMSenderID forKey:@"messagingSenderId"];
  if (options.projectID) [json setValue:options.projectID forKey:@"projectId"];
  if (options.storageBucket) [json setValue:options.storageBucket forKey:@"storageBucket"];
  if (options.trackingID) [json setValue:options.trackingID forKey:@"trackingId"];

  return json;
}

+ (nullable FIROptions *)firOptionsWithJSON:(nullable NSDictionary *)json
{
    if (!json) return nil;
    
    FIROptions *firOptions = [[FIROptions alloc] initWithGoogleAppID:json[@"appId"] GCMSenderID:json[@"messagingSenderId"]];
         
    firOptions.APIKey = json[@"apiKey"];
    firOptions.projectID = json[@"projectId"];
    firOptions.clientID = json[@"clientId"];
    firOptions.trackingID = json[@"trackingId"];
    firOptions.databaseURL = json[@"databaseURL"];
    firOptions.storageBucket = json[@"storageBucket"];
    firOptions.androidClientID = json[@"androidClientId"];
    firOptions.deepLinkURLScheme = json[@"deepLinkURLScheme"];
    
    return firOptions;
}

+ (void) updateFirAppWithOptions:(nullable FIROptions*)options name:(nullable NSString*)name completion:(nonnull FIRAppVoidBoolCallback)completion
{
  // Default app
  if (!name) {
    FIRApp* app = [FIRApp defaultApp];
    if (!options) {
      if (app) {
        [app deleteApp:completion];
        return;
      }
    } else {
      if (app) {
        if (![self.class firOptionsIsEqualTo:app.options compareTo:options]) {
          [app deleteApp:^(BOOL success) {
            [FIRApp configureWithOptions:options];
            completion(YES);
          }];
          return;
        }
      } else {
        [FIRApp configureWithOptions:options];
      }
    }

  // Handle custom apps
  } else {
    // TODO
    completion(NO);
  }
  completion(YES);
}

@end
