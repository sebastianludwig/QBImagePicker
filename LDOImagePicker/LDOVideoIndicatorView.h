//
//  LDOVideoIndicatorView.h
//  LDOImagePicker
//
//  Created by Sebastian Ludwig on 17.04.2016.
//  Copyright (c) 2016 Sebastian Ludwig. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "LDOVideoIconView.h"
#import "LDOSlomoIconView.h"

@interface LDOVideoIndicatorView : UIView

@property (nonatomic, weak) IBOutlet UILabel *timeLabel;
@property (nonatomic, weak) IBOutlet LDOVideoIconView *videoIcon;
@property (nonatomic, weak) IBOutlet LDOSlomoIconView *slomoIcon;


@end
