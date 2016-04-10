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

@implementation QBAssetCollection

- (instancetype)initWithAssetCollection:(PHAssetCollection *)collection
{
    if (self = [super init]) {
        _collection = collection;
    }
    return self;
}

- (NSString *)localizedTitle
{
    return self.collection.localizedTitle;
}

- (BOOL)hasCount
{
    return self.assetFetchResult || self.collection.estimatedAssetCount != NSNotFound;    // not sure if NSNotFound is appropriate here - it's the same value, but not documented
}

- (NSUInteger)count
{
    if (!self.hasCount) {
        return 0;
    }
    return self.assetFetchResult ? self.assetFetchResult.count : self.collection.estimatedAssetCount;
}

- (void)setAssetFetchResult:(PHFetchResult *)assetFetchResult
{
    _assetFetchResult = assetFetchResult;
}

@end


@interface QBAssetCollection (Private)

@property (nonatomic) PHFetchResult *assetFetchResult;

@end


@interface QBFetchCollectionAssetsOperation : NSOperation

@property (nonatomic, readonly) PHAssetCollection *assetCollection;
@property (nonatomic, readonly) QBImagePickerMediaType mediaType;
@property (nonatomic, readonly) PHFetchResult *fetchResult;

- (instancetype)initWithCollection:(PHAssetCollection *)collection mediaType:(QBImagePickerMediaType)mediaType completionBlock:(void (^)(QBFetchCollectionAssetsOperation *operation))completionBlock;

@end

@implementation QBFetchCollectionAssetsOperation
{
    void (^_completionBlock)(QBFetchCollectionAssetsOperation *operation);
}

- (instancetype)initWithCollection:(PHAssetCollection *)collection mediaType:(QBImagePickerMediaType)mediaType completionBlock:(void (^)(QBFetchCollectionAssetsOperation *operation))completionBlock
{
    if (self = [super init]) {
        _assetCollection = collection;
        _mediaType = mediaType;
        _completionBlock = completionBlock;
    }
    return self;
}

- (void)main
{
    if (self.isCancelled) {
        return;
    }
    
    PHFetchOptions *options = [PHFetchOptions new];
    if (self.mediaType == QBImagePickerMediaTypeImage) {
        options.predicate = [NSPredicate predicateWithFormat:@"mediaType == %ld", PHAssetMediaTypeImage];
    } else if (self.mediaType == QBImagePickerMediaTypeVideo) {
        options.predicate = [NSPredicate predicateWithFormat:@"mediaType == %ld", PHAssetMediaTypeVideo];
    }
    
    _fetchResult = [PHAsset fetchAssetsInAssetCollection:self.assetCollection options:options];
 
    dispatch_async(dispatch_get_main_queue(), ^(void) {
        _completionBlock(self); // no need for weak reference, since this does not introduce a retain cycle
    });
}

@end



@interface QBAssetCollectionsController () <PHPhotoLibraryChangeObserver>

@property (nonatomic, copy) NSArray *fetchAssetCollectionsResults;
@property (nonatomic) NSOperationQueue *operationQueue;
@property (nonatomic) BOOL updateAssetCollectionsInProgress;

@end

@implementation QBAssetCollectionsController
{
    BOOL _updateAssetCollectionsInProgress;
}

- (instancetype)initWithAssetCollectionSubtypes:(NSArray *)assetCollectionSubtypes mediaType:(QBImagePickerMediaType)mediaType
{
    if (self = [super init]) {
        _operationQueue = [[NSOperationQueue alloc] init];
        _operationQueue.qualityOfService = NSOperationQualityOfServiceUserInitiated;
        _enabledAssetCollectionSubtypes = assetCollectionSubtypes;
        _mediaType = mediaType;
        
        // TODO: ensure this does not block
        // Fetch user albums and smart albums
        PHFetchResult *smartAlbums = [PHAssetCollection fetchAssetCollectionsWithType:PHAssetCollectionTypeSmartAlbum subtype:PHAssetCollectionSubtypeAny options:nil];
        PHFetchResult *userAlbums = [PHAssetCollection fetchAssetCollectionsWithType:PHAssetCollectionTypeAlbum subtype:PHAssetCollectionSubtypeAny options:nil];
        _fetchAssetCollectionsResults = @[smartAlbums, userAlbums];
        
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

- (void)setMediaType:(QBImagePickerMediaType)mediaType
{
    _mediaType = mediaType;
    
    [self updateAssetCollections];
}

#pragma mark private

- (BOOL)updateAssetCollectionsInProgress {
    return _updateAssetCollectionsInProgress;
}

- (void)updateAssetsCollectionsStarted
{
    _updateAssetCollectionsInProgress = YES;
}

- (void)updateAssetsCollectionsFinished
{
    _updateAssetCollectionsInProgress = NO;
}

- (void)updateAssetCollections
{
    NSAssert([NSThread isMainThread], @"must be called on the main thread");
    [self updateAssetsCollectionsStarted];
    [self.operationQueue cancelAllOperations];
    
    NSMutableDictionary *collectionsByType = [NSMutableDictionary dictionaryWithCapacity:self.enabledAssetCollectionSubtypes.count];
    
    for (PHFetchResult *fetchResult in self.fetchAssetCollectionsResults) {
        [fetchResult enumerateObjectsUsingBlock:^(PHAssetCollection *assetCollection, NSUInteger index, BOOL *stop) {
            PHAssetCollectionSubtype subtype = assetCollection.assetCollectionSubtype;
            
            if (![self.enabledAssetCollectionSubtypes containsObject:@(subtype)]) {
                return;
            }
            
            if (!collectionsByType[@(subtype)]) {
                collectionsByType[@(subtype)] = [NSMutableArray array];
            }
            QBAssetCollection *collection = [[QBAssetCollection alloc] initWithAssetCollection:assetCollection];
            [collectionsByType[@(subtype)] addObject:collection];
            
            
            __weak typeof(self)weakSelf = self;
            void (^completionBlock)(QBFetchCollectionAssetsOperation *) = ^void(QBFetchCollectionAssetsOperation *operation) {
                __strong typeof(self) strongSelf = weakSelf;
                
                if (operation.isCancelled || strongSelf.updateAssetCollectionsInProgress) {
                    return;
                }
                
                collection.assetFetchResult = operation.fetchResult;
                
                if ([strongSelf.delegate respondsToSelector:@selector(qb_assetCollectionDidChange:)]) {
                    [strongSelf.delegate qb_assetCollectionDidChange:collection];
                }
            };
            
            // TODO: suspend queue to stop operations when vc in background (assets vc pushed on top)
            [self.operationQueue addOperation:[[QBFetchCollectionAssetsOperation alloc] initWithCollection:assetCollection
                                                                                               mediaType:self.mediaType
                                                                                         completionBlock:completionBlock]];
        }];
    }
    
    NSMutableArray *assetCollections = [NSMutableArray array];
    for (NSNumber *subtype in self.enabledAssetCollectionSubtypes) {
        NSArray *collections = collectionsByType[subtype];
        
        if (collections) {
            [assetCollections addObjectsFromArray:collections];
        }
    }
    
    _assetCollections = assetCollections;
    _assetCollectionsByType = collectionsByType;
    [self.delegate qb_assetCollectionsDidChange];
    [self updateAssetsCollectionsFinished];
}

#pragma mark - PHPhotoLibraryChangeObserver

- (void)photoLibraryDidChange:(PHChange *)changeInstance
{
    dispatch_async(dispatch_get_main_queue(), ^{
        // Update fetch results
        NSMutableArray *fetchResults = [self.fetchAssetCollectionsResults mutableCopy];
        
        [self.fetchAssetCollectionsResults enumerateObjectsUsingBlock:^(PHFetchResult *fetchResult, NSUInteger index, BOOL *stop) {
            PHFetchResultChangeDetails *changeDetails = [changeInstance changeDetailsForFetchResult:fetchResult];
            
            if (changeDetails) {
                [fetchResults replaceObjectAtIndex:index withObject:changeDetails.fetchResultAfterChanges];
            }
        }];
        
        if (![self.fetchAssetCollectionsResults isEqualToArray:fetchResults]) {
            self.fetchAssetCollectionsResults = fetchResults;
            
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
