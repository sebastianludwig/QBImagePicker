//
//  QBAlbumsTableController.m
//  QBImagePicker
//
//  Created by Sebastian Ludwig on 10.04.16.
//  Copyright © 2016 Katsuma Tanaka. All rights reserved.
//

#import "QBAlbumsTableController.h"
#import "QBBundle.h"
#import "QBAlbumCell.h"


@interface QBAlbumsTableController () <QBAssetCollectionsControllerDelegate>

@end


@implementation QBAlbumsTableController

- (instancetype)init
{
    if (self = [super init]) {
        NSArray *assetCollectionSubtypes = @[
                                             @(PHAssetCollectionSubtypeSmartAlbumUserLibrary),
                                             @(PHAssetCollectionSubtypeAlbumMyPhotoStream),
                                             @(PHAssetCollectionSubtypeSmartAlbumPanoramas),
                                             @(PHAssetCollectionSubtypeSmartAlbumVideos),
                                             @(PHAssetCollectionSubtypeSmartAlbumBursts),
                                             @(PHAssetCollectionSubtypeAlbumRegular)
                                             ];
        _collectionsController = [[QBAssetCollectionsController alloc] initWithAssetCollectionSubtypes:assetCollectionSubtypes mediaType:QBImagePickerMediaTypeAny];
        _collectionsController.delegate = self;
    }
    return self;
}

- (void)awakeFromNib
{
    [super awakeFromNib];
    
    [self setupTableView];
}

- (void)setupTableView
{
    self.tableView.rowHeight = 86;
    
    UINib *nib = [UINib nibWithNibName:@"QBAlbumCell" bundle:[QBBundle imagePickerBundle]];
    [self.tableView registerNib:nib forCellReuseIdentifier:@"QBAlbumCell"];
}

- (void)setTableView:(UITableView *)tableView
{
    _tableView = tableView;
    
    [self setupTableView];
}

- (QBImagePickerMediaType)mediaType
{
    return _collectionsController.mediaType;
}

// TODO: check if this method is called when awaking from a NIB
- (void)setMediaType:(QBImagePickerMediaType)mediaType
{
    _collectionsController.mediaType = mediaType;
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.collectionsController.assetCollections.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    QBAlbumCell *cell = [tableView dequeueReusableCellWithIdentifier:@"QBAlbumCell" forIndexPath:indexPath];
    
    QBAssetCollection *assetCollection = self.collectionsController.assetCollections[indexPath.row];
    [cell prepareForAssetCollection:assetCollection atIndexPath:indexPath];
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    QBAssetCollection *assetCollection = self.collectionsController.assetCollections[self.tableView.indexPathForSelectedRow.row];
    [self.delegate qb_albumsTableController:self didSelectAssetCollection:assetCollection];
}

#pragma mark - QBAssetCollectionsControllerDelegate

- (void)qb_assetCollectionsDidChange
{
    // TODO: preserve selection
    [self.tableView reloadData];
}

- (void)qb_assetCollectionDidChange:(QBAssetCollection *)collection
{
    NSUInteger index = [self.collectionsController.assetCollections indexOfObject:collection];
    if (index == NSNotFound) {
        NSLog(@"this should never happen oO");
    }
    
    [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:index inSection:0]] withRowAnimation:UITableViewRowAnimationNone];
}

@end
