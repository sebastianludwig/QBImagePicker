//
//  QBAssetCell.m
//  QBImagePicker
//
//  Created by Katsuma Tanaka on 2015/04/03.
//  Copyright (c) 2015 Katsuma Tanaka. All rights reserved.
//

#import "QBAssetCell.h"

static CGSize CGSizeScale(CGSize size, CGFloat scale) {
    return CGSizeMake(size.width * scale, size.height * scale);
}

@interface QBAssetCell ()

@property (weak, nonatomic) IBOutlet UIView *overlayView;

@property (nonatomic, copy) NSIndexPath *indexPath;

@end

@implementation QBAssetCell

- (void)setSelected:(BOOL)selected
{
    [super setSelected:selected];
    
    // Show/hide overlay view
    self.overlayView.hidden = !(selected && self.showsOverlayViewWhenSelected);
}

- (void)prepareForAsset:(PHAsset *)asset itemSize:(CGSize)itemSize indexPath:(NSIndexPath *)indexPath imageManager:(PHImageManager *)imageManager
{
    self.indexPath = indexPath;
    
    // Image
    __weak typeof(self)weakSelf = self;
    [imageManager requestImageForAsset:asset
                                 targetSize:CGSizeScale(itemSize, [[UIScreen mainScreen] scale])
                                contentMode:PHImageContentModeAspectFill
                                    options:nil
                              resultHandler:^(UIImage *result, NSDictionary *info) {
                                  __strong typeof(self)strongSelf = weakSelf;
                                  // TODO: handle error and canceled -> info dict
                                  if ([strongSelf.indexPath isEqual:indexPath]) {
                                      strongSelf.imageView.image = result;
                                  }
                              }];
    
    // Video indicator
    if (asset.mediaType == PHAssetMediaTypeVideo) {
        self.videoIndicatorView.hidden = NO;
        
        NSInteger minutes = (NSInteger)(asset.duration / 60.0);
        NSInteger seconds = (NSInteger)ceil(asset.duration - 60.0 * (double)minutes);
        self.videoIndicatorView.timeLabel.text = [NSString stringWithFormat:@"%02ld:%02ld", (long)minutes, (long)seconds];
        
        if (asset.mediaSubtypes & PHAssetMediaSubtypeVideoHighFrameRate) {
            self.videoIndicatorView.videoIcon.hidden = YES;
            self.videoIndicatorView.slomoIcon.hidden = NO;
        }
        else {
            self.videoIndicatorView.videoIcon.hidden = NO;
            self.videoIndicatorView.slomoIcon.hidden = YES;
        }
    } else {
        self.videoIndicatorView.hidden = YES;
    }
}

@end
