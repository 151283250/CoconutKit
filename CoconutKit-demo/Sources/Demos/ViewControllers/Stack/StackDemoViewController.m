//
//  StackDemoViewController.m
//  CoconutKit-demo
//
//  Created by Samuel Défago on 22.07.11.
//  Copyright 2011 Hortis. All rights reserved.
//

#import "StackDemoViewController.h"

#import "ContainmentTestViewController.h"
#import "FixedSizeViewController.h"
#import "HeavyViewController.h"
#import "LandscapeOnlyViewController.h"
#import "LifeCycleTestViewController.h"
#import "MemoryWarningTestCoverViewController.h"
#import "PortraitOnlyViewController.h"
#import "RootStackDemoViewController.h"
#import "StretchableViewController.h"
#import "TransparentViewController.h"

typedef enum {
    ResizeMethodIndexEnumBegin = 0,
    ResizeMethodIndexFrame = ResizeMethodIndexEnumBegin,
    ResizeMethodIndexTransform,
    ResizeMethodIndexEnumEnd,
    ResizeMethodIndexEnumSize = ResizeMethodIndexEnumEnd - ResizeMethodIndexEnumBegin
} ResizeMethodIndex;

@interface StackDemoViewController ()

@property (nonatomic, retain) UIPopoverController *displayedPopoverController;

- (void)displayContentViewController:(UIViewController *)viewController;

- (void)updateIndexInfo;
- (NSUInteger)insertionIndex;
- (NSUInteger)removalIndex;

@end

@implementation StackDemoViewController

#pragma mark Object creation and destruction

- (id)init
{
    if ((self = [super init])) {
        UIViewController *rootViewController = [[[LifeCycleTestViewController alloc] init] autorelease];        
        HLSStackController *stackController = [[[HLSStackController alloc] initWithRootViewController:rootViewController] autorelease];
        stackController.delegate = self;
        stackController.title = @"HLSStackController";
        
        // To be able to test modal presentation contexts, we here make the stack controller display those modal view controllers
        // with the UIModalPresentationCurrentContext presentation style. The definesPresentationContext property is only available
        // since iOS 5
        if ([stackController respondsToSelector:@selector(definesPresentationContext)]) {
            stackController.definesPresentationContext = YES;
        }
        
        // We want to be able to test the stack controller autorotation behavior. Starting with iOS 6, all containers
        // allow rotation by default. Disable it for the placeholder so that we can observe the embedded stack controller
        // behavior
        self.autorotationMode = HLSAutorotationModeContainerAndTopChildren;
        
        // Pre-load other view controllers before display. Yep, this is possible!
        UIViewController *firstViewController = [[[TransparentViewController alloc] init] autorelease];
        [stackController pushViewController:firstViewController 
                        withTransitionClass:[HLSTransitionEmergeFromCenter class]
                                   animated:NO];
        UIViewController *secondViewController = [[[TransparentViewController alloc] init] autorelease];
        [stackController pushViewController:secondViewController 
                        withTransitionClass:[HLSTransitionPushFromRight class]
                                   animated:NO];
        UIViewController *thirdViewController = [[[TransparentViewController alloc] init] autorelease];
        [stackController pushViewController:thirdViewController 
                        withTransitionClass:[HLSTransitionCoverFromRightPushToBack class]
                                   animated:NO];
        UIViewController *fourthViewController = [[[LifeCycleTestViewController alloc] init] autorelease];
        [stackController pushViewController:fourthViewController 
                        withTransitionClass:[HLSTransitionCoverFromBottom class]
                                   animated:NO];
        UIViewController *fifthViewController = [[[LifeCycleTestViewController alloc] init] autorelease];
        [stackController pushViewController:fifthViewController 
                        withTransitionClass:[HLSTransitionPushFromTop class]
                                   animated:NO];
        UIViewController *sixthViewController = [[[LifeCycleTestViewController alloc] init] autorelease];
        [stackController pushViewController:sixthViewController
                        withTransitionClass:[HLSTransitionRotateVerticallyFromLeftClockwise class]
                                   animated:NO];
        UIViewController *seventhViewController = [[[LifeCycleTestViewController alloc] init] autorelease];
        [stackController pushViewController:seventhViewController
                        withTransitionClass:[HLSTransitionFlipHorizontally class]
                                   animated:NO];
        
        [self setInsetViewController:stackController atIndex:0];
    }
    return self;
}

- (void)dealloc
{
    self.displayedPopoverController = nil;

    [super dealloc];
}

- (void)releaseViews
{ 
    [super releaseViews];
    
    self.sizeSlider = nil;
    self.resizeMethodSegmentedControl = nil;
    self.popoverButton = nil;
    self.transitionPickerView = nil;
    self.autorotationModeSegmentedControl = nil;
    self.inTabBarControllerSwitch = nil;
    self.inNavigationControllerSwitch = nil;
    self.animatedSwitch = nil;
    self.indexSlider = nil;
    self.insertionIndexLabel = nil;
    self.removalIndexLabel = nil;
}

#pragma mark Accessors and mutators

@synthesize sizeSlider = m_sizeSlider;

@synthesize resizeMethodSegmentedControl = m_resizeMethodSegmentedControl;

@synthesize popoverButton = m_popoverButton;

@synthesize transitionPickerView = m_transitionPickerView;

@synthesize autorotationModeSegmentedControl = m_autorotationModeSegmentedControl;

@synthesize inTabBarControllerSwitch = m_inTabBarControllerSwitch;

@synthesize inNavigationControllerSwitch = m_inNavigationControllerSwitch;

@synthesize animatedSwitch = m_animatedSwitch;

@synthesize indexSlider = m_indexSlider;

@synthesize insertionIndexLabel = m_insertionIndexLabel;

@synthesize removalIndexLabel = m_removalIndexLabel;

@synthesize displayedPopoverController = m_displayedPopoverController;

#pragma mark View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
        
    self.transitionPickerView.delegate = self;
    self.transitionPickerView.dataSource = self;
    
    HLSStackController *stackController = (HLSStackController *)[self insetViewControllerAtIndex:0];
    self.autorotationModeSegmentedControl.selectedSegmentIndex = stackController.autorotationMode;
    
    self.inTabBarControllerSwitch.on = NO;
    self.inNavigationControllerSwitch.on = NO;
    
    self.indexSlider.minimumValue = 1.f;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    UIView *placeholderView = [self placeholderViewAtIndex:0];
    m_placeholderViewOriginalBounds = placeholderView.bounds;
    
    [self updateIndexInfo];
}

#pragma mark Orientation management

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    // Restore the original bounds for the previous orientation before they are updated by the rotation animation. This
    // is needed since there is no simple way to get the view bounds for the new orientation without actually rotating
    // the view
    UIView *placeholderView = [self placeholderViewAtIndex:0];
    placeholderView.bounds = m_placeholderViewOriginalBounds;
    
    [super willRotateToInterfaceOrientation:toInterfaceOrientation duration:duration];
    
    [self.displayedPopoverController dismissPopoverAnimated:NO];
}

- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    // The view has its new bounds (even if the rotation animation has not been played yet!). Store them so that we
    // are able to restore them when rotating again, and set size according to the previous size slider value. This
    // trick made in the -willRotate... and -willAnimateRotation... methods remains unnoticed!
    UIView *placeholderView = [self placeholderViewAtIndex:0];
    m_placeholderViewOriginalBounds = placeholderView.bounds;
    [self sizeChanged:nil];
    
    [super willAnimateRotationToInterfaceOrientation:toInterfaceOrientation duration:duration];
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
    [super didRotateFromInterfaceOrientation:fromInterfaceOrientation];
    
    [self.displayedPopoverController presentPopoverFromRect:self.popoverButton.bounds
                                                     inView:self.popoverButton
                                   permittedArrowDirections:UIPopoverArrowDirectionAny
                                                   animated:NO];
}

#pragma mark Localization

- (void)localize
{
    [super localize];
    
    self.title = @"HLSStackController";
    
    [self.autorotationModeSegmentedControl setTitle:NSLocalizedString(@"Container", @"Container") forSegmentAtIndex:0];
    [self.autorotationModeSegmentedControl setTitle:NSLocalizedString(@"No children", @"No children") forSegmentAtIndex:1];
    [self.autorotationModeSegmentedControl setTitle:NSLocalizedString(@"Visible", @"Visible") forSegmentAtIndex:2];
    [self.autorotationModeSegmentedControl setTitle:NSLocalizedString(@"All", @"All") forSegmentAtIndex:3];
}

#pragma mark Displaying a view controller according to the user settings

- (void)displayContentViewController:(UIViewController *)viewController
{
    HLSStackController *stackController = (HLSStackController *)[self insetViewControllerAtIndex:0];
    
    // We can even embed navigation and tab bar controllers within a placeolder view controller!
    UIViewController *pushedViewController = viewController;
    if (pushedViewController) {
        if (self.inNavigationControllerSwitch.on) {
            UINavigationController *navigationController = [[[UINavigationController alloc] initWithRootViewController:pushedViewController] autorelease];
            navigationController.autorotationMode = HLSAutorotationModeContainerAndTopChildren;
            pushedViewController = navigationController;
        }
        if (self.inTabBarControllerSwitch.on) {
            UITabBarController *tabBarController = [[[UITabBarController alloc] init] autorelease];
            tabBarController.viewControllers = [NSArray arrayWithObject:pushedViewController];
            pushedViewController = tabBarController;
        }    
    }
    
    NSUInteger pickedIndex = [self.transitionPickerView selectedRowInComponent:0];
    NSString *transitionName = [[HLSTransition availableTransitionNames] objectAtIndex:pickedIndex];
    
    @try {
        [stackController insertViewController:pushedViewController
                                      atIndex:[self insertionIndex]
                          withTransitionClass:NSClassFromString(transitionName)
                                     duration:kAnimationTransitionDefaultDuration
                                     animated:self.animatedSwitch.on];
    }
    @catch (NSException *exception) {
        UIAlertView *alertView = [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Error", @"Error")
                                                             message:NSLocalizedString(@"The view controller is not compatible with the container (most probably its orientation)",
                                                                                       @"The view controller is not compatible with the container (most probably its orientation)")
                                                            delegate:nil
                                                   cancelButtonTitle:NSLocalizedString(@"Dismiss", @"Dismiss")
                                                   otherButtonTitles:nil] autorelease];
        [alertView show];
        return;
    }
    
    [self updateIndexInfo];
}

#pragma mark Miscellaneous

- (void)updateIndexInfo
{
    HLSStackController *stackController = (HLSStackController *)[self insetViewControllerAtIndex:0];
    self.indexSlider.maximumValue = [stackController count];
    self.indexSlider.value = [stackController count];
    [self indexChanged:self.indexSlider];
}

- (NSUInteger)insertionIndex
{
    return roundf(self.indexSlider.value);
}

- (NSUInteger)removalIndex
{
    return MIN([self insertionIndex], [self.indexSlider maximumValue] - 1);
}

#pragma mark HLSStackControllerDelegate protocol implementation

- (void)stackController:(HLSStackController *)stackController
 willPushViewController:(UIViewController *)pushedViewController
    coverViewController:(UIViewController *)coveredViewController
               animated:(BOOL)animated
{
    HLSLoggerInfo(@"Will push view controller %@, cover view controller %@, animated = %@", pushedViewController, coveredViewController, HLSStringFromBool(animated));
}

- (void)stackController:(HLSStackController *)stackController
 willShowViewController:(UIViewController *)viewController
               animated:(BOOL)animated
{
    HLSLoggerInfo(@"Will show view controller %@, animated = %@", viewController, HLSStringFromBool(animated));
}

- (void)stackController:(HLSStackController *)stackController
  didShowViewController:(UIViewController *)viewController
               animated:(BOOL)animated
{
    HLSLoggerInfo(@"Did show view controller %@, animated = %@", viewController, HLSStringFromBool(animated));
    
    [self updateIndexInfo];
}

- (void)stackController:(HLSStackController *)stackController
  didPushViewController:(UIViewController *)pushedViewController
    coverViewController:(UIViewController *)coveredViewController
               animated:(BOOL)animated
{
    HLSLoggerInfo(@"Did push view controller %@, cover view controller %@, animated = %@", pushedViewController, coveredViewController, HLSStringFromBool(animated));
}

- (void)stackController:(HLSStackController *)stackController
  willPopViewController:(UIViewController *)poppedViewController
   revealViewController:(UIViewController *)revealedViewController
               animated:(BOOL)animated
{
    HLSLoggerInfo(@"Will pop view controller %@, reveal view controller %@, animated = %@", poppedViewController, revealedViewController, HLSStringFromBool(animated));
}

- (void)stackController:(HLSStackController *)stackController
 willHideViewController:(UIViewController *)viewController
               animated:(BOOL)animated
{
    HLSLoggerInfo(@"Will hide view controller %@, animated = %@", viewController, HLSStringFromBool(animated));
}

- (void)stackController:(HLSStackController *)stackController
  didHideViewController:(UIViewController *)viewController
               animated:(BOOL)animated
{
    HLSLoggerInfo(@"Did hide view controller %@, animated = %@", viewController, HLSStringFromBool(animated));
}

- (void)stackController:(HLSStackController *)stackController
   didPopViewController:(UIViewController *)poppedViewController
   revealViewController:(UIViewController *)revealedViewController
               animated:(BOOL)animated
{
    HLSLoggerInfo(@"Did pop view controller %@, reveal view controller %@, animated = %@", poppedViewController, revealedViewController, HLSStringFromBool(animated));
    
    [self updateIndexInfo];
}

#pragma mark UIPickerViewDataSource protocol implementation

- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView
{
    return 1;
}

- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component
{
    return [[HLSTransition availableTransitionNames] count];
}

#pragma mark UIPickerViewDelegate protocol implementation

- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component
{
    return [[HLSTransition availableTransitionNames] objectAtIndex:row];
}

#pragma mark UIPopoverControllerDelegate protocol implementation

- (void)popoverControllerDidDismissPopover:(UIPopoverController *)popoverController
{
    self.displayedPopoverController = nil;
}

#pragma mark Event callbacks

- (IBAction)sizeChanged:(id)sender
{
    UIView *placeholderView = [self placeholderViewAtIndex:0];
    
    if (self.resizeMethodSegmentedControl.selectedSegmentIndex == ResizeMethodIndexFrame) {
        placeholderView.bounds = CGRectMake(0.f,
                                            0.f,
                                            CGRectGetWidth(m_placeholderViewOriginalBounds) * self.sizeSlider.value,
                                            CGRectGetHeight(m_placeholderViewOriginalBounds) * self.sizeSlider.value);
    }
    else {
        placeholderView.transform = CGAffineTransformMakeScale(self.sizeSlider.value, self.sizeSlider.value);
    }
}

- (IBAction)changeResizeMethod:(id)sender
{
    // Reset the view to its maximum size
    self.sizeSlider.value = self.sizeSlider.maximumValue;
    
    UIView *placeholderView = [self placeholderViewAtIndex:0];
    placeholderView.bounds = m_placeholderViewOriginalBounds;
    placeholderView.transform = CGAffineTransformIdentity;
}

- (IBAction)displayLifeCycleTest:(id)sender
{
    LifeCycleTestViewController *lifecycleTestViewController = [[[LifeCycleTestViewController alloc] init] autorelease];
    [self displayContentViewController:lifecycleTestViewController];
}

- (IBAction)displayContainmentTest:(id)sender
{
    ContainmentTestViewController *containmentTestViewController = [[[ContainmentTestViewController alloc] init] autorelease];
    [self displayContentViewController:containmentTestViewController];
}

- (IBAction)displayStretchable:(id)sender
{
    StretchableViewController *stretchableViewController = [[[StretchableViewController alloc] init] autorelease];
    [self displayContentViewController:stretchableViewController];
}

- (IBAction)displayFixedSize:(id)sender
{
    FixedSizeViewController *fixedSizeViewController = [[[FixedSizeViewController alloc] init] autorelease];
    [self displayContentViewController:fixedSizeViewController];
}

- (IBAction)displayHeavy:(id)sender
{
    HeavyViewController *heavyViewController = [[[HeavyViewController alloc] init] autorelease];
    [self displayContentViewController:heavyViewController];
}

- (IBAction)displayPortraitOnly:(id)sender
{
    PortraitOnlyViewController *portraitOnlyViewController = [[[PortraitOnlyViewController alloc] init] autorelease];
    [self displayContentViewController:portraitOnlyViewController];
}

- (IBAction)displayLandscapeOnly:(id)sender
{
    LandscapeOnlyViewController *landscapeOnlyViewController = [[[LandscapeOnlyViewController alloc] init] autorelease];
    [self displayContentViewController:landscapeOnlyViewController];
}

- (IBAction)hideWithModal:(id)sender
{
    MemoryWarningTestCoverViewController *memoryWarningTestCoverViewController = [[[MemoryWarningTestCoverViewController alloc] init] autorelease];
    [self presentModalViewController:memoryWarningTestCoverViewController animated:YES];
}

- (IBAction)displayTransparent:(id)sender
{
    TransparentViewController *transparentViewController = [[[TransparentViewController alloc] init] autorelease];
    [self displayContentViewController:transparentViewController];
}

- (IBAction)testInModal:(id)sender
{
    RootStackDemoViewController *rootStackDemoViewController = [[[RootStackDemoViewController alloc] init] autorelease];
    HLSStackController *stackController = [[[HLSStackController alloc] initWithRootViewController:rootStackDemoViewController] autorelease];
    // Benefits from the fact that we are already logging HLSStackControllerDelegate methods in this class
    stackController.delegate = self;
    [self presentModalViewController:stackController animated:YES];
}

- (IBAction)testInPopover:(id)sender
{   
    RootStackDemoViewController *rootStackDemoViewController = [[[RootStackDemoViewController alloc] init] autorelease];
    HLSStackController *stackController = [[[HLSStackController alloc] initWithRootViewController:rootStackDemoViewController] autorelease];
    // Benefits from the fact that we are already logging HLSStackControllerDelegate methods in this class
    stackController.delegate = self;
    stackController.contentSizeForViewInPopover = CGSizeMake(800.f, 600.);
    self.displayedPopoverController = [[[UIPopoverController alloc] initWithContentViewController:stackController] autorelease];
    self.displayedPopoverController.delegate = self;
    [self.displayedPopoverController presentPopoverFromRect:self.popoverButton.bounds
                                                     inView:self.popoverButton
                                   permittedArrowDirections:UIPopoverArrowDirectionAny
                                                   animated:YES];
}

- (IBAction)pop:(id)sender
{
    HLSStackController *stackController = (HLSStackController *)[self insetViewControllerAtIndex:0];
    [stackController removeViewControllerAtIndex:[self removalIndex] animated:self.animatedSwitch.on];
}

- (IBAction)popToRoot:(id)sender
{
    HLSStackController *stackController = (HLSStackController *)[self insetViewControllerAtIndex:0];
    [stackController popToRootViewControllerAnimated:self.animatedSwitch.on];
}

- (IBAction)popThree:(id)sender
{
    HLSStackController *stackController = (HLSStackController *)[self insetViewControllerAtIndex:0];
    NSArray *viewControllers = [stackController viewControllers];
    UIViewController *targetViewController = nil;
    if ([viewControllers count] >= 4) {
        targetViewController = [viewControllers objectAtIndex:[viewControllers count] - 4];
    }
    else {
        targetViewController = [stackController rootViewController];
    }
    [stackController popToViewController:targetViewController animated:self.animatedSwitch.on];
}

- (IBAction)testResponderChain:(id)sender
{
    UIAlertView *alertView = [[[UIAlertView alloc] initWithTitle:HLSLocalizedStringFromUIKit(@"OK")
                                                         message:nil
                                                        delegate:nil
                                               cancelButtonTitle:NSLocalizedString(@"Dismiss", @"Dismiss")
                                               otherButtonTitles:nil] autorelease];
    [alertView show];
}

- (IBAction)changeAutorotationMode:(id)sender
{
    HLSStackController *stackController = (HLSStackController *)[self insetViewControllerAtIndex:0];
    stackController.autorotationMode = self.autorotationModeSegmentedControl.selectedSegmentIndex;
}

- (IBAction)indexChanged:(id)sender
{
    self.insertionIndexLabel.text = [NSString stringWithFormat:NSLocalizedString(@"Insertion index: %d", @"Insertion index: %d"),
                                     [self insertionIndex]];
    self.removalIndexLabel.text = [NSString stringWithFormat:NSLocalizedString(@"Removal index: %d", @"Removal index: %d"),
                                   [self removalIndex]];
}

- (IBAction)navigateForwardNonAnimated:(id)sender
{
    StackDemoViewController *stackDemoViewController = [[[StackDemoViewController alloc] init] autorelease];
    [self.navigationController pushViewController:stackDemoViewController animated:NO];
}

- (IBAction)navigateBackNonAnimated:(id)sender
{
    [self.navigationController popViewControllerAnimated:NO];
}

@end
