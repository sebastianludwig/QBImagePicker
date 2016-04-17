//
//  LDOAssetsCollectionController.m
//  LDOImagePicker
//
//  Created by Sebastian Ludwig on 17.04.16.
//  Copyright (c) 2016 Sebastian Ludwig. All rights reserved.
//

#import "LDOAssetsCollectionController.h"
#import "LDOImagePickerBundle.h"
#import "LDOAssetCell.h"

static CGSize CGSizeScale(CGSize size, CGFloat scale) {
    return CGSizeMake(size.width * scale, size.height * scale);
}

// TODO: inline
@implementation NSIndexSet (Convenience)

- (NSArray *)qb_indexPathsFromIndexesWithSection:(NSUInteger)section
{
    NSMutableArray *indexPaths = [NSMutableArray arrayWithCapacity:self.count];
    [self enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
        [indexPaths addObject:[NSIndexPath indexPathForItem:idx inSection:section]];
    }];
    return indexPaths;
}

@end

// TODO: inline
@implementation UICollectionView (Convenience)

- (NSArray *)qb_indexPathsForElementsInRect:(CGRect)rect
{
    NSArray *allLayoutAttributes = [self.collectionViewLayout layoutAttributesForElementsInRect:rect];
    if (allLayoutAttributes.count == 0) { return nil; }
    
    NSMutableArray *indexPaths = [NSMutableArray arrayWithCapacity:allLayoutAttributes.count];
    for (UICollectionViewLayoutAttributes *layoutAttributes in allLayoutAttributes) {
        NSIndexPath *indexPath = layoutAttributes.indexPath;
        [indexPaths addObject:indexPath];
    }
    return indexPaths;
}

@end




@interface LDOAssetsCollectionController () <PHPhotoLibraryChangeObserver>

@property (nonatomic) PHCachingImageManager *imageManager;
@property (nonatomic) CGRect previousPreheatRect;

@property (nonatomic) NSIndexPath *lastSelectedItemIndexPath;

@end


@implementation LDOAssetsCollectionController

- (instancetype)init
{
    if (self = [super init]) {
        _numberOfColumns = 4;
        UICollectionViewFlowLayout *layout = [UICollectionViewFlowLayout new];
        layout.minimumInteritemSpacing = 2;
        layout.minimumLineSpacing = 2;
        layout.footerReferenceSize = CGSizeMake(66, 66);
        _collectionViewLayout = layout;
        
        _imageManager = [PHCachingImageManager new];
        [self resetCachedAssets];
        
        [[PHPhotoLibrary sharedPhotoLibrary] registerChangeObserver:self];
    }
    return self;
}

- (void)dealloc
{
    [[PHPhotoLibrary sharedPhotoLibrary] unregisterChangeObserver:self];
}

- (void)awakeFromNib
{
    [super awakeFromNib];
    
    [self setupCollectionView];
}

#pragma mark - Accessors

- (void)setFetchResult:(PHFetchResult *)fetchResult
{
    _fetchResult = fetchResult;
    
    if (self.assetSelection.isAutoDeselectEnabled && self.assetSelection.count > 0) {
        // Get index of previous selected asset
        PHAsset *asset = [self.assetSelection.assets firstObject];
        NSInteger assetIndex = [self.fetchResult indexOfObject:asset];
        self.lastSelectedItemIndexPath = [NSIndexPath indexPathForItem:assetIndex inSection:0];
    }
    
    [self.collectionView reloadData];
    
    // TDOO: check if this needs to resetCachedAssets
}

- (void)setNumberOfColumns:(NSUInteger)numberOfColumns
{
    _numberOfColumns = numberOfColumns;
    
    [self.collectionViewLayout invalidateLayout];
}

- (void)setAssetSelection:(LDOAssetSelection *)assetSelection
{
    _assetSelection = assetSelection;
    self.collectionView.allowsMultipleSelection = _assetSelection.allowsMultipleSelection;
}

- (void)setCollectionView:(UICollectionView *)collectionView
{
    _collectionView = collectionView;
    [self setupCollectionView];
}

- (void)setupCollectionView
{
    UINib *nib = [UINib nibWithNibName:@"LDOAssetCell" bundle:[LDOImagePickerBundle ldoImagePickerBundle]];
    [self.collectionView registerNib:nib forCellWithReuseIdentifier:@"LDOAssetCell"];
    [self.collectionView registerClass:[UICollectionReusableView class] forSupplementaryViewOfKind:UICollectionElementKindSectionFooter withReuseIdentifier:@"LDOFooterView"];
    self.collectionView.allowsMultipleSelection = self.assetSelection.allowsMultipleSelection;
}

#pragma mark - Asset Caching

- (void)resetCachedAssets
{
    [self.imageManager stopCachingImagesForAllAssets];
    self.previousPreheatRect = CGRectZero;
}

- (void)updateCachedAssets
{
    BOOL isViewVisible = self.collectionView && self.collectionView.superview;
    if (!isViewVisible) { return; }
    
    // The preheat window is twice the height of the visible rect
    CGRect preheatRect = self.collectionView.bounds;
    preheatRect = CGRectInset(preheatRect, 0.0, -0.5 * CGRectGetHeight(preheatRect));
    
    // If scrolled by a "reasonable" amount...
    CGFloat delta = ABS(CGRectGetMidY(preheatRect) - CGRectGetMidY(self.previousPreheatRect));
    
    if (delta > CGRectGetHeight(self.collectionView.bounds) / 3.0) {
        // Compute the assets to start caching and to stop caching
        NSMutableArray *addedIndexPaths = [NSMutableArray array];
        NSMutableArray *removedIndexPaths = [NSMutableArray array];
        
        [self computeDifferenceBetweenRect:self.previousPreheatRect andRect:preheatRect addedHandler:^(CGRect addedRect) {
            NSArray *indexPaths = [self.collectionView qb_indexPathsForElementsInRect:addedRect];
            [addedIndexPaths addObjectsFromArray:indexPaths];
        } removedHandler:^(CGRect removedRect) {
            NSArray *indexPaths = [self.collectionView qb_indexPathsForElementsInRect:removedRect];
            [removedIndexPaths addObjectsFromArray:indexPaths];
        }];
        
        NSArray *assetsToStartCaching = [self assetsAtIndexPaths:addedIndexPaths];
        NSArray *assetsToStopCaching = [self assetsAtIndexPaths:removedIndexPaths];
        
        CGSize itemSize = [(UICollectionViewFlowLayout *)self.collectionViewLayout itemSize];
        CGSize targetSize = CGSizeScale(itemSize, [[UIScreen mainScreen] scale]);
        
        [self.imageManager startCachingImagesForAssets:assetsToStartCaching
                                            targetSize:targetSize
                                           contentMode:PHImageContentModeAspectFill
                                               options:nil];
        [self.imageManager stopCachingImagesForAssets:assetsToStopCaching
                                           targetSize:targetSize
                                          contentMode:PHImageContentModeAspectFill
                                              options:nil];
        
        self.previousPreheatRect = preheatRect;
    }
}

- (void)computeDifferenceBetweenRect:(CGRect)oldRect andRect:(CGRect)newRect addedHandler:(void (^)(CGRect addedRect))addedHandler removedHandler:(void (^)(CGRect removedRect))removedHandler
{
    if (CGRectIntersectsRect(newRect, oldRect)) {
        CGFloat oldMaxY = CGRectGetMaxY(oldRect);
        CGFloat oldMinY = CGRectGetMinY(oldRect);
        CGFloat newMaxY = CGRectGetMaxY(newRect);
        CGFloat newMinY = CGRectGetMinY(newRect);
        
        if (newMaxY > oldMaxY) {
            CGRect rectToAdd = CGRectMake(newRect.origin.x, oldMaxY, newRect.size.width, (newMaxY - oldMaxY));
            addedHandler(rectToAdd);
        }
        if (oldMinY > newMinY) {
            CGRect rectToAdd = CGRectMake(newRect.origin.x, newMinY, newRect.size.width, (oldMinY - newMinY));
            addedHandler(rectToAdd);
        }
        if (newMaxY < oldMaxY) {
            CGRect rectToRemove = CGRectMake(newRect.origin.x, newMaxY, newRect.size.width, (oldMaxY - newMaxY));
            removedHandler(rectToRemove);
        }
        if (oldMinY < newMinY) {
            CGRect rectToRemove = CGRectMake(newRect.origin.x, oldMinY, newRect.size.width, (newMinY - oldMinY));
            removedHandler(rectToRemove);
        }
    } else {
        addedHandler(newRect);
        removedHandler(oldRect);
    }
}

- (NSArray *)assetsAtIndexPaths:(NSArray *)indexPaths
{
    if (indexPaths.count == 0) { return nil; }
    
    NSMutableArray *assets = [NSMutableArray arrayWithCapacity:indexPaths.count];
    for (NSIndexPath *indexPath in indexPaths) {
        if (indexPath.item < self.fetchResult.count) {
            PHAsset *asset = self.fetchResult[indexPath.item];
            [assets addObject:asset];
        }
    }
    return assets;
}

#pragma mark - UIScrollViewDelegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    [self updateCachedAssets];
}

#pragma mark - UICollectionViewDataSource

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return self.fetchResult.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    PHAsset *asset = self.fetchResult[indexPath.item];
    
    LDOAssetCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"LDOAssetCell" forIndexPath:indexPath];
    cell.showsOverlayViewWhenSelected = self.assetSelection.allowsMultipleSelection;
    CGSize itemSize = [(UICollectionViewFlowLayout *)collectionView.collectionViewLayout itemSize];
    [cell prepareForAsset:asset itemSize:itemSize indexPath:indexPath imageManager:self.imageManager];
    
    // Selection state
    if ([self.assetSelection containsAsset:asset]) {
        [cell setSelected:YES];
        [collectionView selectItemAtIndexPath:indexPath animated:NO scrollPosition:UICollectionViewScrollPositionNone];
    }
    
    return cell;
}

- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath
{
    if (kind != UICollectionElementKindSectionFooter) {
        UICollectionReusableView *mustNotReturnNilView = [UICollectionReusableView new];
        mustNotReturnNilView.hidden = YES;
        return mustNotReturnNilView;
    }
    
    UICollectionReusableView *footerView = [collectionView dequeueReusableSupplementaryViewOfKind:kind withReuseIdentifier:@"LDOFooterView" forIndexPath:indexPath];
    
    // Number of assets
    UILabel *label = [UILabel new];
    label.textAlignment = NSTextAlignmentCenter;
    [footerView addSubview:label];
    label.translatesAutoresizingMaskIntoConstraints = NO;
    [footerView addConstraint:[label.leftAnchor constraintEqualToAnchor:footerView.leftAnchor]];
    [footerView addConstraint:[label.rightAnchor constraintEqualToAnchor:footerView.rightAnchor]];
    [footerView addConstraint:[label.centerYAnchor constraintEqualToAnchor:footerView.centerYAnchor]];
    
    NSBundle *bundle = [LDOImagePickerBundle ldoImagePickerBundle];
    NSUInteger numberOfPhotos = [self.fetchResult countOfAssetsWithMediaType:PHAssetMediaTypeImage];
    NSUInteger numberOfVideos = [self.fetchResult countOfAssetsWithMediaType:PHAssetMediaTypeVideo];
    
    switch (self.mediaType) {
        case LDOImagePickerMediaTypeAny:
        {
            NSString *format;
            if (numberOfPhotos == 1) {
                if (numberOfVideos == 1) {
                    format = NSLocalizedStringFromTableInBundle(@"assets.footer.photo-and-video", @"LDOImagePicker", bundle, nil);
                } else {
                    format = NSLocalizedStringFromTableInBundle(@"assets.footer.photo-and-videos", @"LDOImagePicker", bundle, nil);
                }
            } else if (numberOfVideos == 1) {
                format = NSLocalizedStringFromTableInBundle(@"assets.footer.photos-and-video", @"LDOImagePicker", bundle, nil);
            } else {
                format = NSLocalizedStringFromTableInBundle(@"assets.footer.photos-and-videos", @"LDOImagePicker", bundle, nil);
            }
            
            label.text = [NSString stringWithFormat:format, numberOfPhotos, numberOfVideos];
        }
            break;
            
        case LDOImagePickerMediaTypeImage:
        {
            NSString *key = (numberOfPhotos == 1) ? @"assets.footer.photo" : @"assets.footer.photos";
            NSString *format = NSLocalizedStringFromTableInBundle(key, @"LDOImagePicker", bundle, nil);
            
            label.text = [NSString stringWithFormat:format, numberOfPhotos];
        }
            break;
            
        case LDOImagePickerMediaTypeVideo:
        {
            NSString *key = (numberOfVideos == 1) ? @"assets.footer.video" : @"assets.footer.videos";
            NSString *format = NSLocalizedStringFromTableInBundle(key, @"LDOImagePicker", bundle, nil);
            
            label.text = [NSString stringWithFormat:format, numberOfVideos];
        }
            break;
    }
    
    return footerView;
}


#pragma mark - UICollectionViewDelegate

- (BOOL)collectionView:(UICollectionView *)collectionView shouldSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    if ([self.delegate respondsToSelector:@selector(assetsCollectionController:shouldSelectAsset:)]) {
        PHAsset *asset = self.fetchResult[indexPath.item];
        return [self.delegate assetsCollectionController:self shouldSelectAsset:asset];
    }
    
    if ([self.assetSelection isAutoDeselectEnabled]) {
        return YES;
    }
    
    return ![self.assetSelection isMaximumSelectionLimitReached];
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    PHAsset *asset = self.fetchResult[indexPath.item];
    
    // Add asset to set
    [self.assetSelection addAsset:asset];
    
    if (self.assetSelection.allowsMultipleSelection) {
        if (self.assetSelection.isAutoDeselectEnabled && self.assetSelection.count > 1) {
            // Remove previous selected asset from set
            [self.assetSelection removeObjectAtIndex:0];
            
            // Deselect previous selected asset
            if (self.lastSelectedItemIndexPath) {
                [collectionView deselectItemAtIndexPath:self.lastSelectedItemIndexPath animated:NO];
            }
        }
        
        self.lastSelectedItemIndexPath = indexPath;
        
        if ([self.delegate respondsToSelector:@selector(assetsCollectionController:didSelectAsset:)]) {
            [self.delegate assetsCollectionController:self didSelectAsset:asset];
        }
    } else {
        if ([self.delegate respondsToSelector:@selector(assetsCollectionController:didSelectAsset:)]) {
            [self.delegate assetsCollectionController:self didSelectAsset:asset];
        }
        
        if ([self.delegate respondsToSelector:@selector(assetsCollectionControllerDidFinish:)]) {
            [self.delegate assetsCollectionControllerDidFinish:self];
        }
    }
}

- (void)collectionView:(UICollectionView *)collectionView didDeselectItemAtIndexPath:(NSIndexPath *)indexPath
{
    if (!self.assetSelection.allowsMultipleSelection) {
        return;
    }
    
    PHAsset *asset = self.fetchResult[indexPath.item];
    
    // Remove asset from set
    [self.assetSelection removeAsset:asset];
    
    self.lastSelectedItemIndexPath = nil;
    
    if ([self.delegate respondsToSelector:@selector(assetsCollectionController:didDeselectAsset:)]) {
        [self.delegate assetsCollectionController:self didDeselectAsset:asset];
    }
}

#pragma mark - UICollectionViewDelegateFlowLayout

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    CGFloat spacing = 2;
    if ([self.collectionViewLayout isKindOfClass:[UICollectionViewFlowLayout class]]) {
        spacing = [(UICollectionViewFlowLayout *)self.collectionViewLayout minimumInteritemSpacing];
    }
    CGFloat width = (CGRectGetWidth(self.collectionView.frame) - spacing * (self.numberOfColumns - 1)) / self.numberOfColumns;
    
    return CGSizeMake(width, width);
}

#pragma mark - PHPhotoLibraryChangeObserver

- (void)photoLibraryDidChange:(PHChange *)changeInstance
{
    dispatch_async(dispatch_get_main_queue(), ^{
        PHFetchResultChangeDetails *collectionChanges = [changeInstance changeDetailsForFetchResult:self.fetchResult];
        
        if (collectionChanges) {
            // Get the new fetch result
            self.fetchResult = [collectionChanges fetchResultAfterChanges];
            
            if (![collectionChanges hasIncrementalChanges] || [collectionChanges hasMoves]) {
                // We need to reload all if the incremental diffs are not available
                [self.collectionView reloadData];
            } else {
                // If we have incremental diffs, tell the collection view to animate insertions and deletions
                [self.collectionView performBatchUpdates:^{
                    NSIndexSet *removedIndexes = [collectionChanges removedIndexes];
                    if ([removedIndexes count]) {
                        [self.collectionView deleteItemsAtIndexPaths:[removedIndexes qb_indexPathsFromIndexesWithSection:0]];
                    }
                    
                    NSIndexSet *insertedIndexes = [collectionChanges insertedIndexes];
                    if ([insertedIndexes count]) {
                        [self.collectionView insertItemsAtIndexPaths:[insertedIndexes qb_indexPathsFromIndexesWithSection:0]];
                    }
                    
                    NSIndexSet *changedIndexes = [collectionChanges changedIndexes];
                    if ([changedIndexes count]) {
                        [self.collectionView reloadItemsAtIndexPaths:[changedIndexes qb_indexPathsFromIndexesWithSection:0]];
                    }
                } completion:NULL];
            }
            
            [self resetCachedAssets];
        }
    });
}

@end
