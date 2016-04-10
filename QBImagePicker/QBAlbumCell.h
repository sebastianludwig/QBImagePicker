//
//  QBAlbumCell.h
//  QBImagePicker
//
//  Created by Katsuma Tanaka on 2015/04/03.
//  Copyright (c) 2015 Katsuma Tanaka. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Photos/Photos.h>
#import "QBImagePickerTypes.h"
#import "QBAlbumsViewController.h"  // TODO: change this

@interface QBAlbumCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UIImageView *frontImageView;
@property (weak, nonatomic) IBOutlet UIImageView *middleImageView;
@property (weak, nonatomic) IBOutlet UIImageView *backImageView;
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UILabel *countLabel;

@property (nonatomic, assign) CGFloat imageViewBorderWidth;     // TODO: make inspectable
@property (nonatomic, assign) UIColor *imageViewBorderColor;

- (void)prepareForAssetCollection:(QBAssetCollection *)assetCollection atIndexPath:(NSIndexPath *)indexPath;

@end
