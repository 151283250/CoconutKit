//
//  HLSServiceAnswer.m
//  nut
//
//  Created by Samuel Défago on 7/31/10.
//  Copyright 2010 Hortis. All rights reserved.
//

#import "HLSServiceAnswer.h"

@interface HLSServiceAnswer ()

@property (nonatomic, retain) NSString *body;
@property (nonatomic, retain) NSString *requestId;

@end

@implementation HLSServiceAnswer

#pragma mark Object creation and destruction

- (id)initWithBody:(NSString *)body forRequestId:(NSString *)requestId
{
    if (self = [super init]) {
        self.body = body;
        self.requestId = requestId;
    }
    return self;
}

- (void)dealloc
{
    self.body = nil;
    self.requestId = nil;
    [super dealloc];
}

#pragma mark Accessors and mutators

@synthesize body = m_body;

@synthesize requestId = m_requestId;

@end
