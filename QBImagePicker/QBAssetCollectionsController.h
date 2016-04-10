//
//  QBAssetCollectionsController.h
//  QBImagePicker
//
//  Created by Sebastian Ludwig on 10.04.16.
//  Copyright © 2016 Katsuma Tanaka. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "QBAssetCollection.h"
#import "QBImagePickerTypes.h"

@protocol QBAssetCollectionsControllerDelegate <NSObject>

- (void)qb_assetCollectionsDidChange;

@optional
- (void)qb_assetCollectionDidChange:(QBAssetCollection *)collection;

@end

@interface QBAssetCollectionsController : NSObject

@property (nonatomic, weak) id<QBAssetCollectionsControllerDelegate> delegate;

@property (nonatomic) QBImagePickerMediaType mediaType;
@property (nonatomic, copy) NSArray *enabledAssetCollectionSubtypes;
@property (nonatomic, copy, readonly) NSArray<QBAssetCollection *> *assetCollections;
@property (nonatomic, copy, readonly) NSDictionary<NSNumber *, NSArray<QBAssetCollection *> *> *assetCollectionsByType;

- (instancetype)initWithAssetCollectionSubtypes:(NSArray *)assetCollectionSubtypes mediaType:(QBImagePickerMediaType)mediaType;

@end
