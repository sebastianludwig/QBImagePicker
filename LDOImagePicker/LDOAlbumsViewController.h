//
//  LDOAlbumsViewController.h
//  LDOImagePicker
//
//  Created by Sebastian Ludwig on 17.04.2016.
//  Copyright (c) 2016 Sebastian Ludwig. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "LDOAssetSelection.h"
#import "LDOAssetCollection.h"
#import "LDOAlbumsTableController.h"


@class LDOAlbumsViewController;

@protocol LDOAlbumsViewControllerDelegate <NSObject>

- (void)albumsViewController:(LDOAlbumsViewController *)albumsViewController didSelectAssetCollection:(LDOAssetCollection *)assetCollection;
- (void)albumsViewControllerDidFinish:(LDOAlbumsViewController *)albumsViewController;
- (void)albumsViewControllerDidCancel:(LDOAlbumsViewController *)albumsViewController;

@end

@interface LDOAlbumsViewController : UIViewController

@property (nonatomic, weak) id<LDOAlbumsViewControllerDelegate> delegate;

@property (nonatomic, strong) LDOAssetSelection *assetSelection; // TODO: setter should update Done button state

@property (nonatomic, readonly) LDOAlbumsTableController *albumsController;

@end
