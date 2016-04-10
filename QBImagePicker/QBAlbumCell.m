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
    self.frontImageView.layer.borderWidth = self.imageViewBorderWidth;
    self.middleImageView.layer.borderWidth = self.imageViewBorderWidth;
    self.backImageView.layer.borderWidth = self.imageViewBorderWidth;
    
    self.frontImageView.layer.borderColor = [self.imageViewBorderColor CGColor];
    self.middleImageView.layer.borderColor = [self.imageViewBorderColor CGColor];
    self.backImageView.layer.borderColor = [self.imageViewBorderColor CGColor];
}

- (void)setImageViewBorderWidth:(CGFloat)width
{
    _imageViewBorderWidth = width;
    
    self.frontImageView.layer.borderWidth = width;
    self.middleImageView.layer.borderWidth = width;
    self.backImageView.layer.borderWidth = width;
}

- (void)setImageViewBorderColor:(UIColor *)color
{
    _imageViewBorderColor = color;
    
    self.frontImageView.layer.borderColor = [color CGColor];
    self.middleImageView.layer.borderColor = [color CGColor];
    self.backImageView.layer.borderColor = [color CGColor];
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

- (void)prepareForAssetCollection:(QBAssetCollection *)assetCollection atIndexPath:(NSIndexPath *)indexPath
{
    self.indexPath = indexPath;
    
    self.titleLabel.text = assetCollection.localizedTitle;
    
    self.countLabel.text = [NSString stringWithFormat:@"%lu", (long)assetCollection.count];
    self.countLabel.hidden = !assetCollection.hasCount;

    if (assetCollection.assetFetchResult) {
        PHFetchResult *fetchResult = assetCollection.assetFetchResult;
        
        self.backImageView.hidden = fetchResult.count < 3 && fetchResult.count != 0;
        self.middleImageView.hidden = fetchResult.count < 2 && fetchResult.count != 0;
        
        if (fetchResult.count >= 3) {
            [self updateImageView:self.backImageView withAsset:fetchResult[fetchResult.count - 3] indexPath:indexPath];
        }
        
        if (fetchResult.count >= 2) {
            [self updateImageView:self.middleImageView withAsset:fetchResult[fetchResult.count - 2] indexPath:indexPath];
        }
        
        if (fetchResult.count >= 1) {
            [self updateImageView:self.frontImageView withAsset:fetchResult[fetchResult.count - 1] indexPath:indexPath];
        }
        
        if (fetchResult.count == 0) {
            UIImage *placeholderImage = [self.class placeholderImageWithSize:self.frontImageView.frame.size];
            self.frontImageView.image = placeholderImage;
            self.middleImageView.image = placeholderImage;
            self.backImageView.image = placeholderImage;
        }
    }
}

@end
