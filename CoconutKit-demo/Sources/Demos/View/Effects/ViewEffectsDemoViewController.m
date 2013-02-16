//
//  ViewEffectsDemoViewController.m
//  CoconutKit-demo
//
//  Created by Samuel Défago on 2/16/13.
//  Copyright (c) 2013 Hortis. All rights reserved.
//

#import "ViewEffectsDemoViewController.h"

@implementation ViewEffectsDemoViewController

#pragma mark Object creation and destruction

- (void)releaseViews
{
    [super releaseViews];
    
    self.imageView1 = nil;
    self.imageView2 = nil;
}

#pragma mark Accessors and mutators

@synthesize imageView1 = _imageView1;

@synthesize imageView2 = _imageView2;

#pragma mark View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self.imageView1 fadeLeft:0.2f right:0.6f];
    [self.imageView2 fadeTop:0.2f bottom:0.6f];
}

#pragma mark Localization

- (void)localize
{
    [super localize];
    
    // Code
}

@end
