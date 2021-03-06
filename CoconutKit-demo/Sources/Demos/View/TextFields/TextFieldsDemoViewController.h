//
//  TextFieldsDemoViewController.h
//  CoconutKit-demo
//
//  Created by Samuel Défago on 2/12/11.
//  Copyright 2011 Hortis. All rights reserved.
//

@interface TextFieldsDemoViewController : HLSViewController <UITextFieldDelegate> {
@private
    HLSTextField *m_textField1;
    HLSTextField *m_textField2;
    HLSTextField *m_textField3;
    HLSTextField *m_textField4;
}

@property (nonatomic, retain) IBOutlet HLSTextField *textField1;
@property (nonatomic, retain) IBOutlet HLSTextField *textField2;
@property (nonatomic, retain) IBOutlet HLSTextField *textField3;
@property (nonatomic, retain) IBOutlet HLSTextField *textField4;

@end
