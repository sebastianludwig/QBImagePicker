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

@class QBImagePickerController;

@interface QBAssetsViewController : UICollectionViewController

@property (nonatomic, weak) QBImagePickerController *imagePickerController;
@property (nonatomic, strong) PHAssetCollection *assetCollection;

@property (nonatomic, assign) BOOL showsNumberOfSelectedAssets;

@property (nonatomic, assign) NSUInteger numberOfColumnsInPortrait; // TODO: rather use size classes here
@property (nonatomic, assign) NSUInteger numberOfColumnsInLandscape;

@property (nonatomic, assign) BOOL allowsMultipleSelection;
@property (nonatomic, assign) QBImagePickerMediaType mediaType;     // TODO: try to get rid of this - maybe by passing the fetch options from the AlbumsViewController. Otherwise a setter is needed (that triggers whatever updates are necessary - closely related to assetsCollection property)
@property (nonatomic, assign) NSUInteger minimumNumberOfSelection;
@property (nonatomic, assign) NSUInteger maximumNumberOfSelection;

@end
