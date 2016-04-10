//
//  QBAlbumsTableView.m
//  QBImagePicker
//
//  Created by Sebastian Ludwig on 10.04.16.
//  Copyright © 2016 Katsuma Tanaka. All rights reserved.
//

#import "QBAlbumsTableView.h"
#import "QBBundle.h"
#import "QBAlbumCell.h"


@interface QBAlbumsTableView () <UITableViewDelegate, UITableViewDataSource, QBAssetCollectionsControllerDelegate>

@end


@implementation QBAlbumsTableView

- (instancetype)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    if (self) {
        [self setup];
    }
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame style:(UITableViewStyle)style
{
    self = [super initWithFrame:frame style:style];
    if (self) {
        [self setup];
    }
    return self;
}

- (void)setup
{
    self.rowHeight = 86;
    
    UINib *nib = [UINib nibWithNibName:@"QBAlbumCell" bundle:[QBBundle imagePickerBundle]];
    [self registerNib:nib forCellReuseIdentifier:@"QBAlbumCell"];
    
    self.delegate = self;
    self.dataSource = self;
    
    
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
    QBAssetCollection *assetCollection = self.collectionsController.assetCollections[self.indexPathForSelectedRow.row];
    [self.albumsTableViewDelegate qb_albumsTableView:self didSelectAssetCollection:assetCollection];
}

#pragma mark - QBAssetCollectionsControllerDelegate

- (void)qb_assetCollectionsDidChange
{
    // TODO: preserve selection
    [self reloadData];
}

- (void)qb_assetCollectionDidChange:(QBAssetCollection *)collection
{
    NSUInteger index = [self.collectionsController.assetCollections indexOfObject:collection];
    if (index == NSNotFound) {
        NSLog(@"this should never happen oO");
    }
    
    [self reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:index inSection:0]] withRowAnimation:UITableViewRowAnimationNone];
}

@end
