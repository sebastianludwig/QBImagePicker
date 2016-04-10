//
//  QBAlbumsViewController.h
//  QBImagePicker
//
//  Created by Katsuma Tanaka on 2015/04/03.
//  Copyright (c) 2015 Katsuma Tanaka. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Photos/Photos.h>
#import "QBAssetSelection.h"
#import "QBImagePickerTypes.h"
#import "QBAssetCollection.h"
#import "QBAssetCollectionsController.h"



@class QBAlbumsViewController;

@protocol QBAlbumsViewControllerDelegate <NSObject>

- (void)qb_albumsViewController:(QBAlbumsViewController *)albumsViewController didSelectAssetCollection:(PHAssetCollection *)assetCollection;
- (void)qb_albumsViewControllerDidFinish:(QBAlbumsViewController *)albumsViewController;
- (void)qb_albumsViewControllerDidCancel:(QBAlbumsViewController *)albumsViewController;

@end

@interface QBAlbumsViewController : UITableViewController

@property (nonatomic, weak) id<QBAlbumsViewControllerDelegate> delegate;
@property (nonatomic, strong) QBAssetCollectionsController* collectionsController;
@property (nonatomic, strong) QBAssetSelection *assetSelection; // TODO: setter should update Done button state

@property (nonatomic) QBImagePickerMediaType mediaType;

@end
