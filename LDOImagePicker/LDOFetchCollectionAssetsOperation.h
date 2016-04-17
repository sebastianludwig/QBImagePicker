//
//  LDOFetchCollectionAssetsOperation.h
//  LDOImagePicker
//
//  Created by Sebastian Ludwig on 10.04.16.
//  Copyright (c) 2016 Sebastian Ludwig. All rights reserved.
//

#import <Photos/Photos.h>
#import "LDOImagePickerTypes.h"

@interface LDOFetchCollectionAssetsOperation : NSOperation

@property (nonatomic, readonly) PHAssetCollection *assetCollection;
@property (nonatomic, readonly) LDOImagePickerMediaType mediaType;
@property (nonatomic, readonly) PHFetchResult *fetchResult;

- (instancetype)initWithCollection:(PHAssetCollection *)collection mediaType:(LDOImagePickerMediaType)mediaType completionBlock:(void (^)(LDOFetchCollectionAssetsOperation *operation))completionBlock;

@end