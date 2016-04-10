//
//  QBAlbumsTableView.h
//  QBImagePicker
//
//  Created by Sebastian Ludwig on 10.04.16.
//  Copyright © 2016 Katsuma Tanaka. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "QBAssetCollection.h"
#import "QBAssetCollectionsController.h"
#import "QBImagePickerTypes.h"

@class QBAlbumsTableView;

@protocol QBAlbumsTableViewDelegate <NSObject>

- (void)qb_albumsTableView:(QBAlbumsTableView *)tableView didSelectAssetCollection:(QBAssetCollection *)assetCollection;

@end


@interface QBAlbumsTableView : UITableView

@property (nonatomic, weak) IBOutlet id<QBAlbumsTableViewDelegate> albumsTableViewDelegate;
@property (nonatomic, strong) IBOutlet QBAssetCollectionsController* collectionsController;

@property (nonatomic) IBInspectable QBImagePickerMediaType mediaType;

@end
