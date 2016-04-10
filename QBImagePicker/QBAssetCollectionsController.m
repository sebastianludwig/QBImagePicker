//
//  QBAssetCollectionsController.m
//  QBImagePicker
//
//  Created by Sebastian Ludwig on 10.04.16.
//  Copyright © 2016 Katsuma Tanaka. All rights reserved.
//

#import "QBAssetCollectionsController.h"
#import "QBFetchCollectionAssetsOperation.h"

@interface QBAssetCollection (Private)

@property (nonatomic) PHFetchResult *assetFetchResult;

@end


@interface QBAssetCollectionsController () <PHPhotoLibraryChangeObserver>

@property (nonatomic, copy) NSArray *fetchAssetCollectionsResults;
@property (nonatomic) NSOperationQueue *operationQueue;
@property (nonatomic) BOOL updateAssetCollectionsInProgress;

@end

@implementation QBAssetCollectionsController
{
    BOOL _updateAssetCollectionsInProgress;
}

- (instancetype)initWithAssetCollectionSubtypes:(NSArray *)assetCollectionSubtypes mediaType:(QBImagePickerMediaType)mediaType
{
    if (self = [super init]) {
        _operationQueue = [[NSOperationQueue alloc] init];
        _operationQueue.qualityOfService = NSOperationQualityOfServiceUserInitiated;
        _enabledAssetCollectionSubtypes = assetCollectionSubtypes;
        _mediaType = mediaType;
        
        // TODO: ensure this does not block
        // Fetch user albums and smart albums
        PHFetchResult *smartAlbums = [PHAssetCollection fetchAssetCollectionsWithType:PHAssetCollectionTypeSmartAlbum subtype:PHAssetCollectionSubtypeAny options:nil];
        PHFetchResult *userAlbums = [PHAssetCollection fetchAssetCollectionsWithType:PHAssetCollectionTypeAlbum subtype:PHAssetCollectionSubtypeAny options:nil];
        _fetchAssetCollectionsResults = @[smartAlbums, userAlbums];
        
        // TODO: maybe use
        // PHFetchResult *topLevelUserCollections = [PHCollectionList fetchTopLevelUserCollectionsWithOptions:nil];
        // PHFetchResult *smartAlbums = [PHAssetCollection fetchAssetCollectionsWithType:PHAssetCollectionTypeSmartAlbum subtype:PHAssetCollectionSubtypeAlbumRegular options:nil];
        // see GMPhotoPicker
        
        [self updateAssetCollections];
        
        // Register observer
        [[PHPhotoLibrary sharedPhotoLibrary] registerChangeObserver:self];
    }
    return self;
}

- (void)dealloc
{
    [[PHPhotoLibrary sharedPhotoLibrary] unregisterChangeObserver:self];
}

- (void)setEnabledAssetCollectionSubtypes:(NSArray *)enabledAssetCollectionSubtypes
{
    _enabledAssetCollectionSubtypes = enabledAssetCollectionSubtypes;
    
    [self updateAssetCollections];
}

- (void)setMediaType:(QBImagePickerMediaType)mediaType
{
    _mediaType = mediaType;
    
    [self updateAssetCollections];
}

#pragma mark private

- (BOOL)updateAssetCollectionsInProgress {
    return _updateAssetCollectionsInProgress;
}

- (void)updateAssetsCollectionsStarted
{
    _updateAssetCollectionsInProgress = YES;
}

- (void)updateAssetsCollectionsFinished
{
    _updateAssetCollectionsInProgress = NO;
}

- (void)updateAssetCollections
{
    NSAssert([NSThread isMainThread], @"must be called on the main thread");
    [self updateAssetsCollectionsStarted];
    [self.operationQueue cancelAllOperations];
    
    NSMutableDictionary *collectionsByType = [NSMutableDictionary dictionaryWithCapacity:self.enabledAssetCollectionSubtypes.count];
    
    for (PHFetchResult *fetchResult in self.fetchAssetCollectionsResults) {
        [fetchResult enumerateObjectsUsingBlock:^(PHAssetCollection *assetCollection, NSUInteger index, BOOL *stop) {
            PHAssetCollectionSubtype subtype = assetCollection.assetCollectionSubtype;
            
            if (![self.enabledAssetCollectionSubtypes containsObject:@(subtype)]) {
                return;
            }
            
            if (!collectionsByType[@(subtype)]) {
                collectionsByType[@(subtype)] = [NSMutableArray array];
            }
            QBAssetCollection *collection = [[QBAssetCollection alloc] initWithAssetCollection:assetCollection];
            [collectionsByType[@(subtype)] addObject:collection];
            
            
            __weak typeof(self)weakSelf = self;
            void (^completionBlock)(QBFetchCollectionAssetsOperation *) = ^void(QBFetchCollectionAssetsOperation *operation) {
                __strong typeof(self) strongSelf = weakSelf;
                
                if (operation.isCancelled || strongSelf.updateAssetCollectionsInProgress) {
                    return;
                }
                
                collection.assetFetchResult = operation.fetchResult;
                
                if ([strongSelf.delegate respondsToSelector:@selector(qb_assetCollectionDidChange:)]) {
                    [strongSelf.delegate qb_assetCollectionDidChange:collection];
                }
            };
            
            // TODO: suspend queue to stop operations when vc in background (assets vc pushed on top)
            [self.operationQueue addOperation:[[QBFetchCollectionAssetsOperation alloc] initWithCollection:assetCollection
                                                                                                 mediaType:self.mediaType
                                                                                           completionBlock:completionBlock]];
        }];
    }
    
    NSMutableArray *assetCollections = [NSMutableArray array];
    for (NSNumber *subtype in self.enabledAssetCollectionSubtypes) {
        NSArray *collections = collectionsByType[subtype];
        
        if (collections) {
            [assetCollections addObjectsFromArray:collections];
        }
    }
    
    _assetCollections = assetCollections;
    _assetCollectionsByType = collectionsByType;
    [self.delegate qb_assetCollectionsDidChange];
    [self updateAssetsCollectionsFinished];
}

#pragma mark - PHPhotoLibraryChangeObserver

- (void)photoLibraryDidChange:(PHChange *)changeInstance
{
    dispatch_async(dispatch_get_main_queue(), ^{
        // Update fetch results
        NSMutableArray *fetchResults = [self.fetchAssetCollectionsResults mutableCopy];
        
        [self.fetchAssetCollectionsResults enumerateObjectsUsingBlock:^(PHFetchResult *fetchResult, NSUInteger index, BOOL *stop) {
            PHFetchResultChangeDetails *changeDetails = [changeInstance changeDetailsForFetchResult:fetchResult];
            
            if (changeDetails) {
                [fetchResults replaceObjectAtIndex:index withObject:changeDetails.fetchResultAfterChanges];
            }
        }];
        
        if (![self.fetchAssetCollectionsResults isEqualToArray:fetchResults]) {
            self.fetchAssetCollectionsResults = fetchResults;
            
            // Reload albums
            [self updateAssetCollections];
        }
    });
}

@end
