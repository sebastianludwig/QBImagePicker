//
//  LDOImagePickerController.h
//  LDOImagePicker
//
//  Created by Sebastian Ludwig on 17.04.2016.
//  Copyright (c) 2016 Sebastian Ludwig. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Photos/Photos.h>
#import "LDOImagePickerTypes.h"
#import "LDOAssetSelection.h"

@class LDOImagePickerController;

@protocol LDOImagePickerControllerDelegate <NSObject>

@optional
- (void)imagePickerController:(LDOImagePickerController *)imagePickerController didFinishPickingAssets:(NSArray *)assets;
- (void)imagePickerControllerDidCancel:(LDOImagePickerController *)imagePickerController;

- (BOOL)imagePickerController:(LDOImagePickerController *)imagePickerController shouldSelectAsset:(PHAsset *)asset;
- (void)imagePickerController:(LDOImagePickerController *)imagePickerController didSelectAsset:(PHAsset *)asset;
- (void)imagePickerController:(LDOImagePickerController *)imagePickerController didDeselectAsset:(PHAsset *)asset;

@end

// TODO:
// assetsVC does not implement deselection logic but asks its delegate to deselect an asset
// move mediaType to LDOAssetsController, let it request the count in the background and use the fetch result to pass it to AssetsViewController?

@interface LDOImagePickerController : UIViewController

@property (nonatomic, weak) id<LDOImagePickerControllerDelegate> delegate;

@property (nonatomic, strong, readonly) LDOAssetSelection *assetSelection;

@property (nonatomic, copy) NSArray *assetCollectionSubtypes;
@property (nonatomic, assign) LDOImagePickerMediaType mediaType;

@property (nonatomic, assign) BOOL allowsMultipleSelection;
@property (nonatomic, assign) NSUInteger minimumNumberOfSelection;
@property (nonatomic, assign) NSUInteger maximumNumberOfSelection;

@property (nonatomic, copy) NSString *prompt;
@property (nonatomic, assign) BOOL showsNumberOfSelectedAssets;

@property (nonatomic, assign) NSUInteger numberOfColumnsInPortrait;
@property (nonatomic, assign) NSUInteger numberOfColumnsInLandscape;


@end
