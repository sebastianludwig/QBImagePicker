//
//  QBFetchCollectionAssetsOperation.m
//  QBImagePicker
//
//  Created by Sebastian Ludwig on 10.04.16.
//  Copyright © 2016 Katsuma Tanaka. All rights reserved.
//

#import "QBFetchCollectionAssetsOperation.h"

@implementation QBFetchCollectionAssetsOperation
{
    void (^_completionBlock)(QBFetchCollectionAssetsOperation *operation);
}

- (instancetype)initWithCollection:(PHAssetCollection *)collection mediaType:(QBImagePickerMediaType)mediaType completionBlock:(void (^)(QBFetchCollectionAssetsOperation *operation))completionBlock
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
    if (self.mediaType == QBImagePickerMediaTypeImage) {
        options.predicate = [NSPredicate predicateWithFormat:@"mediaType == %ld", PHAssetMediaTypeImage];
    } else if (self.mediaType == QBImagePickerMediaTypeVideo) {
        options.predicate = [NSPredicate predicateWithFormat:@"mediaType == %ld", PHAssetMediaTypeVideo];
    }
    
    _fetchResult = [PHAsset fetchAssetsInAssetCollection:self.assetCollection options:options];
    
    dispatch_async(dispatch_get_main_queue(), ^(void) {
        _completionBlock(self); // no need for weak reference, since this does not introduce a retain cycle
    });
}

@end
