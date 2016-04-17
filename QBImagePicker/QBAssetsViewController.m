//
//  QBAssetsViewController.m
//  QBImagePicker
//
//  Created by Katsuma Tanaka on 2015/04/03.
//  Copyright (c) 2015 Katsuma Tanaka. All rights reserved.
//

#import "QBAssetsViewController.h"
#import "QBBundle.h"

// Views
#import "QBAssetCell.h"
#import "QBVideoIndicatorView.h"

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




@interface QBAssetCollectionViewController () <PHPhotoLibraryChangeObserver>

@property (nonatomic) PHCachingImageManager *imageManager;
@property (nonatomic) CGRect previousPreheatRect;

@property (nonatomic) NSIndexPath *lastSelectedItemIndexPath;

@end


@implementation QBAssetCollectionViewController

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

- (void)setAssetSelection:(QBAssetSelection *)assetSelection
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
    UINib *nib = [UINib nibWithNibName:@"QBAssetCell" bundle:[QBBundle imagePickerBundle]];
    [self.collectionView registerNib:nib forCellWithReuseIdentifier:@"QBAssetCell"];
    [self.collectionView registerClass:[UICollectionReusableView class] forSupplementaryViewOfKind:UICollectionElementKindSectionFooter withReuseIdentifier:@"QBFooterView"];
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
    
    QBAssetCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"QBAssetCell" forIndexPath:indexPath];
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
    
    UICollectionReusableView *footerView = [collectionView dequeueReusableSupplementaryViewOfKind:kind withReuseIdentifier:@"QBFooterView" forIndexPath:indexPath];
    
    // Number of assets
    UILabel *label = [UILabel new];
    label.textAlignment = NSTextAlignmentCenter;
    [footerView addSubview:label];
    label.translatesAutoresizingMaskIntoConstraints = NO;
    [footerView addConstraint:[label.leftAnchor constraintEqualToAnchor:footerView.leftAnchor]];
    [footerView addConstraint:[label.rightAnchor constraintEqualToAnchor:footerView.rightAnchor]];
    [footerView addConstraint:[label.centerYAnchor constraintEqualToAnchor:footerView.centerYAnchor]];
    
    NSBundle *bundle = [QBBundle imagePickerBundle];
    NSUInteger numberOfPhotos = [self.fetchResult countOfAssetsWithMediaType:PHAssetMediaTypeImage];
    NSUInteger numberOfVideos = [self.fetchResult countOfAssetsWithMediaType:PHAssetMediaTypeVideo];
    
    switch (self.mediaType) {
        case QBImagePickerMediaTypeAny:
        {
            NSString *format;
            if (numberOfPhotos == 1) {
                if (numberOfVideos == 1) {
                    format = NSLocalizedStringFromTableInBundle(@"assets.footer.photo-and-video", @"QBImagePicker", bundle, nil);
                } else {
                    format = NSLocalizedStringFromTableInBundle(@"assets.footer.photo-and-videos", @"QBImagePicker", bundle, nil);
                }
            } else if (numberOfVideos == 1) {
                format = NSLocalizedStringFromTableInBundle(@"assets.footer.photos-and-video", @"QBImagePicker", bundle, nil);
            } else {
                format = NSLocalizedStringFromTableInBundle(@"assets.footer.photos-and-videos", @"QBImagePicker", bundle, nil);
            }
            
            label.text = [NSString stringWithFormat:format, numberOfPhotos, numberOfVideos];
        }
            break;
            
        case QBImagePickerMediaTypeImage:
        {
            NSString *key = (numberOfPhotos == 1) ? @"assets.footer.photo" : @"assets.footer.photos";
            NSString *format = NSLocalizedStringFromTableInBundle(key, @"QBImagePicker", bundle, nil);
            
            label.text = [NSString stringWithFormat:format, numberOfPhotos];
        }
            break;
            
        case QBImagePickerMediaTypeVideo:
        {
            NSString *key = (numberOfVideos == 1) ? @"assets.footer.video" : @"assets.footer.videos";
            NSString *format = NSLocalizedStringFromTableInBundle(key, @"QBImagePicker", bundle, nil);
            
            label.text = [NSString stringWithFormat:format, numberOfVideos];
        }
            break;
    }
    
    return footerView;
}


#pragma mark - UICollectionViewDelegate

- (BOOL)collectionView:(UICollectionView *)collectionView shouldSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    if ([self.delegate respondsToSelector:@selector(qb_assetCollectionController:shouldSelectAsset:)]) {
        PHAsset *asset = self.fetchResult[indexPath.item];
        return [self.delegate qb_assetCollectionController:self shouldSelectAsset:asset];
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
        
        if ([self.delegate respondsToSelector:@selector(qb_assetCollectionController:didSelectAsset:)]) {
            [self.delegate qb_assetCollectionController:self didSelectAsset:asset];
        }
    } else {
        if ([self.delegate respondsToSelector:@selector(qb_assetCollectionController:didSelectAsset:)]) {
            [self.delegate qb_assetCollectionController:self didSelectAsset:asset];
        }
        
        if ([self.delegate respondsToSelector:@selector(qb_assetCollectionControllerDidFinish:)]) {
            [self.delegate qb_assetCollectionControllerDidFinish:self];
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
    
    if ([self.delegate respondsToSelector:@selector(qb_assetCollectionController:didDeselectAsset:)]) {
        [self.delegate qb_assetCollectionController:self didDeselectAsset:asset];
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














@interface QBAssetsViewController () <QBAssetCollectionControllerDelegate>

@property (nonatomic, strong) NSBundle *assetBundle;

@property (nonatomic, strong) UIBarButtonItem *infoToolbarItem;
@property (nonatomic, strong) IBOutlet UIBarButtonItem *doneButton;

@property (nonatomic, assign) BOOL scrollToBottomEnabled;

@end

@implementation QBAssetsViewController

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self setup];
    }
    return self;
}

- (instancetype)init
{
    if (self = [super init]) {
        [self setup];
    }
    return self;
}

- (void)setup
{
    _assetBundle = [QBBundle imagePickerBundle];
    _collectionViewController = [QBAssetCollectionViewController new];
    _collectionViewController.delegate = self;
    
    
    // Space
    UIBarButtonItem *leftSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:NULL];
    UIBarButtonItem *rightSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:NULL];
    
    // Info label
    NSDictionary *attributes = @{ NSForegroundColorAttributeName: [UIColor blackColor] };
    self.infoToolbarItem = [[UIBarButtonItem alloc] initWithTitle:@"" style:UIBarButtonItemStylePlain target:nil action:NULL];
    self.infoToolbarItem.enabled = NO;
    [self.infoToolbarItem setTitleTextAttributes:attributes forState:UIControlStateNormal];
    [self.infoToolbarItem setTitleTextAttributes:attributes forState:UIControlStateDisabled];
    
    self.toolbarItems = @[leftSpace, self.infoToolbarItem, rightSpace];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    UICollectionView *collectionView = [[UICollectionView alloc] initWithFrame:self.view.bounds collectionViewLayout:self.collectionViewController.collectionViewLayout];
    collectionView.backgroundColor = [UIColor whiteColor];
    
    self.collectionViewController.collectionView = collectionView;
    collectionView.dataSource = self.collectionViewController;
    collectionView.delegate = self.collectionViewController;
    
    [self.view addSubview:collectionView];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    // Show/hide 'Done' button
    if (self.collectionViewController.assetSelection.allowsMultipleSelection) {
        [self.navigationItem setRightBarButtonItem:self.doneButton animated:NO];
    } else {
        [self.navigationItem setRightBarButtonItem:nil animated:NO];
    }
    
    if (UIInterfaceOrientationIsPortrait([[UIApplication sharedApplication] statusBarOrientation])) {
        [self updateNumberOfCollectionViewColumnsForSize:self.view.frame.size];
    }
    
    [self updateDoneButtonState];
    [self updateSelectionInfo];
    [self.collectionViewController.collectionView reloadData];
    
    // Scroll to bottom
    if (self.collectionViewController.fetchResult.count > 0 && self.isMovingToParentViewController && self.scrollToBottomEnabled) {
        NSIndexPath *indexPath = [NSIndexPath indexPathForItem:(self.collectionViewController.fetchResult.count - 1) inSection:0];
        [self.collectionViewController.collectionView scrollToItemAtIndexPath:indexPath atScrollPosition:UICollectionViewScrollPositionTop animated:NO];
    }
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    self.scrollToBottomEnabled = NO;
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    self.scrollToBottomEnabled = YES;
    
    [self.collectionViewController updateCachedAssets];    // TODO: get rid of this call
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator
{
    // Save indexPath for the last item
    NSIndexPath *indexPath = [[self.collectionViewController.collectionView indexPathsForVisibleItems] lastObject];
    
    [self updateNumberOfCollectionViewColumnsForSize:size];
    
    // Restore scroll position
    [coordinator animateAlongsideTransition:nil completion:^(id<UIViewControllerTransitionCoordinatorContext> context) {
        [self.collectionViewController.collectionView scrollToItemAtIndexPath:indexPath atScrollPosition:UICollectionViewScrollPositionBottom animated:NO];
    }];
}


#pragma mark Actions

- (IBAction)done:(id)sender
{
    [self.delegate qb_assetsViewControllerDidFinish:self];
}


#pragma mark Update UI

- (void)updateNumberOfCollectionViewColumnsForSize:(CGSize)size
{
    self.collectionViewController.numberOfColumns = size.height > size.width ? self.numberOfColumnsInPortrait : self.numberOfColumnsInLandscape;
}

- (void)updateUI
{
    [self updateDoneButtonState];
    
    if (self.showsNumberOfSelectedAssets) {
        [self updateSelectionInfo];
        
        [self.navigationController setToolbarHidden:self.collectionViewController.assetSelection.count == 0 animated:YES];
    }
}

- (void)updateSelectionInfo
{
    NSUInteger count = self.collectionViewController.assetSelection.count;
    
    if (count > 0) {
        NSString *identifier = count == 1 ? @"assets.toolbar.item-selected" : @"assets.toolbar.items-selected";
        NSString *format = NSLocalizedStringFromTableInBundle(identifier, @"QBImagePicker", self.assetBundle, nil);
        NSString *title = [NSString stringWithFormat:format, count];
        [self.infoToolbarItem setTitle:title];
    } else {
        [self.infoToolbarItem setTitle:@""];
    }
}

- (void)updateDoneButtonState
{
    self.doneButton.enabled = self.collectionViewController.assetSelection.isMinimumSelectionLimitFulfilled;
}

#pragma mark - QBAssetCollectionControllerDelegate

- (void)qb_assetCollectionControllerDidFinish:(QBAssetCollectionViewController *)assetCollectionController
{
    [self.delegate qb_assetsViewControllerDidFinish:self];
}

- (void)qb_assetCollectionController:(QBAssetCollectionViewController *)assetCollectionController didSelectAsset:(PHAsset *)asset
{
    [self updateUI];
    
    if ([self.delegate respondsToSelector:@selector(qb_assetsViewController:didSelectAsset:)]) {
        [self.delegate qb_assetsViewController:self didSelectAsset:asset];
    }
}

- (void)qb_assetCollectionController:(QBAssetCollectionViewController *)assetCollectionController didDeselectAsset:(PHAsset *)asset
{
    [self updateUI];
    
    if ([self.delegate respondsToSelector:@selector(qb_assetCollectionController:didDeselectAsset:)]) {
        [self.delegate qb_assetsViewController:self didDeselectAsset:asset];
    }
}

@end
