//
//  ProgrammaticTableViewCell.h
//  CoconutKit-demo
//
//  Created by Samuel Défago on 2/10/11.
//  Copyright 2011 Hortis. All rights reserved.
//

@interface ProgrammaticTableViewCell : HLSTableViewCell {
@private
    UILabel *_label;
}

@property (nonatomic, retain) UILabel *label;

@end
