//
//  QBImagePickerController.m
//  QBImagePicker
//
//  Created by Katsuma Tanaka on 2015/04/03.
//  Copyright (c) 2015 Katsuma Tanaka. All rights reserved.
//

#import "QBImagePickerController.h"
#import <Photos/Photos.h>

// ViewControllers
#import "QBAlbumsViewController.h"
#import "QBAssetsViewController.h"

@interface QBImagePickerController () <QBAlbumsViewControllerDelegate>

@property (nonatomic, strong) UINavigationController *albumsNavigationController;

@property (nonatomic, strong) NSBundle *assetBundle;

@end

@implementation QBImagePickerController

- (instancetype)init
{
    self = [super init];
    
    if (self) {
        // Set default values
        self.assetCollectionSubtypes = @[
                                         @(PHAssetCollectionSubtypeSmartAlbumUserLibrary),
                                         @(PHAssetCollectionSubtypeAlbumMyPhotoStream),
                                         @(PHAssetCollectionSubtypeSmartAlbumPanoramas),
                                         @(PHAssetCollectionSubtypeSmartAlbumVideos),
                                         @(PHAssetCollectionSubtypeSmartAlbumBursts)
                                         ];
        self.minimumNumberOfSelection = 1;
        self.numberOfColumnsInPortrait = 4;
        self.numberOfColumnsInLandscape = 7;
        
        _selectedAssets = [NSMutableOrderedSet orderedSet];
        
        // Get asset bundle
        self.assetBundle = [NSBundle bundleForClass:[self class]];
        NSString *bundlePath = [self.assetBundle pathForResource:@"QBImagePicker" ofType:@"bundle"];
        if (bundlePath) {
            self.assetBundle = [NSBundle bundleWithPath:bundlePath];
        }
        
        [self setUpAlbumsViewController];
        
        // Set instance
        QBAlbumsViewController *albumsViewController = (QBAlbumsViewController *)self.albumsNavigationController.topViewController;
        albumsViewController.imagePickerController = self;
        albumsViewController.delegate = self;
        albumsViewController.navigationItem.title = NSLocalizedStringFromTableInBundle(@"albums.title", @"QBImagePicker", self.assetBundle, nil);
        albumsViewController.navigationItem.prompt = self.prompt;
    }
    
    return self;
}

- (void)setUpAlbumsViewController
{
    // Add QBAlbumsViewController as a child
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"QBImagePicker" bundle:self.assetBundle];
    UINavigationController *navigationController = [storyboard instantiateViewControllerWithIdentifier:@"QBAlbumsNavigationController"];
    
    [self addChildViewController:navigationController];
    
    navigationController.view.frame = self.view.bounds;
    [self.view addSubview:navigationController.view];
    
    [navigationController didMoveToParentViewController:self];
    
    self.albumsNavigationController = navigationController;
}

#pragma mark - QBAlbumsViewControllerDelegate

- (void)qb_albumsViewController:(QBAlbumsViewController *)albumsViewController didSelectAssetCollection:(PHAssetCollection *)assetCollection
{
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"QBImagePicker" bundle:self.assetBundle];
    QBAssetsViewController *assetsViewController = [storyboard instantiateViewControllerWithIdentifier:@"QBAssetsViewController"];
    assetsViewController.imagePickerController = self;
    
    assetsViewController.navigationItem.prompt = self.prompt;
    assetsViewController.showsNumberOfSelectedAssets = self.showsNumberOfSelectedAssets;
    assetsViewController.numberOfColumnsInPortrait = self.numberOfColumnsInPortrait;
    assetsViewController.numberOfColumnsInLandscape = self.numberOfColumnsInLandscape;
    assetsViewController.allowsMultipleSelection = self.allowsMultipleSelection;
    assetsViewController.minimumNumberOfSelection = self.minimumNumberOfSelection;
    assetsViewController.maximumNumberOfSelection = self.maximumNumberOfSelection;
    assetsViewController.mediaType = self.mediaType;
    
    assetsViewController.assetCollection = assetCollection;
    
    [self.albumsNavigationController pushViewController:assetsViewController animated:YES];
}

@end
