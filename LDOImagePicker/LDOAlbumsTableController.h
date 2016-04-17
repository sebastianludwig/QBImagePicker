//
//  LDOAlbumsTableController.h
//  LDOImagePicker
//
//  Created by Sebastian Ludwig on 10.04.16.
//  Copyright (c) 2016 Sebastian Ludwig. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "LDOAssetCollection.h"
#import "LDOAlbumsController.h"
#import "LDOImagePickerTypes.h"

@class LDOAlbumsTableController;

@protocol LDOAlbumsTableControllerDelegate <NSObject>

- (void)albumsTableController:(LDOAlbumsTableController *)controller didSelectAssetCollection:(LDOAssetCollection *)assetCollection;

@end


@interface LDOAlbumsTableController : NSObject <UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, weak) IBOutlet UITableView *tableView;
@property (nonatomic, weak) IBOutlet id<LDOAlbumsTableControllerDelegate> delegate;
@property (nonatomic, strong) IBOutlet LDOAlbumsController* collectionsController;

@property (nonatomic) IBInspectable LDOImagePickerMediaType mediaType;

@end
