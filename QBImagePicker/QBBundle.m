//
//  QBBundle.m
//  QBImagePicker
//
//  Created by Sebastian Ludwig on 10.04.16.
//  Copyright © 2016 Katsuma Tanaka. All rights reserved.
//

#import "QBBundle.h"

@implementation QBBundle

+ (NSBundle *)imagePickerBundle
{
    NSBundle *bundle = [NSBundle bundleForClass:self];
    NSString *resourceBundlePath = [bundle pathForResource:@"QBImagePicker" ofType:@"bundle"];
    if (resourceBundlePath) {
        bundle = [NSBundle bundleWithPath:resourceBundlePath];
    }
    
    return bundle;
}

@end
