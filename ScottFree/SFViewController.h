//
//  SFViewController.h
//  ScottFree
//
//  Created by Joel Glovacki on 6/29/14.
//  Copyright (c) 2014 Company B. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AVCamPreviewView.h"
#import "SFFilterView.h"

@interface SFViewController : UIViewController

@property (nonatomic, weak) IBOutlet AVCamPreviewView *previewView;
@property (weak, nonatomic) IBOutlet UIButton *stillButton;
- (IBAction)takePhoto:(UIButton *)sender;

@property (weak, nonatomic) IBOutlet SFFilterView *filterView;

@property (strong, nonatomic) IBOutlet UIButton *retakeButton;
@property (strong, nonatomic) IBOutlet UIButton *postButton;
@property (strong, nonatomic) IBOutlet UIButton *postAndSendButton;

@property (strong, nonatomic) IBOutlet UIView *sidebar;
@property (weak, nonatomic) IBOutlet UIImageView *yourPhoto;
@property (weak, nonatomic) IBOutlet UIView *snapSidebar;
@property (weak, nonatomic) IBOutlet UIView *buttonsView;

@property (weak, nonatomic) IBOutlet UIView *intro;
@property (weak, nonatomic) IBOutlet UIButton *homeGoButton;

- (IBAction)getStarted:(UIButton *)sender;
- (IBAction)retakePhoto:(UIButton *)sender;
- (IBAction)postAndSendPhoto:(UIButton *)sender;
- (IBAction)PostPhoto:(UIButton *)sender;
@property (strong, nonatomic) IBOutlet UIView *mainView;

@end
