//
//  LDOAlbumsController.h
//  LDOImagePicker
//
//  Created by Sebastian Ludwig on 10.04.16.
//  Copyright (c) 2016 Sebastian Ludwig. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "LDOAssetCollection.h"
#import "LDOImagePickerTypes.h"

@protocol LDOAlbumsControllerDelegate <NSObject>

- (void)assetCollectionsDidChange;

@optional
- (void)assetCollectionDidChange:(LDOAssetCollection *)collection;

@end

@interface LDOAlbumsController : NSObject

@property (nonatomic, weak) id<LDOAlbumsControllerDelegate> delegate;

@property (nonatomic) LDOImagePickerMediaType mediaType;
@property (nonatomic, copy) NSArray *enabledAssetCollectionSubtypes;
@property (nonatomic, copy, readonly) NSArray<LDOAssetCollection *> *assetCollections;
@property (nonatomic, copy, readonly) NSDictionary<NSNumber *, NSArray<LDOAssetCollection *> *> *assetCollectionsByType;

- (instancetype)initWithAssetCollectionSubtypes:(NSArray *)assetCollectionSubtypes mediaType:(LDOImagePickerMediaType)mediaType;

@end
