//  Copyright © 2019 650 Industries. All rights reserved.

#import <EXUpdates/EXUpdatesAsset.h>
#import <EXUpdates/EXUpdatesUtils.h>

@implementation EXUpdatesAsset

- (instancetype)initWithUrl:(NSURL * _Nonnull)url type:(NSString * _Nonnull)type
{
  if (self = [super init]) {
    _url = url;
    _type = type;
  }
  return self;
}

@end
