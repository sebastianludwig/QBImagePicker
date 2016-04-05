//
//  QBAssetSelection.h
//  QBImagePicker
//
//  Created by Sebastian Ludwig on 29.03.16.
//  Copyright © 2016 Katsuma Tanaka. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Photos/Photos.h>

@interface QBAssetSelection : NSObject

@property (nonatomic, assign) BOOL allowsMultipleSelection;
@property (nonatomic, assign) NSUInteger minimumNumberOfAssets;
@property (nonatomic, assign) NSUInteger maximumNumberOfAssets;
@property (nonatomic, readonly, getter=isMinimumSelectionLimitFulfilled) BOOL minimumSelectionLimitFulfilled;
@property (nonatomic, readonly, getter=isMaximumSelectionLimitReached) BOOL maximumSelectionLimitReached;
@property (nonatomic, readonly, getter=isAutoDeselectEnabled) BOOL autoDeselectEnabled;

@property (nonatomic, copy, readonly) NSOrderedSet *assets;
@property (nonatomic, readonly) NSUInteger count;


- (void)addAsset:(PHAsset *)asset;
- (void)removeObjectAtIndex:(NSUInteger)index;
- (void)removeAsset:(PHAsset *)asset;
- (BOOL)containsAsset:(PHAsset *)asset;

@end
