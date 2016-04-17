//
//  LDOAlbumsTableController.m
//  LDOImagePicker
//
//  Created by Sebastian Ludwig on 10.04.16.
//  Copyright (c) 2016 Sebastian Ludwig. All rights reserved.
//

#import "LDOAlbumsTableController.h"
#import "LDOImagePickerBundle.h"
#import "LDOAlbumCell.h"


@interface LDOAlbumsTableController () <LDOAlbumsControllerDelegate>

@end


@implementation LDOAlbumsTableController

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
        _collectionsController = [[LDOAlbumsController alloc] initWithAssetCollectionSubtypes:assetCollectionSubtypes mediaType:LDOImagePickerMediaTypeAny];
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
    
    UINib *nib = [UINib nibWithNibName:@"LDOAlbumCell" bundle:[LDOImagePickerBundle ldoImagePickerBundle]];
    [self.tableView registerNib:nib forCellReuseIdentifier:@"LDOAlbumCell"];
}

- (void)setTableView:(UITableView *)tableView
{
    _tableView = tableView;
    
    [self setupTableView];
}

- (LDOImagePickerMediaType)mediaType
{
    return _collectionsController.mediaType;
}

// TODO: check if this method is called when awaking from a NIB
- (void)setMediaType:(LDOImagePickerMediaType)mediaType
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
    LDOAlbumCell *cell = [tableView dequeueReusableCellWithIdentifier:@"LDOAlbumCell" forIndexPath:indexPath];
    
    LDOAssetCollection *assetCollection = self.collectionsController.assetCollections[indexPath.row];
    [cell prepareForAssetCollection:assetCollection atIndexPath:indexPath];
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    LDOAssetCollection *assetCollection = self.collectionsController.assetCollections[self.tableView.indexPathForSelectedRow.row];
    [self.delegate albumsTableController:self didSelectAssetCollection:assetCollection];
}

#pragma mark - LDOAssetsCollectionControllerDelegate

- (void)assetCollectionsDidChange
{
    // TODO: preserve selection
    [self.tableView reloadData];
}

- (void)assetCollectionDidChange:(LDOAssetCollection *)collection
{
    NSUInteger index = [self.collectionsController.assetCollections indexOfObject:collection];
    if (index == NSNotFound) {
        NSLog(@"this should never happen oO");
    }
    
    [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:index inSection:0]] withRowAnimation:UITableViewRowAnimationNone];
}

@end
