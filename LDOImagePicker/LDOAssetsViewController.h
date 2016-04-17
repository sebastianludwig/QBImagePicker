//
//  LDOAssetsViewController.h
//  LDOImagePicker
//
//  Created by Sebastian Ludwig on 17.04.2016.
//  Copyright (c) 2016 Sebastian Ludwig. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Photos/Photos.h>
#import "LDOAssetsCollectionController.h"


@class LDOAssetsViewController;

@protocol LDOAssetsViewControllerDelegate <NSObject>

- (void)assetsViewControllerDidFinish:(LDOAssetsViewController *)assetsViewController;

@optional
- (void)assetsViewController:(LDOAssetsViewController *)assetsViewController didSelectAsset:(PHAsset *)asset;
- (void)assetsViewController:(LDOAssetsViewController *)assetsViewController didDeselectAsset:(PHAsset *)asset;

@end


@interface LDOAssetsViewController : UIViewController

@property (nonatomic, weak) id<LDOAssetsViewControllerDelegate> delegate;

@property (nonatomic, readonly) LDOAssetsCollectionController *collectionViewController;

@property (nonatomic, assign) NSUInteger numberOfColumnsInPortrait; // TODO: rather use size classes here
@property (nonatomic, assign) NSUInteger numberOfColumnsInLandscape;
@property (nonatomic, assign) BOOL showsNumberOfSelectedAssets;

@end
