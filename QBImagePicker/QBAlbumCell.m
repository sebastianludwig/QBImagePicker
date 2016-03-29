//
//  QBAlbumCell.m
//  QBImagePicker
//
//  Created by Katsuma Tanaka on 2015/04/03.
//  Copyright (c) 2015 Katsuma Tanaka. All rights reserved.
//

#import "QBAlbumCell.h"

static CGSize CGSizeScreenScale(CGSize size) {
    CGFloat scale = [[UIScreen mainScreen] scale];
    return CGSizeMake(size.width * scale, size.height * scale);
}

@interface QBAlbumCell ()

@property (nonatomic, copy) NSIndexPath *indexPath;

@end

@implementation QBAlbumCell

+ (UIImage *)placeholderImageWithSize:(CGSize)size
{
    static CGSize cachedSize = {0.0, 0.0};
    static UIImage *cachedPlaceholderImage = nil;
    
    if (CGSizeEqualToSize(cachedSize, size)) {
        return cachedPlaceholderImage;
    }
    
    UIGraphicsBeginImageContext(size);
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    UIColor *backgroundColor = [UIColor colorWithRed:(239.0 / 255.0) green:(239.0 / 255.0) blue:(244.0 / 255.0) alpha:1.0];
    UIColor *iconColor = [UIColor colorWithRed:(179.0 / 255.0) green:(179.0 / 255.0) blue:(182.0 / 255.0) alpha:1.0];
    
    // Background
    CGContextSetFillColorWithColor(context, [backgroundColor CGColor]);
    CGContextFillRect(context, CGRectMake(0, 0, size.width, size.height));
    
    // Icon (back)
    CGRect backIconRect = CGRectMake(size.width * (16.0 / 68.0),
                                     size.height * (20.0 / 68.0),
                                     size.width * (32.0 / 68.0),
                                     size.height * (24.0 / 68.0));
    
    CGContextSetFillColorWithColor(context, [iconColor CGColor]);
    CGContextFillRect(context, backIconRect);
    
    CGContextSetFillColorWithColor(context, [backgroundColor CGColor]);
    CGContextFillRect(context, CGRectInset(backIconRect, 1.0, 1.0));
    
    // Icon (front)
    CGRect frontIconRect = CGRectMake(size.width * (20.0 / 68.0),
                                      size.height * (24.0 / 68.0),
                                      size.width * (32.0 / 68.0),
                                      size.height * (24.0 / 68.0));
    
    CGContextSetFillColorWithColor(context, [backgroundColor CGColor]);
    CGContextFillRect(context, CGRectInset(frontIconRect, -1.0, -1.0));
    
    CGContextSetFillColorWithColor(context, [iconColor CGColor]);
    CGContextFillRect(context, frontIconRect);
    
    CGContextSetFillColorWithColor(context, [backgroundColor CGColor]);
    CGContextFillRect(context, CGRectInset(frontIconRect, 1.0, 1.0));
    
    cachedPlaceholderImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    cachedSize = size;
    return cachedPlaceholderImage;
}

- (instancetype)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    if (self) {
        _imageViewBorderWidth = 1.0 / [[UIScreen mainScreen] scale];
        _imageViewBorderColor = [UIColor whiteColor];
    }
    return self;
}

- (void)awakeFromNib
{
    self.imageView1.layer.borderWidth = self.imageViewBorderWidth;
    self.imageView2.layer.borderWidth = self.imageViewBorderWidth;
    self.imageView3.layer.borderWidth = self.imageViewBorderWidth;
    
    self.imageView1.layer.borderColor = [self.imageViewBorderColor CGColor];
    self.imageView2.layer.borderColor = [self.imageViewBorderColor CGColor];
    self.imageView3.layer.borderColor = [self.imageViewBorderColor CGColor];
}

- (void)setImageViewBorderWidth:(CGFloat)width
{
    _imageViewBorderWidth = width;
    
    self.imageView1.layer.borderWidth = width;
    self.imageView2.layer.borderWidth = width;
    self.imageView3.layer.borderWidth = width;
}

- (void)setImageViewBorderColor:(UIColor *)color
{
    _imageViewBorderColor = color;
    
    self.imageView1.layer.borderColor = [color CGColor];
    self.imageView2.layer.borderColor = [color CGColor];
    self.imageView3.layer.borderColor = [color CGColor];
}

- (void)updateImageView:(UIImageView *)imageView withAsset:(PHAsset *)asset indexPath:(NSIndexPath *)indexPath
{
    PHImageManager *imageManager = [PHImageManager defaultManager];
    
    [imageManager requestImageForAsset:asset
                            targetSize:CGSizeScreenScale(imageView.frame.size)
                           contentMode:PHImageContentModeAspectFill
                               options:nil
                         resultHandler:^(UIImage *result, NSDictionary *info) {
                             // TODO: handle error and canceled -> info dict
                             if ([self.indexPath isEqual:indexPath]) {
                                 imageView.image = result;
                             }
                         }];
}

- (void)prepareForAssetCollection:(PHAssetCollection *)assetCollection mediaType:(QBImagePickerMediaType)mediaType atIndexPath:(NSIndexPath *)indexPath
{
    self.indexPath = indexPath;
    
    PHFetchOptions *options = [PHFetchOptions new];
    
    if (mediaType == QBImagePickerMediaTypeImage) {
        options.predicate = [NSPredicate predicateWithFormat:@"mediaType == %ld", PHAssetMediaTypeImage];
    } else if (mediaType == QBImagePickerMediaTypeVideo) {
        options.predicate = [NSPredicate predicateWithFormat:@"mediaType == %ld", PHAssetMediaTypeVideo];
    }
    
    // SEB: don't fetch here, it's going to be slow with many iCloud albums
    // use PHAssetCollection.estimatedAssetCount and PHAsset+fetchKeyAssetsInAssetCollection
    // later: pre-fetch all assets in the background to supply them to the assets collection view
    
    PHFetchResult *fetchResult = [PHAsset fetchAssetsInAssetCollection:assetCollection options:options];
    
    if (fetchResult.count >= 3) {
        self.imageView3.hidden = NO;
        [self updateImageView:self.imageView3 withAsset:fetchResult[fetchResult.count - 3] indexPath:indexPath];
    } else {
        self.imageView3.hidden = YES;
    }
    
    if (fetchResult.count >= 2) {
        self.imageView2.hidden = NO;
        [self updateImageView:self.imageView2 withAsset:fetchResult[fetchResult.count - 2] indexPath:indexPath];
    } else {
        self.imageView2.hidden = YES;
    }
    
    if (fetchResult.count >= 1) {
        [self updateImageView:self.imageView1 withAsset:fetchResult[fetchResult.count - 1] indexPath:indexPath];
    }
    
    if (fetchResult.count == 0) {
        self.imageView3.hidden = NO;
        self.imageView2.hidden = NO;
        
        // Set placeholder image
        UIImage *placeholderImage = [self.class placeholderImageWithSize:self.imageView1.frame.size];
        self.imageView1.image = placeholderImage;
        self.imageView2.image = placeholderImage;
        self.imageView3.image = placeholderImage;
    }
    
    // Album title
    self.titleLabel.text = assetCollection.localizedTitle;
    
    // Number of photos
    self.countLabel.text = [NSString stringWithFormat:@"%lu", (long)fetchResult.count];
}

@end
