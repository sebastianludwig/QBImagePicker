//
//  QBAssetCollection.h
//  QBImagePicker
//
//  Created by Sebastian Ludwig on 10.04.16.
//  Copyright © 2016 Katsuma Tanaka. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Photos/Photos.h>

@interface QBAssetCollection : NSObject

@property (nonatomic, readonly) PHAssetCollection *collection;
@property (nonatomic, strong, readonly) NSString *localizedTitle;
@property (nonatomic, readonly) NSUInteger count;
@property (nonatomic, readonly) BOOL hasCount;
@property (nonatomic, readonly) PHFetchResult *assetFetchResult;

- (instancetype)initWithAssetCollection:(PHAssetCollection *)collection;

@end
