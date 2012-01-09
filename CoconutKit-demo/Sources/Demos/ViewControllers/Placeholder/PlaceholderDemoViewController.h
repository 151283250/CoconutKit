//
//  PlaceholderDemoViewController.h
//  CoconutKit-demo
//
//  Created by Samuel Défago on 2/14/11.
//  Copyright 2011 Hortis. All rights reserved.
//

// Forward declarations
@class HeavyViewController;

@interface PlaceholderDemoViewController : HLSPlaceholderViewController <UIPickerViewDataSource, UIPickerViewDelegate> {
@private
    UIPickerView *m_transitionPickerView;
    UISwitch *m_forwardingPropertiesSwitch;
    HeavyViewController *m_heavyViewController;
}

@property (nonatomic, retain) IBOutlet UIPickerView *transitionPickerView;
@property (nonatomic, retain) IBOutlet UISwitch *forwardingPropertiesSwitch;

- (IBAction)lifeCycleTestSampleButtonClicked:(id)sender;
- (IBAction)stretchableSampleButtonClicked:(id)sender;
- (IBAction)fixedSizeSampleButtonClicked:(id)sender;
- (IBAction)heavySampleButtonClicked:(id)sender;
- (IBAction)portraitOnlyButtonClicked:(id)sender;
- (IBAction)landscapeOnlyButtonClicked:(id)sender;
- (IBAction)removeButtonClicked:(id)sender;
- (IBAction)hideWithModalButtonClicked:(id)sender;
- (IBAction)orientationClonerButtonClicked:(id)sender;
- (IBAction)containerCustomizationButtonClicked:(id)sender;
- (IBAction)forwardingPropertiesSwitchValueChanged:(id)sender;

@end
