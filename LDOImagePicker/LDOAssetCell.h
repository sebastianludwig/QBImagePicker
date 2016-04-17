//
//  LDOAssetCell.h
//  LDOImagePicker
//
//  Created by Sebastian Ludwig on 17.04.2016.
//  Copyright (c) 2016 Sebastian Ludwig. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Photos/Photos.h>
#import "LDOVideoIndicatorView.h"

@interface LDOAssetCell : UICollectionViewCell

@property (weak, nonatomic) IBOutlet UIImageView *imageView;
@property (weak, nonatomic) IBOutlet LDOVideoIndicatorView *videoIndicatorView;

@property (nonatomic, assign) BOOL showsOverlayViewWhenSelected;

- (void)prepareForAsset:(PHAsset *)asset itemSize:(CGSize)itemSize indexPath:(NSIndexPath *)indexPath imageManager:(PHImageManager *)imageManager;

@end
