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
#import "QBImagePickerController.h"
#import "QBAssetsViewController.h"


@protocol QBAssetCollectionsControllerDelegate <NSObject>

- (void)qb_assetCollectionsDidChange;

@end

@interface QBAssetCollectionsController : NSObject

@property (nonatomic, weak) id<QBAssetCollectionsControllerDelegate> delegate;

@property (nonatomic, copy) NSArray *enabledAssetCollectionSubtypes;    // TODO: setter should trigger updateAssetCollections
@property (nonatomic, copy) NSArray *assetCollections;

@end

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

#pragma mark private

- (void)updateAssetCollections
{
    // TODO: previously this used self.imagePickerController.assetCollectionSubtypes - now changes to the imagePickerController subtypes won't be honored anymore
    
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
            [self.delegate qb_assetCollectionsDidChange];
        }
    });
}

@end




@interface QBAlbumsViewController () <QBAssetCollectionsControllerDelegate>

@property (nonatomic, strong) NSBundle *assetBundle;

@property (nonatomic, strong) IBOutlet UIBarButtonItem *doneButton;
@property (nonatomic, strong) UIBarButtonItem *infoToolbarItem;
@property (nonatomic, strong) QBAssetCollectionsController* collectionsController;

@end

@implementation QBAlbumsViewController

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        self.assetBundle = [NSBundle bundleForClass:[self class]];
        NSString *bundlePath = [self.assetBundle pathForResource:@"QBImagePicker" ofType:@"bundle"];
        if (bundlePath) {
            self.assetBundle = [NSBundle bundleWithPath:bundlePath];
        }
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self setUpToolbarItems];
    
    self.collectionsController = [[QBAssetCollectionsController alloc] initWithAssetCollectionSubtypes:self.imagePickerController.assetCollectionSubtypes];
    self.collectionsController.delegate = self;
    
    UINib *nib = [UINib nibWithNibName:@"QBAlbumCell" bundle:self.assetBundle];
    [self.tableView registerNib:nib forCellReuseIdentifier:@"QBAlbumCell"];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    // Show/hide 'Done' button
    if (self.imagePickerController.allowsMultipleSelection) {
        BOOL isMinimumSelectionLimitFulfilled = self.imagePickerController.minimumNumberOfSelection <= self.imagePickerController.selectedAssets.count;
        self.doneButton.enabled = isMinimumSelectionLimitFulfilled;
        [self.navigationItem setRightBarButtonItem:self.doneButton animated:NO];
    } else {
        [self.navigationItem setRightBarButtonItem:nil animated:NO];
    }
    
    [self updateSelectionInfo];
}


#pragma mark - Actions

- (IBAction)cancel:(id)sender
{
    if ([self.imagePickerController.delegate respondsToSelector:@selector(qb_imagePickerControllerDidCancel:)]) {
        [self.imagePickerController.delegate qb_imagePickerControllerDidCancel:self.imagePickerController];
    }
}

- (IBAction)done:(id)sender
{
    if ([self.imagePickerController.delegate respondsToSelector:@selector(qb_imagePickerController:didFinishPickingAssets:)]) {
        [self.imagePickerController.delegate qb_imagePickerController:self.imagePickerController
                                               didFinishPickingAssets:self.imagePickerController.selectedAssets.array];
    }
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
    NSUInteger count = self.imagePickerController.selectedAssets.count;
    
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
    [cell prepareForAssetCollection:assetCollection mediaType:self.imagePickerController.mediaType atIndexPath:indexPath];
    
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
    // TODO: preserve selection
    [self.tableView reloadData];
}


@end
