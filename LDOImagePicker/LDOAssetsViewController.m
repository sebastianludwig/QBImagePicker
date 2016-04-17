//
//  LDOAssetsViewController.m
//  LDOImagePicker
//
//  Created by Sebastian Ludwig on 17.04.2016.
//  Copyright (c) 2016 Sebastian Ludwig. All rights reserved.
//

#import "LDOAssetsViewController.h"
#import "LDOImagePickerBundle.h"


@interface LDOAssetsViewController () <LDOAssetsCollectionControllerDelegate>

@property (nonatomic, strong) NSBundle *assetBundle;

@property (nonatomic, strong) UIBarButtonItem *infoToolbarItem;
@property (nonatomic, strong) IBOutlet UIBarButtonItem *doneButton;

@property (nonatomic, assign) BOOL scrollToBottomEnabled;

@end

@implementation LDOAssetsViewController

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
    _assetBundle = [LDOImagePickerBundle ldoImagePickerBundle];
    _collectionViewController = [LDOAssetsCollectionController new];
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
    
    [self.collectionViewController updateCachedAssets];    // TODO: get rid of this call and make private again (maybe startCachingAssets & stopCachingAssets)
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
    [self.delegate assetsViewControllerDidFinish:self];
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
        NSString *format = NSLocalizedStringFromTableInBundle(identifier, @"LDOImagePicker", self.assetBundle, nil);
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

#pragma mark - LDOAssetsCollectionControllerDelegate

- (void)assetsCollectionControllerDidFinish:(LDOAssetsCollectionController *)assetsCollectionController
{
    [self.delegate assetsViewControllerDidFinish:self];
}

- (void)assetsCollectionController:(LDOAssetsCollectionController *)assetsCollectionController didSelectAsset:(PHAsset *)asset
{
    [self updateUI];
    
    if ([self.delegate respondsToSelector:@selector(assetsViewController:didSelectAsset:)]) {
        [self.delegate assetsViewController:self didSelectAsset:asset];
    }
}

- (void)assetsCollectionController:(LDOAssetsCollectionController *)assetsCollectionController didDeselectAsset:(PHAsset *)asset
{
    [self updateUI];
    
    if ([self.delegate respondsToSelector:@selector(assetsViewController:didDeselectAsset:)]) {
        [self.delegate assetsViewController:self didDeselectAsset:asset];
    }
}

@end
