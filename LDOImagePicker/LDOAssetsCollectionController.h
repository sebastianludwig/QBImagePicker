//
//  LDOAssetsCollectionController.h
//  LDOImagePicker
//
//  Created by Sebastian Ludwig on 17.04.16.
//  Copyright (c) 2016 Sebastian Ludwig. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Photos/Photos.h>
#import "LDOImagePickerTypes.h"
#import "LDOAssetSelection.h"

@class LDOAssetsCollectionController;

@protocol LDOAssetsCollectionControllerDelegate <NSObject>

- (void)assetsCollectionControllerDidFinish:(LDOAssetsCollectionController *)assetsCollectionController;

@optional
- (BOOL)assetsCollectionController:(LDOAssetsCollectionController *)assetsCollectionController shouldSelectAsset:(PHAsset *)asset;
- (void)assetsCollectionController:(LDOAssetsCollectionController *)assetsCollectionController didSelectAsset:(PHAsset *)asset;
- (void)assetsCollectionController:(LDOAssetsCollectionController *)assetsCollectionController didDeselectAsset:(PHAsset *)asset;

@end


@interface LDOAssetsCollectionController : NSObject <UICollectionViewDelegate, UICollectionViewDataSource>

@property (nonatomic, weak) IBOutlet UICollectionView *collectionView;
@property (nonatomic, weak) IBOutlet id<LDOAssetsCollectionControllerDelegate> delegate;

@property (nonatomic) PHFetchResult *fetchResult;
@property (nonatomic, assign) LDOImagePickerMediaType mediaType;

@property (nonatomic) LDOAssetSelection *assetSelection; // TODO: setter should update Done button state and reload the collection view

@property (nonatomic) UICollectionViewLayout *collectionViewLayout;
@property (nonatomic, assign) NSUInteger numberOfColumns;

- (void)updateCachedAssets;

@end
