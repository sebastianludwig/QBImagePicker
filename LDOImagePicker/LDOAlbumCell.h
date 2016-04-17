//
//  LDOAlbumCell.h
//  LDOImagePicker
//
//  Created by Sebastian Ludwig on 17.04.2016.
//  Copyright (c) 2016 Sebastian Ludwig. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Photos/Photos.h>
#import "LDOImagePickerTypes.h"
#import "LDOAlbumsViewController.h"  // TODO: change this

@interface LDOAlbumCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UIImageView *frontImageView;
@property (weak, nonatomic) IBOutlet UIImageView *middleImageView;
@property (weak, nonatomic) IBOutlet UIImageView *backImageView;
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UILabel *countLabel;

@property (nonatomic, assign) CGFloat imageViewBorderWidth;     // TODO: make inspectable
@property (nonatomic, assign) UIColor *imageViewBorderColor;

- (void)prepareForAssetCollection:(LDOAssetCollection *)assetCollection atIndexPath:(NSIndexPath *)indexPath;

@end
