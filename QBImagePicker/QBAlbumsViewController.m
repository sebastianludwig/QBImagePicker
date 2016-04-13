//
//  QBAlbumsViewController.m
//  QBImagePicker
//
//  Created by Katsuma Tanaka on 2015/04/03.
//  Copyright (c) 2015 Katsuma Tanaka. All rights reserved.
//

#import "QBAlbumsViewController.h"
#import "QBBundle.h"


@interface QBAlbumsViewController () <QBAlbumsTableControllerDelegate>

@property (nonatomic, strong) NSBundle *assetBundle;

@property (nonatomic, strong) IBOutlet UIBarButtonItem *doneButton;
@property (nonatomic, strong) UIBarButtonItem *infoToolbarItem;

@end

@implementation QBAlbumsViewController
{
    QBAlbumsTableController *_albumsController;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    if (self = [super initWithCoder:aDecoder]) {
        [self setup];
    }
    return self;
}

- (instancetype)init
{
    if (self = [super init]) {
        [self setup];
        
        self.doneButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(done)];
        self.navigationItem.rightBarButtonItem = self.doneButton;
        self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancel)];
    }
    return self;
}

- (void)setup
{
    [self setUpToolbarItems];
    
    _assetBundle = [QBBundle imagePickerBundle];
    _assetSelection = [QBAssetSelection new];
    _albumsController = [QBAlbumsTableController new];
    _albumsController.delegate = self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    UITableView *tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStylePlain];
    
    [self.view addSubview:tableView];
    
    self.albumsController.tableView = tableView;
    tableView.dataSource = self.albumsController;
    tableView.delegate = self.albumsController;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    // Show/hide 'Done' button
    self.doneButton.enabled = [self.assetSelection isMinimumSelectionLimitFulfilled];
    self.navigationItem.rightBarButtonItem = self.assetSelection.allowsMultipleSelection ? self.doneButton : nil;
    
    [self.albumsController.tableView deselectRowAtIndexPath:self.albumsController.tableView.indexPathForSelectedRow animated:YES];
    
    [self updateSelectionInfo];
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

#pragma mark - QBAlbumsTableViewDelegate

- (void)qb_albumsTableController:(QBAlbumsTableController *)controller didSelectAssetCollection:(QBAssetCollection *)assetCollection
{
    [self.delegate qb_albumsViewController:self didSelectAssetCollection:assetCollection];
}

@end
