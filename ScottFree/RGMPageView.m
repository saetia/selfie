//
//  RGMPageView.m
//  RGMPagingScrollViewExample
//
//  Created by Ryder Mackay on 2012-10-11.
//  Copyright (c) 2012 Ryder Mackay. All rights reserved.
//

#import "RGMPageView.h"

@implementation RGMPageView

- (id)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame]) {

        
//        _label = [[UILabel alloc] initWithFrame:frame];
//        _label.font = [UIFont boldSystemFontOfSize:256.0f];
//        _label.textAlignment = NSTextAlignmentCenter;
//        _label.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
//        _label.backgroundColor = [UIColor clearColor];
//        [self addSubview:_label];
        
    
        
        _one = [UIButton buttonWithType:UIButtonTypeCustom];
        [_one setContentMode:UIViewContentModeScaleAspectFill];
        [_one setFrame: CGRectMake(0, 0, 256, 256)];
        [_one setBackgroundColor: [UIColor lightGrayColor]];
        [self addSubview:_one];
        
        _two = [UIButton buttonWithType:UIButtonTypeCustom];
        [_two setContentMode:UIViewContentModeScaleAspectFill];
        [_two setFrame: CGRectMake(0, 256, 256, 256)];
        [_two setBackgroundColor: [UIColor lightGrayColor]];
        [self addSubview:_two];
        
        _three = [UIButton buttonWithType:UIButtonTypeCustom];
        [_three setContentMode:UIViewContentModeScaleAspectFill];
        [_three setFrame: CGRectMake(0, 256 * 2, 256, 256)];
        [_three setBackgroundColor: [UIColor lightGrayColor]];
        [self addSubview:_three];
        
        
    }
    
    return self;
}



@end
