//
//  LDOFetchCollectionAssetsOperation.m
//  LDOImagePicker
//
//  Created by Sebastian Ludwig on 10.04.16.
//  Copyright (c) 2016 Sebastian Ludwig. All rights reserved.
//

#import "LDOFetchCollectionAssetsOperation.h"

@implementation LDOFetchCollectionAssetsOperation
{
    void (^_completionBlock)(LDOFetchCollectionAssetsOperation *operation);
}

- (instancetype)initWithCollection:(PHAssetCollection *)collection mediaType:(LDOImagePickerMediaType)mediaType completionBlock:(void (^)(LDOFetchCollectionAssetsOperation *operation))completionBlock
{
    if (self = [super init]) {
        _assetCollection = collection;
        _mediaType = mediaType;
        _completionBlock = completionBlock;
    }
    return self;
}

- (void)main
{
    if (self.isCancelled) {
        return;
    }
    
    PHFetchOptions *options = [PHFetchOptions new];
    if (self.mediaType == LDOImagePickerMediaTypeImage) {
        options.predicate = [NSPredicate predicateWithFormat:@"mediaType == %ld", PHAssetMediaTypeImage];
    } else if (self.mediaType == LDOImagePickerMediaTypeVideo) {
        options.predicate = [NSPredicate predicateWithFormat:@"mediaType == %ld", PHAssetMediaTypeVideo];
    }
    
    _fetchResult = [PHAsset fetchAssetsInAssetCollection:self.assetCollection options:options];
    
    dispatch_async(dispatch_get_main_queue(), ^(void) {
        _completionBlock(self); // no need for weak reference, since this does not introduce a retain cycle
    });
}

@end
