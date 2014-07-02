//
//  SFModalViewController.m
//  ScottFree
//
//  Created by Joel Glovacki on 7/1/14.
//  Copyright (c) 2014 Company B. All rights reserved.
//

#import "SFModalViewController.h"

@interface SFModalViewController() <UITextFieldDelegate>
@end

@implementation SFModalViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    _email.delegate = self;
    _email.text = @"";
    // Do any additional setup after loading the view.
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [self sendEmail:nil];
    return YES;
}

//- (void)viewDidAppear:(BOOL)animated
//{
//    [super viewDidAppear: animated];
//    [self.email becomeFirstResponder];
//}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/


- (IBAction)sendEmail:(UIButton *)sender {
    
    NSString *email = _email.text;


    NSString *imagePath = [NSString stringWithFormat:@"%@/image.igo",[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject]];

    NSData *data = [NSData dataWithContentsOfFile:imagePath];
    
    NSMutableString *urlString = [[NSMutableString alloc] initWithFormat:@"file=thefile&&filename=selfie"];
    
    [urlString appendFormat:@"%@", data];
    
    NSData *postData = [urlString dataUsingEncoding:NSASCIIStringEncoding allowLossyConversion:YES];
    NSString *postLength = [NSString stringWithFormat:@"%d", [postData length]];
    NSString *baseurl = [NSString stringWithFormat:@"http://companyb.companybonline.com/selfie/mail.php?email=%@",email];
    
    NSURL *url = [NSURL URLWithString:baseurl];
    NSMutableURLRequest *urlRequest = [NSMutableURLRequest requestWithURL:url];
    [urlRequest setHTTPMethod: @"POST"];
    [urlRequest setValue:postLength forHTTPHeaderField:@"Content-Length"];
    [urlRequest setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
    [urlRequest setHTTPBody:postData];
    
    NSURLConnection *connection = [NSURLConnection connectionWithRequest:urlRequest delegate:self];
    [connection start];
    
    
    [_email resignFirstResponder];
    
    __weak SFModalViewController *weakSelf = self;
    
    [self dismissViewControllerAnimated:YES completion:^(void){
        weakSelf.email.text = @"";
    }];
    
}
@end
