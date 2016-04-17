//
//  QBAssetsViewController.h
//  QBImagePicker
//
//  Created by Katsuma Tanaka on 2015/04/03.
//  Copyright (c) 2015 Katsuma Tanaka. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Photos/Photos.h>
#import "QBImagePickerTypes.h"
#import "QBAssetSelection.h"



@class QBAssetCollectionViewController;

@protocol QBAssetCollectionControllerDelegate <NSObject>

- (void)qb_assetCollectionControllerDidFinish:(QBAssetCollectionViewController *)assetCollectionController;

@optional
- (BOOL)qb_assetCollectionController:(QBAssetCollectionViewController *)assetCollectionController shouldSelectAsset:(PHAsset *)asset;
- (void)qb_assetCollectionController:(QBAssetCollectionViewController *)assetCollectionController didSelectAsset:(PHAsset *)asset;
- (void)qb_assetCollectionController:(QBAssetCollectionViewController *)assetCollectionController didDeselectAsset:(PHAsset *)asset;

@end


@interface QBAssetCollectionViewController : NSObject <UICollectionViewDelegate, UICollectionViewDataSource>

@property (nonatomic, weak) IBOutlet UICollectionView *collectionView;
@property (nonatomic, weak) IBOutlet id<QBAssetCollectionControllerDelegate> delegate;

@property (nonatomic) PHFetchResult *fetchResult;
@property (nonatomic, assign) QBImagePickerMediaType mediaType;

@property (nonatomic) QBAssetSelection *assetSelection; // TODO: setter should update Done button state and reload the collection view

@property (nonatomic) UICollectionViewLayout *collectionViewLayout;
@property (nonatomic, assign) NSUInteger numberOfColumns;

@end






@class QBAssetsViewController;

@protocol QBAssetsViewControllerDelegate <NSObject>

- (void)qb_assetsViewControllerDidFinish:(QBAssetsViewController *)assetsViewController;

@optional
- (void)qb_assetsViewController:(QBAssetsViewController *)assetsViewController didSelectAsset:(PHAsset *)asset;
- (void)qb_assetsViewController:(QBAssetsViewController *)assetsViewController didDeselectAsset:(PHAsset *)asset;

@end


@interface QBAssetsViewController : UIViewController

@property (nonatomic, weak) id<QBAssetsViewControllerDelegate> delegate;

@property (nonatomic, readonly) QBAssetCollectionViewController *collectionViewController;

@property (nonatomic, assign) NSUInteger numberOfColumnsInPortrait; // TODO: rather use size classes here
@property (nonatomic, assign) NSUInteger numberOfColumnsInLandscape;
@property (nonatomic, assign) BOOL showsNumberOfSelectedAssets;

@end
