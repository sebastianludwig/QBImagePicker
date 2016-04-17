//
//  ViewController.m
//  LDOImagePickerDemo
//
//  Created by Sebastian Ludwig on 17.04.2016.
//  Copyright (c) 2016 Sebastian Ludwig. All rights reserved.
//

#import "ViewController.h"
#import <LDOImagePicker/LDOImagePicker.h>

@interface ViewController () <LDOImagePickerControllerDelegate>

@end

@implementation ViewController


#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    LDOImagePickerController *imagePickerController = [LDOImagePickerController new];
    imagePickerController.delegate = self;
    imagePickerController.mediaType = LDOImagePickerMediaTypeAny;
    imagePickerController.showsNumberOfSelectedAssets = YES;
    
    imagePickerController.prompt = @"DO IT!";
    //    imagePickerController.mediaType = LDOImagePickerMediaTypeImage;
    imagePickerController.allowsMultipleSelection = (indexPath.section == 1);
    
    if (indexPath.section == 1) {
        switch (indexPath.row) {
            case 1:
                imagePickerController.minimumNumberOfSelection = 3;
                break;
                
            case 2:
                imagePickerController.maximumNumberOfSelection = 6;
                break;
                
            case 3:
                imagePickerController.minimumNumberOfSelection = 1;
                imagePickerController.maximumNumberOfSelection = 1;
                break;

            case 4:
                imagePickerController.maximumNumberOfSelection = 2;
                [imagePickerController.assetSelection addAsset:[PHAsset fetchAssetsWithOptions:nil].lastObject];
                break;
                
            default:
                break;
        }
    }
    
    [self presentViewController:imagePickerController animated:YES completion:NULL];
}


#pragma mark - LDOImagePickerControllerDelegate

- (void)imagePickerController:(LDOImagePickerController *)imagePickerController didFinishPickingAssets:(NSArray *)assets
{
    NSLog(@"Selected assets:");
    NSLog(@"%@", assets);
    
    [self dismissViewControllerAnimated:YES completion:NULL];
}

- (void)imagePickerControllerDidCancel:(LDOImagePickerController *)imagePickerController
{
    NSLog(@"Canceled.");
    
    [self dismissViewControllerAnimated:YES completion:NULL];
}

@end
