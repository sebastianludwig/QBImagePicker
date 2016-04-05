//
//  QBAlbumsViewController.m
//  QBImagePicker
//
//  Created by Katsuma Tanaka on 2015/04/03.
//  Copyright (c) 2015 Katsuma Tanaka. All rights reserved.
//

#import "QBAlbumsViewController.h"

// Views
#import "QBAlbumCell.h"

// ViewControllers
#import "QBAssetsViewController.h"


@interface QBAssetCollectionsController () <PHPhotoLibraryChangeObserver>

@property (nonatomic, copy) NSArray *fetchResults;

@end

@implementation QBAssetCollectionsController

- (instancetype)initWithAssetCollectionSubtypes:(NSArray *)assetCollectionSubtypes
{
    if (self = [super init]) {
        self.enabledAssetCollectionSubtypes = assetCollectionSubtypes;
        
        // TODO: ensure this does not block
        // Fetch user albums and smart albums
        PHFetchResult *smartAlbums = [PHAssetCollection fetchAssetCollectionsWithType:PHAssetCollectionTypeSmartAlbum subtype:PHAssetCollectionSubtypeAny options:nil];
        PHFetchResult *userAlbums = [PHAssetCollection fetchAssetCollectionsWithType:PHAssetCollectionTypeAlbum subtype:PHAssetCollectionSubtypeAny options:nil];
        self.fetchResults = @[smartAlbums, userAlbums];
        
        // SEB: maybe use
        // PHFetchResult *topLevelUserCollections = [PHCollectionList fetchTopLevelUserCollectionsWithOptions:nil];
        // PHFetchResult *smartAlbums = [PHAssetCollection fetchAssetCollectionsWithType:PHAssetCollectionTypeSmartAlbum subtype:PHAssetCollectionSubtypeAlbumRegular options:nil];
        // see GMPhotoPicker
        
        [self updateAssetCollections];
        
        // Register observer
        [[PHPhotoLibrary sharedPhotoLibrary] registerChangeObserver:self];
    }
    return self;
}

- (void)dealloc
{
    [[PHPhotoLibrary sharedPhotoLibrary] unregisterChangeObserver:self];
}

- (void)setEnabledAssetCollectionSubtypes:(NSArray *)enabledAssetCollectionSubtypes
{
    _enabledAssetCollectionSubtypes = enabledAssetCollectionSubtypes;
    
    [self updateAssetCollections];
}

#pragma mark private

- (void)updateAssetCollections
{
    // Filter albums
    NSMutableDictionary *smartAlbums = [NSMutableDictionary dictionaryWithCapacity:self.enabledAssetCollectionSubtypes.count];
    NSMutableArray *userAlbums = [NSMutableArray array];
    
    for (PHFetchResult *fetchResult in self.fetchResults) {
        [fetchResult enumerateObjectsUsingBlock:^(PHAssetCollection *assetCollection, NSUInteger index, BOOL *stop) {
            PHAssetCollectionSubtype subtype = assetCollection.assetCollectionSubtype;
            
            if (subtype == PHAssetCollectionSubtypeAlbumRegular) {
                [userAlbums addObject:assetCollection];
            } else if ([self.enabledAssetCollectionSubtypes containsObject:@(subtype)]) {
                if (!smartAlbums[@(subtype)]) {
                    smartAlbums[@(subtype)] = [NSMutableArray array];
                }
                [smartAlbums[@(subtype)] addObject:assetCollection];
            }
        }];
    }
    
    NSMutableArray *assetCollections = [NSMutableArray array];
    
    // Fetch smart albums
    for (NSNumber *assetCollectionSubtype in self.enabledAssetCollectionSubtypes) {
        NSArray *collections = smartAlbums[assetCollectionSubtype];
        
        if (collections) {
            [assetCollections addObjectsFromArray:collections];
        }
    }
    
    // Fetch user albums
    [userAlbums enumerateObjectsUsingBlock:^(PHAssetCollection *assetCollection, NSUInteger index, BOOL *stop) {
        [assetCollections addObject:assetCollection];
    }];
    
    self.assetCollections = assetCollections;
    [self.delegate qb_assetCollectionsDidChange];
}

#pragma mark - PHPhotoLibraryChangeObserver

- (void)photoLibraryDidChange:(PHChange *)changeInstance
{
    dispatch_async(dispatch_get_main_queue(), ^{
        // Update fetch results
        NSMutableArray *fetchResults = [self.fetchResults mutableCopy];
        
        [self.fetchResults enumerateObjectsUsingBlock:^(PHFetchResult *fetchResult, NSUInteger index, BOOL *stop) {
            PHFetchResultChangeDetails *changeDetails = [changeInstance changeDetailsForFetchResult:fetchResult];
            
            if (changeDetails) {
                [fetchResults replaceObjectAtIndex:index withObject:changeDetails.fetchResultAfterChanges];
            }
        }];
        
        if (![self.fetchResults isEqualToArray:fetchResults]) {
            self.fetchResults = fetchResults;
            
            // Reload albums
            [self updateAssetCollections];
        }
    });
}

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
    _assetBundle = [NSBundle bundleForClass:[self class]];
    NSString *bundlePath = [_assetBundle pathForResource:@"QBImagePicker" ofType:@"bundle"];
    if (bundlePath) {
        _assetBundle = [NSBundle bundleWithPath:bundlePath];
    }
    _assetSelection = [QBAssetSelection new];
    _mediaType = QBImagePickerMediaTypeAny;
    
    NSArray *assetCollectionSubtypes = @[
                                         @(PHAssetCollectionSubtypeSmartAlbumUserLibrary),
                                         @(PHAssetCollectionSubtypeAlbumMyPhotoStream),
                                         @(PHAssetCollectionSubtypeSmartAlbumPanoramas),
                                         @(PHAssetCollectionSubtypeSmartAlbumVideos),
                                         @(PHAssetCollectionSubtypeSmartAlbumBursts)
                                         ];
    _collectionsController = [[QBAssetCollectionsController alloc] initWithAssetCollectionSubtypes:assetCollectionSubtypes];
    _collectionsController.delegate = self;
    
    [self setUpToolbarItems];
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

- (void)setMediaType:(QBImagePickerMediaType)mediaType
{
    _mediaType = mediaType;
    if (self.isViewLoaded) {
        [self.tableView reloadData];
    }
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
    
    PHAssetCollection *assetCollection = self.collectionsController.assetCollections[indexPath.row];
    [cell prepareForAssetCollection:assetCollection mediaType:self.mediaType atIndexPath:indexPath];
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    PHAssetCollection *assetCollection = self.collectionsController.assetCollections[self.tableView.indexPathForSelectedRow.row];
    [self.delegate qb_albumsViewController:self didSelectAssetCollection:assetCollection];
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


@end
