//
//  LDOImagePickerBundle.m
//  LDOImagePicker
//
//  Created by Sebastian Ludwig on 10.04.16.
//  Copyright (c) 2016 Sebastian Ludwig. All rights reserved.
//

#import "LDOImagePickerBundle.h"

@implementation LDOImagePickerBundle

+ (NSBundle *)ldoImagePickerBundle
{
    NSBundle *bundle = [NSBundle bundleForClass:self];
    NSString *resourceBundlePath = [bundle pathForResource:@"LDOImagePicker" ofType:@"bundle"];
    if (resourceBundlePath) {
        bundle = [NSBundle bundleWithPath:resourceBundlePath];
    }
    
    return bundle;
}

@end
