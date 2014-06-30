//
//  SFViewController.h
//  ScottFree
//
//  Created by Joel Glovacki on 6/29/14.
//  Copyright (c) 2014 Company B. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AVCamPreviewView.h"

@class RGMPagingScrollView;
@class RGMPageControl;

@interface SFViewController : UIViewController

@property (nonatomic, weak) IBOutlet AVCamPreviewView *previewView;
@property (weak, nonatomic) IBOutlet UILabel *three;
@property (weak, nonatomic) IBOutlet UILabel *two;
@property (weak, nonatomic) IBOutlet UILabel *one;
@property (weak, nonatomic) IBOutlet UIButton *stillButton;
- (IBAction)takePhoto:(UIButton *)sender;

@property (nonatomic, strong) IBOutlet RGMPagingScrollView *pagingScrollView;
@property (nonatomic, strong) IBOutlet RGMPageControl *pageIndicator;

@property (strong, nonatomic) IBOutlet UIView *sidebar;


@end
