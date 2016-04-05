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

@class QBAssetsViewController;

@protocol QBAssetsViewControllerDelegate <NSObject>

- (void)qb_assetsViewControllerDidFinish:(QBAssetsViewController *)assetsViewController;

@optional
- (BOOL)qb_assetsViewController:(QBAssetsViewController *)assetsViewController shouldSelectAsset:(PHAsset *)asset;
- (void)qb_assetsViewController:(QBAssetsViewController *)assetsViewController didSelectAsset:(PHAsset *)asset;
- (void)qb_assetsViewController:(QBAssetsViewController *)assetsViewController didDeselectAsset:(PHAsset *)asset;

@end


@interface QBAssetsViewController : UICollectionViewController

@property (nonatomic, weak) id<QBAssetsViewControllerDelegate> delegate;
@property (nonatomic, strong) QBAssetSelection *assetSelection; // TODO: setter should update Done button state and reload the collection view
@property (nonatomic, strong) PHAssetCollection *assetCollection;

@property (nonatomic, assign) BOOL showsNumberOfSelectedAssets;

@property (nonatomic, assign) NSUInteger numberOfColumnsInPortrait; // TODO: rather use size classes here
@property (nonatomic, assign) NSUInteger numberOfColumnsInLandscape;

@property (nonatomic, assign) QBImagePickerMediaType mediaType;     // TODO: try to get rid of this - maybe by passing the fetch options from the AlbumsViewController. Otherwise a setter is needed (that triggers whatever updates are necessary - closely related to assetsCollection property)

@end
