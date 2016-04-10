//
//  QBFetchCollectionAssetsOperation.h
//  QBImagePicker
//
//  Created by Sebastian Ludwig on 10.04.16.
//  Copyright © 2016 Katsuma Tanaka. All rights reserved.
//

#import <Photos/Photos.h>
#import "QBImagePickerTypes.h"

@interface QBFetchCollectionAssetsOperation : NSOperation

@property (nonatomic, readonly) PHAssetCollection *assetCollection;
@property (nonatomic, readonly) QBImagePickerMediaType mediaType;
@property (nonatomic, readonly) PHFetchResult *fetchResult;

- (instancetype)initWithCollection:(PHAssetCollection *)collection mediaType:(QBImagePickerMediaType)mediaType completionBlock:(void (^)(QBFetchCollectionAssetsOperation *operation))completionBlock;

@end