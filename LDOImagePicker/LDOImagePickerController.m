//
//  LDOImagePickerController.m
//  LDOImagePicker
//
//  Created by Sebastian Ludwig on 17.04.2016.
//  Copyright (c) 2016 Sebastian Ludwig. All rights reserved.
//

#import "LDOImagePickerController.h"
#import <Photos/Photos.h>
#import "LDOAlbumsViewController.h"
#import "LDOAssetsViewController.h"
#import "LDOImagePickerBundle.h"

@interface LDOImagePickerController () <LDOAlbumsViewControllerDelegate, LDOAssetsViewControllerDelegate>

@property (nonatomic, strong) UINavigationController *albumsNavigationController;
@property (nonatomic, strong) LDOAlbumsViewController *albumsViewController;

@property (nonatomic, strong) NSBundle *assetBundle;

@end

@implementation LDOImagePickerController

- (instancetype)init
{
    self = [super init];
    
    if (self) {
        // Set default values
        _numberOfColumnsInPortrait = 4;
        _numberOfColumnsInLandscape = 7;
        
        _assetSelection = [LDOAssetSelection new];
        
        // Get asset bundle
        _assetBundle = [LDOImagePickerBundle ldoImagePickerBundle];
        
        [self addAlbumsViewController];
    }
    
    return self;
}

- (void)addAlbumsViewController
{
    self.albumsViewController = [[LDOAlbumsViewController alloc] init];
    self.albumsViewController.delegate = self;
    self.albumsViewController.assetSelection = self.assetSelection;
    self.albumsViewController.albumsController.mediaType = self.mediaType;
    self.albumsViewController.navigationItem.title = NSLocalizedStringFromTableInBundle(@"albums.title", @"LDOImagePicker", _assetBundle, nil);
    
    self.albumsNavigationController = [[UINavigationController alloc] initWithRootViewController:self.albumsViewController];
    
    [self addChildViewController:self.albumsNavigationController];
    
    self.albumsNavigationController.view.frame = self.view.bounds;
    self.albumsNavigationController.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.albumsNavigationController.view.translatesAutoresizingMaskIntoConstraints = YES;
    [self.view addSubview:self.albumsNavigationController.view];

    [self.albumsNavigationController didMoveToParentViewController:self];
}

- (NSString *)prompt
{
    return self.albumsViewController.navigationItem.prompt;
}

- (void)setPrompt:(NSString *)prompt
{
    self.albumsViewController.navigationItem.prompt = prompt;
}

- (BOOL)allowsMultipleSelection
{
    return self.assetSelection.allowsMultipleSelection;
}

- (void)setAllowsMultipleSelection:(BOOL)allowsMultipleSelection
{
    self.assetSelection.allowsMultipleSelection = allowsMultipleSelection;
}

- (NSUInteger)minimumNumberOfSelection {
    return self.assetSelection.minimumNumberOfAssets;
}

- (void)setMinimumNumberOfSelection:(NSUInteger)minimumNumberOfSelection
{
    self.assetSelection.minimumNumberOfAssets = minimumNumberOfSelection;
}

- (NSUInteger)maximumNumberOfSelection
{
    return self.assetSelection.maximumNumberOfAssets;
}

- (void)setMaximumNumberOfSelection:(NSUInteger)maximumNumberOfSelection
{
    self.assetSelection.maximumNumberOfAssets = maximumNumberOfSelection;
}

- (NSArray *)assetCollectionSubtypes
{
    return self.albumsViewController.albumsController.collectionsController.enabledAssetCollectionSubtypes;
}

- (void)setAssetCollectionSubtypes:(NSArray *)assetCollectionSubtypes
{
    self.albumsViewController.albumsController.collectionsController.enabledAssetCollectionSubtypes = assetCollectionSubtypes;
}

#pragma mark - LDOAlbumsViewControllerDelegate

- (void)albumsViewController:(LDOAlbumsViewController *)albumsViewController didSelectAssetCollection:(LDOAssetCollection *)assetCollection
{
    LDOAssetsViewController *assetsViewController = [LDOAssetsViewController new];
    
    assetsViewController.title = assetCollection.collection.localizedTitle;
    
    assetsViewController.delegate = self;
    assetsViewController.navigationItem.prompt = self.prompt;
    assetsViewController.showsNumberOfSelectedAssets = self.showsNumberOfSelectedAssets;
    assetsViewController.numberOfColumnsInPortrait = self.numberOfColumnsInPortrait;
    assetsViewController.numberOfColumnsInLandscape = self.numberOfColumnsInLandscape;
    
    assetsViewController.collectionViewController.assetSelection = self.assetSelection;
    assetsViewController.collectionViewController.mediaType = self.mediaType;
    
    assetsViewController.collectionViewController.fetchResult = assetCollection.assetFetchResult;
    
    [self.albumsNavigationController pushViewController:assetsViewController animated:YES];
}

- (void)albumsViewControllerDidFinish:(LDOAlbumsViewController *)albumsViewController
{
    if ([self.delegate respondsToSelector:@selector(imagePickerController:didFinishPickingAssets:)]) {
        [self.delegate imagePickerController:self didFinishPickingAssets:self.assetSelection.assets.array];
    }
}

- (void)albumsViewControllerDidCancel:(LDOAlbumsViewController *)albumsViewController
{
    if ([self.delegate respondsToSelector:@selector(imagePickerControllerDidCancel:)]) {
        [self.delegate imagePickerControllerDidCancel:self];
    }
}

#pragma mark - LDOAssetsViewControllerDelegate

- (void)assetsViewControllerDidFinish:(LDOAssetsViewController *)assetsViewController
{
    if ([self.delegate respondsToSelector:@selector(imagePickerController:didFinishPickingAssets:)]) {
        [self.delegate imagePickerController:self didFinishPickingAssets:self.assetSelection.assets.array];
    }
}

@end
