//
//  SFModalViewController.h
//  ScottFree
//
//  Created by Joel Glovacki on 7/1/14.
//  Copyright (c) 2014 Company B. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SFModalViewController : UIViewController
@property (weak, nonatomic) IBOutlet UITextField *email;
- (IBAction)sendEmail:(UIButton *)sender;

@end
