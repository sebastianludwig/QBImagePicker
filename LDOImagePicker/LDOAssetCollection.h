//
//  LDOAssetCollection.h
//  LDOImagePicker
//
//  Created by Sebastian Ludwig on 10.04.16.
//  Copyright (c) 2016 Sebastian Ludwig. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Photos/Photos.h>

@interface LDOAssetCollection : NSObject

@property (nonatomic, readonly) PHAssetCollection *collection;
@property (nonatomic, strong, readonly) NSString *localizedTitle;
@property (nonatomic, readonly) NSUInteger count;
@property (nonatomic, readonly) BOOL hasCount;
@property (nonatomic, readonly) PHFetchResult *assetFetchResult;

- (instancetype)initWithAssetCollection:(PHAssetCollection *)collection;

@end
