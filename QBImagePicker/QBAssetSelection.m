//
//  QBAssetSelection.m
//  QBImagePicker
//
//  Created by Sebastian Ludwig on 29.03.16.
//  Copyright © 2016 Katsuma Tanaka. All rights reserved.
//

#import "QBAssetSelection.h"

@implementation QBAssetSelection
{
    NSMutableOrderedSet<PHAsset *> *selectedAssets;
}

- (instancetype)init
{
    if (self = [super init]) {
        selectedAssets = [NSMutableOrderedSet orderedSet];
        _minimumNumberOfAssets = 1;
    }
    return self;
}

#pragma mark Properties

- (NSOrderedSet *)assets
{
    return [selectedAssets copy];
}

- (NSUInteger)count
{
    return selectedAssets.count;
}

- (BOOL)isAutoDeselectEnabled
{
    return self.maximumNumberOfAssets == 1 && self.minimumNumberOfAssets <= self.maximumNumberOfAssets;
}

- (BOOL)isMinimumSelectionLimitFulfilled
{
    return self.count >= self.minimumNumberOfAssets;
}

- (BOOL)isMaximumSelectionLimitReached
{
    NSUInteger minimumNumberOfSelection = MAX(1, self.minimumNumberOfAssets);
    
    if (minimumNumberOfSelection > self.maximumNumberOfAssets) {
        return NO;
    }
    
    return self.count >= self.maximumNumberOfAssets;
}

#pragma mark Methods

- (void)addAsset:(PHAsset *)asset
{
    [selectedAssets addObject:asset];
}

- (void)removeObjectAtIndex:(NSUInteger)index
{
    [selectedAssets removeObjectAtIndex:index];
}

- (void)removeAsset:(PHAsset *)asset
{
    [selectedAssets removeObject:asset];
}

- (BOOL)containsAsset:(PHAsset *)asset
{
    return [selectedAssets containsObject:asset];
}

@end
