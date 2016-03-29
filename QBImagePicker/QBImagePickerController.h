//
//  QBImagePickerController.h
//  QBImagePicker
//
//  Created by Katsuma Tanaka on 2015/04/03.
//  Copyright (c) 2015 Katsuma Tanaka. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Photos/Photos.h>
#import "QBImagePickerTypes.h"

@class QBImagePickerController;

@protocol QBImagePickerControllerDelegate <NSObject>

@optional
- (void)qb_imagePickerController:(QBImagePickerController *)imagePickerController didFinishPickingAssets:(NSArray *)assets;
- (void)qb_imagePickerControllerDidCancel:(QBImagePickerController *)imagePickerController;

- (BOOL)qb_imagePickerController:(QBImagePickerController *)imagePickerController shouldSelectAsset:(PHAsset *)asset;
- (void)qb_imagePickerController:(QBImagePickerController *)imagePickerController didSelectAsset:(PHAsset *)asset;
- (void)qb_imagePickerController:(QBImagePickerController *)imagePickerController didDeselectAsset:(PHAsset *)asset;

@end


// TODO: make this a controller object which is albumVC and assetVC delegate
// assetsVC does not implement deselection logic but asks its delegate to deselect an asset

@interface QBImagePickerController : UIViewController

@property (nonatomic, weak) id<QBImagePickerControllerDelegate> delegate;

@property (nonatomic, strong, readonly) NSMutableOrderedSet *selectedAssets;

@property (nonatomic, copy) NSArray *assetCollectionSubtypes;
@property (nonatomic, assign) QBImagePickerMediaType mediaType;

@property (nonatomic, assign) BOOL allowsMultipleSelection;
@property (nonatomic, assign) NSUInteger minimumNumberOfSelection;
@property (nonatomic, assign) NSUInteger maximumNumberOfSelection;

@property (nonatomic, copy) NSString *prompt;
@property (nonatomic, assign) BOOL showsNumberOfSelectedAssets;

@property (nonatomic, assign) NSUInteger numberOfColumnsInPortrait;
@property (nonatomic, assign) NSUInteger numberOfColumnsInLandscape;

@end
