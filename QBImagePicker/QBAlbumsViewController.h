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


@interface QBAssetCollection : NSObject

@property (nonatomic, readonly) PHAssetCollection *collection;
@property (nonatomic, strong, readonly) NSString *localizedTitle;
@property (nonatomic, readonly) NSUInteger count;
@property (nonatomic, readonly) BOOL hasCount;
@property (nonatomic, readonly) PHFetchResult *assetFetchResult;

- (instancetype)initWithAssetCollection:(PHAssetCollection *)collection;

@end



@protocol QBAssetCollectionsControllerDelegate <NSObject>

- (void)qb_assetCollectionsDidChange;

@optional
- (void)qb_assetCollectionDidChange:(QBAssetCollection *)collection;

@end

@interface QBAssetCollectionsController : NSObject

@property (nonatomic, weak) id<QBAssetCollectionsControllerDelegate> delegate;

@property (nonatomic) QBImagePickerMediaType mediaType;
@property (nonatomic, copy) NSArray *enabledAssetCollectionSubtypes;
@property (nonatomic, copy, readonly) NSArray<QBAssetCollection *> *assetCollections;
@property (nonatomic, copy, readonly) NSDictionary<NSNumber *, NSArray<QBAssetCollection *> *> *assetCollectionsByType;

- (instancetype)initWithAssetCollectionSubtypes:(NSArray *)assetCollectionSubtypes mediaType:(QBImagePickerMediaType)mediaType;

@end





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
