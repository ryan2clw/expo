//  Copyright © 2020 650 Industries. All rights reserved.

#import <Foundation/Foundation.h>
#import <EXFirebaseApp/EXFirebaseApp.h>
#import <Firebase/Firebase.h>

@interface EXFirebaseApp (FIROptions)

+ (nullable FIROptions*) firOptionsWithGoogleServicesFile:(nullable NSDictionary*)plist;
+ (nonnull NSDictionary *)firOptionsToJSON:(nonnull FIROptions *)options;
+ (nullable FIROptions *)firOptionsWithJSON:(nullable NSDictionary *)json;

+ (BOOL) firOptionsIsEqualTo:(nonnull FIROptions*)firebaseOptions compareTo:(nonnull FIROptions*)compareTo;

+ (void) updateFirAppWithOptions:(nullable FIROptions*)options name:(nullable NSString*)name completion:(nonnull FIRAppVoidBoolCallback)completion;

@end
