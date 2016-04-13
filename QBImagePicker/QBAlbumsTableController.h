//
//  QBAlbumsTableController.h
//  QBImagePicker
//
//  Created by Sebastian Ludwig on 10.04.16.
//  Copyright © 2016 Katsuma Tanaka. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "QBAssetCollection.h"
#import "QBAssetCollectionsController.h"
#import "QBImagePickerTypes.h"

@class QBAlbumsTableController;

@protocol QBAlbumsTableControllerDelegate <NSObject>

- (void)qb_albumsTableController:(QBAlbumsTableController *)controller didSelectAssetCollection:(QBAssetCollection *)assetCollection;

@end


@interface QBAlbumsTableController : NSObject <UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, weak) IBOutlet UITableView *tableView;
@property (nonatomic, weak) IBOutlet id<QBAlbumsTableControllerDelegate> delegate;
@property (nonatomic, strong) IBOutlet QBAssetCollectionsController* collectionsController;

@property (nonatomic) IBInspectable QBImagePickerMediaType mediaType;

@end
