//
//  QBAssetCollection.m
//  QBImagePicker
//
//  Created by Sebastian Ludwig on 10.04.16.
//  Copyright © 2016 Katsuma Tanaka. All rights reserved.
//

#import "QBAssetCollection.h"

@implementation QBAssetCollection

- (instancetype)initWithAssetCollection:(PHAssetCollection *)collection
{
    if (self = [super init]) {
        _collection = collection;
    }
    return self;
}

- (NSString *)localizedTitle
{
    return self.collection.localizedTitle;
}

- (BOOL)hasCount
{
    return self.assetFetchResult || self.collection.estimatedAssetCount != NSNotFound;    // not sure if NSNotFound is appropriate here - it's the same value, but not documented
}

- (NSUInteger)count
{
    if (!self.hasCount) {
        return 0;
    }
    return self.assetFetchResult ? self.assetFetchResult.count : self.collection.estimatedAssetCount;
}

- (void)setAssetFetchResult:(PHFetchResult *)assetFetchResult
{
    _assetFetchResult = assetFetchResult;
}

@end
