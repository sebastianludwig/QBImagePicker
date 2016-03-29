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

@interface QBAlbumCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UIImageView *imageView1;       // TODO: use outlet collection
@property (weak, nonatomic) IBOutlet UIImageView *imageView2;
@property (weak, nonatomic) IBOutlet UIImageView *imageView3;
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UILabel *countLabel;

@property (nonatomic, assign) CGFloat imageViewBorderWidth;     // TODO: make inspectable
@property (nonatomic, assign) UIColor *imageViewBorderColor;

- (void)prepareForAssetCollection:(PHAssetCollection *)assetCollection mediaType:(QBImagePickerMediaType)mediaType atIndexPath:(NSIndexPath *)indexPath;

@end
