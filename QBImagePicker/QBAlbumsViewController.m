//
//  QBAlbumsViewController.m
//  QBImagePicker
//
//  Created by Katsuma Tanaka on 2015/04/03.
//  Copyright (c) 2015 Katsuma Tanaka. All rights reserved.
//

#import "QBAlbumsViewController.h"
#import "QBBundle.h"
#import "QBAssetsViewController.h"
#import "QBAlbumCell.h"


@interface QBAlbumsTableView : UITableView

@end



@implementation QBAlbumsTableView



@end





@interface QBAlbumsViewController () <QBAssetCollectionsControllerDelegate>

@property (nonatomic, strong) NSBundle *assetBundle;

@property (nonatomic, strong) IBOutlet UIBarButtonItem *doneButton;
@property (nonatomic, strong) UIBarButtonItem *infoToolbarItem;

@end

@implementation QBAlbumsViewController

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    if (self = [super initWithCoder:aDecoder]) {
        [self setup];
    }
    return self;
}

- (instancetype)init
{
    if (self = [super initWithStyle:UITableViewStylePlain]) {
        [self setup];
        
        self.doneButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(done)];
        self.navigationItem.rightBarButtonItem = self.doneButton;
        self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancel)];
    }
    return self;
}

- (void)setup
{
    _assetSelection = [QBAssetSelection new];
    
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
    
    [self setUpToolbarItems];
    _assetBundle = [QBBundle imagePickerBundle];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.tableView.rowHeight = 86;
    
    UINib *nib = [UINib nibWithNibName:@"QBAlbumCell" bundle:self.assetBundle];
    [self.tableView registerNib:nib forCellReuseIdentifier:@"QBAlbumCell"];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    // Show/hide 'Done' button
    self.doneButton.enabled = [self.assetSelection isMinimumSelectionLimitFulfilled];
    self.navigationItem.rightBarButtonItem = self.assetSelection.allowsMultipleSelection ? self.doneButton : nil;
    
    [self updateSelectionInfo];
}

- (QBImagePickerMediaType)mediaType
{
    return self.collectionsController.mediaType;
}

- (void)setMediaType:(QBImagePickerMediaType)mediaType
{
    self.collectionsController.mediaType = mediaType;
}


#pragma mark - Actions

- (IBAction)cancel
{
    [self.delegate qb_albumsViewControllerDidCancel:self];
}

- (IBAction)done
{
    [self.delegate qb_albumsViewControllerDidFinish:self];
}


#pragma mark - Toolbar

- (void)setUpToolbarItems
{
    // Space
    UIBarButtonItem *leftSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:NULL];
    UIBarButtonItem *rightSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:NULL];
    
    // Info label
    self.infoToolbarItem = [[UIBarButtonItem alloc] initWithTitle:@"" style:UIBarButtonItemStylePlain target:nil action:NULL];
    self.infoToolbarItem.enabled = NO;
    NSDictionary *attributes = @{ NSForegroundColorAttributeName: [UIColor blackColor] };
    [self.infoToolbarItem setTitleTextAttributes:attributes forState:UIControlStateNormal];
    [self.infoToolbarItem setTitleTextAttributes:attributes forState:UIControlStateDisabled];
    
    self.toolbarItems = @[leftSpace, self.infoToolbarItem, rightSpace];
}

- (void)updateSelectionInfo
{
    NSUInteger count = self.assetSelection.count;
    
    if (count > 0) {
        NSString *identifier = count == 1 ? @"assets.toolbar.item-selected" : @"assets.toolbar.items-selected";
        NSString *format = NSLocalizedStringFromTableInBundle(identifier, @"QBImagePicker", self.assetBundle, nil);
        NSString *title = [NSString stringWithFormat:format, count];
        [self.infoToolbarItem setTitle:title];
    } else {
        [self.infoToolbarItem setTitle:@""];
    }
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
    [self.delegate qb_albumsViewController:self didSelectAssetCollection:assetCollection.collection];
}

#pragma mark - QBAssetCollectionsControllerDelegate

- (void)qb_assetCollectionsDidChange
{
    if (!self.isViewLoaded) {
        return;
    }
    
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
