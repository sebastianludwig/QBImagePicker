//
//  QBAlbumsViewController.h
//  QBImagePicker
//
//  Created by Katsuma Tanaka on 2015/04/03.
//  Copyright (c) 2015 Katsuma Tanaka. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Photos/Photos.h>

@class QBAlbumsViewController;

@protocol QBAlbumsViewControllerDelegate <NSObject>

- (void)qb_albumsViewController:(QBAlbumsViewController *)albumsViewController didSelectAssetCollection:(PHAssetCollection *)assetCollection;

@end

@class QBImagePickerController;

@interface QBAlbumsViewController : UITableViewController

@property (nonatomic, weak) id<QBAlbumsViewControllerDelegate> delegate;
@property (nonatomic, weak) QBImagePickerController *imagePickerController;

@end
