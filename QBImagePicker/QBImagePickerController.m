//
//  QBImagePickerController.m
//  QBImagePicker
//
//  Created by Katsuma Tanaka on 2015/04/03.
//  Copyright (c) 2015 Katsuma Tanaka. All rights reserved.
//

#import "QBImagePickerController.h"
#import <Photos/Photos.h>
#import "QBAlbumsViewController.h"
#import "QBAssetsViewController.h"
#import "QBBundle.h"

@interface QBImagePickerController () <QBAlbumsViewControllerDelegate, QBAssetsViewControllerDelegate>

@property (nonatomic, strong) UINavigationController *albumsNavigationController;
@property (nonatomic, strong) QBAlbumsViewController *albumsViewController;

@property (nonatomic, strong) NSBundle *assetBundle;

@end

@implementation QBImagePickerController

- (instancetype)init
{
    self = [super init];
    
    if (self) {
        // Set default values
        _numberOfColumnsInPortrait = 4;
        _numberOfColumnsInLandscape = 7;
        
        _assetSelection = [QBAssetSelection new];
        
        // Get asset bundle
        _assetBundle = [QBBundle imagePickerBundle];
        
        [self addAlbumsViewController];
    }
    
    return self;
}

- (void)addAlbumsViewController
{
    self.albumsViewController = [[QBAlbumsViewController alloc] init];
    self.albumsViewController.delegate = self;
    self.albumsViewController.assetSelection = self.assetSelection;
    self.albumsViewController.tableView.mediaType = self.mediaType;
    self.albumsViewController.navigationItem.title = NSLocalizedStringFromTableInBundle(@"albums.title", @"QBImagePicker", _assetBundle, nil);
    
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
    return self.albumsViewController.tableView.collectionsController.enabledAssetCollectionSubtypes;
}

- (void)setAssetCollectionSubtypes:(NSArray *)assetCollectionSubtypes
{
    self.albumsViewController.tableView.collectionsController.enabledAssetCollectionSubtypes = assetCollectionSubtypes;
}

#pragma mark - QBAlbumsViewControllerDelegate

- (void)qb_albumsViewController:(QBAlbumsViewController *)albumsViewController didSelectAssetCollection:(QBAssetCollection *)assetCollection
{
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"QBImagePicker" bundle:self.assetBundle];
    QBAssetsViewController *assetsViewController = [storyboard instantiateViewControllerWithIdentifier:@"QBAssetsViewController"];
    assetsViewController.delegate = self;
    assetsViewController.navigationItem.prompt = self.prompt;
    assetsViewController.showsNumberOfSelectedAssets = self.showsNumberOfSelectedAssets;
    assetsViewController.numberOfColumnsInPortrait = self.numberOfColumnsInPortrait;
    assetsViewController.numberOfColumnsInLandscape = self.numberOfColumnsInLandscape;
    
    assetsViewController.assetSelection = self.assetSelection;
    assetsViewController.mediaType = self.mediaType;
    
    assetsViewController.assetCollection = assetCollection.collection;
    
    [self.albumsNavigationController pushViewController:assetsViewController animated:YES];
}

- (void)qb_albumsViewControllerDidFinish:(QBAlbumsViewController *)albumsViewController
{
    if ([self.delegate respondsToSelector:@selector(qb_imagePickerController:didFinishPickingAssets:)]) {
        [self.delegate qb_imagePickerController:self didFinishPickingAssets:self.assetSelection.assets.array];
    }
}

- (void)qb_albumsViewControllerDidCancel:(QBAlbumsViewController *)albumsViewController
{
    if ([self.delegate respondsToSelector:@selector(qb_imagePickerControllerDidCancel:)]) {
        [self.delegate qb_imagePickerControllerDidCancel:self];
    }
}

#pragma mark - QBAssetsViewControllerDelegate

- (void)qb_assetsViewControllerDidFinish:(QBAssetsViewController *)assetsViewController
{
    if ([self.delegate respondsToSelector:@selector(qb_imagePickerController:didFinishPickingAssets:)]) {
        [self.delegate qb_imagePickerController:self didFinishPickingAssets:self.assetSelection.assets.array];
    }
}

@end
