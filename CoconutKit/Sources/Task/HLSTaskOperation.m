//
//  HLSTaskOperation.m
//  CoconutKit
//
//  Created by Samuel Défago on 12/18/10.
//  Copyright 2010 Hortis. All rights reserved.
//

#import "HLSTaskOperation.h"

#import "HLSAssert.h"
#import "HLSLogger.h"
#import "HLSTask+Friend.h"
#import "HLSTaskGroup+Friend.h"
#import "HLSTaskManager+Friend.h"

@interface HLSTaskOperation ()

@property (nonatomic, assign) HLSTaskManager *taskManager;
@property (nonatomic, assign) HLSTask *task;
@property (nonatomic, retain) NSThread *callingThread;

- (void)operationMain;

- (void)onCallingThreadPerformSelector:(SEL)selector object:(NSObject *)objectOrNil;
- (void)updateProgressToValue:(float)progress;
- (void)attachError:(NSError *)error;

- (void)notifyStart;
- (void)notifyRunningWithProgress:(NSNumber *)progress;
- (void)notifyEnd;
- (void)notifySettingReturnInfo:(NSDictionary *)returnInfo;
- (void)notifySettingError:(NSError *)error;

@end

@implementation HLSTaskOperation

#pragma mark -
#pragma mark Object creation and destruction

- (id)initWithTaskManager:(HLSTaskManager *)taskManager task:(HLSTask *)task
{
    if ((self = [super init])) {
        self.taskManager = taskManager;
        self.task = task;
        self.callingThread = [NSThread currentThread];
    }
    return self;
}

- (id)init
{
    HLSForbiddenInheritedMethod();
    return nil;
}

- (void)dealloc
{
    self.taskManager = nil;
    self.task = nil;
    self.callingThread = nil;
    [super dealloc];
}

#pragma mark -
#pragma mark Accessors and mutators

@synthesize taskManager = _taskManager;

@synthesize task = _task;

@synthesize callingThread = _callingThread;

#pragma mark -
#pragma mark Thread main function

- (void)main
{
    // Notify begin
    [self onCallingThreadPerformSelector:@selector(notifyStart) object:nil];
    
    // Execute the main method code
    [self operationMain];
    
    // Notify end
    [self onCallingThreadPerformSelector:@selector(notifyEnd) object:nil];
}

- (void)operationMain
{
    HLSMissingMethodImplementation();
}

#pragma mark -
#pragma mark Executing code on the calling thread

- (void)onCallingThreadPerformSelector:(SEL)selector object:(NSObject *)objectOrNil
{
    // HUGE WARNING here! If we do not wait until done, we might sometimes (most notably under heavy load) perform selectors
    // on the calling thread, but not in the order they were scheduled. This can be a complete disaster if we perform the
    // notifyEnd method before a progress update via notifyRunningWithProgress:. If waitUntilDone is left to NO, then this
    // might happen and, since the task is released by notifyEnd, any notifyRunningWithProgress: coming after it would crash.
    // To avoid this issue, waitUntilDone must clearly be set to YES.
    // Remark: This equivalently means that when waitUntilDone is NO, selectors are not necessarily processed in the order they 
    //         are "sent" to the calling thread. Most of the time they seem to, but not always. Setting waitUntilDone to YES 
    //         guarantees they will be processed sequentially (of course, since performSelector blocks the thread). IMHO, I would 
    //         have not called this method performSelector:onThread:withObject:waitUntilDone:, 
    [self performSelector:selector 
                 onThread:self.callingThread 
               withObject:objectOrNil
            waitUntilDone:YES];
}

// Remark: Originally, I intended to call this method "setProgress:", but this was a bad idea. It could have conflicted
//         with setProgress: methods defined by subclasses of HLSTaskOperation (and guess what, this just happened
//         since one of my subclasses implemented the ASIProgressDelegate protocol, which declares a setProgress: method)
- (void)updateProgressToValue:(float)progress
{
    [self onCallingThreadPerformSelector:@selector(notifyRunningWithProgress:) 
                                  object:[NSNumber numberWithFloat:progress]];
}

- (void)attachReturnInfo:(NSDictionary *)returnInfo
{
    [self onCallingThreadPerformSelector:@selector(notifySettingReturnInfo:) 
                                  object:returnInfo];
}

- (void)attachError:(NSError *)error
{
    [self onCallingThreadPerformSelector:@selector(notifySettingError:) 
                                  object:error];
}

#pragma mark -
#pragma mark Code to be executed on the calling thread

- (void)notifyStart
{
    HLSLoggerDebug(@"Task %@ starts", self.task);
    
    // Reset status
    [self.task reset];
    
    // If part of a non-running task group, first flag the task group as running and notify
    HLSTaskGroup *taskGroup = self.task.taskGroup;
    if (taskGroup && ! taskGroup.running) {
        HLSLoggerDebug(@"Task group %@ starts", taskGroup);
        
        taskGroup.running = YES;
        id<HLSTaskGroupDelegate> taskGroupDelegate = [self.taskManager delegateForTaskGroup:taskGroup];
        if ([taskGroupDelegate respondsToSelector:@selector(taskGroupDidStart:)]) {
            [taskGroupDelegate taskGroupDidStart:taskGroup];
        }
    }
    
    // ... then flag the task as running and notify ...
    id<HLSTaskDelegate> taskDelegate = [self.taskManager delegateForTask:self.task];
    self.task.running = YES;
    if ([taskDelegate respondsToSelector:@selector(taskDidStart:)]) {
        [taskDelegate taskDidStart:self.task];
    }
    self.task.progressTracker.progress = 0.f;
    if ([taskDelegate respondsToSelector:@selector(taskDidProgress:)]) {
        [taskDelegate taskDidProgress:self.task];
    }
    
    // ... and finally update and notify about the task group status
    if (taskGroup) {
        [taskGroup updateStatus];
        id<HLSTaskGroupDelegate> taskGroupDelegate = [self.taskManager delegateForTaskGroup:taskGroup];
        if ([taskGroupDelegate respondsToSelector:@selector(taskGroupDidProgress:)]) {
            [taskGroupDelegate taskGroupDidProgress:taskGroup];
        }
    }
}

- (void)notifyRunningWithProgress:(NSNumber *)progress
{
    // Update and notify about the task progress
    self.task.progressTracker.progress = [progress floatValue];
    id<HLSTaskDelegate> taskDelegate = [self.taskManager delegateForTask:self.task];
    if ([taskDelegate respondsToSelector:@selector(taskDidProgress:)]) {
        [taskDelegate taskDidProgress:self.task];
    }
    
    // If part of a task group, update and notify about its status as well
    HLSTaskGroup *taskGroup = self.task.taskGroup;
    if (taskGroup) {
        [taskGroup updateStatus];
        id<HLSTaskGroupDelegate> taskGroupDelegate = [self.taskManager delegateForTaskGroup:taskGroup];
        if ([taskGroupDelegate respondsToSelector:@selector(taskGroupDidProgress:)]) {
            [taskGroupDelegate taskGroupDidProgress:taskGroup];
        }
    }
}

- (void)notifyEnd
{
    id<HLSTaskDelegate> taskDelegate = [self.taskManager delegateForTask:self.task];
    
    // If part of a task group, first cancel all dependent tasks; a task group is removed once all tasks it contains are
    // marked as finished. Here we are careful enough to cancel all dependent task before the current task is set as 
    // finished. This way the task group is guaranteed to survive the loop below
    HLSTaskGroup *taskGroup = self.task.taskGroup;
    if (taskGroup) {
        // Cancel all tasks strongly depending on the task it not successful
        if ([self isCancelled] || self.task.error) {
            NSSet *strongDependents = [taskGroup strongDependentsForTask:self.task];
            for (HLSTask *dependent in strongDependents) {
                [self.taskManager cancelTask:dependent];
            }
        }
    }
    
    // Update the progress to 1.f on success, but do not notify that the task has progressed if an error has been
    // encountered or if the task has been cancelled
    self.task.progressTracker.progress = 1.f;
    if (! self.task.error && ! [self isCancelled]) {
        if ([taskDelegate respondsToSelector:@selector(taskDidProgress:)]) {
            [taskDelegate taskDidProgress:self.task];
        }
    }
    self.task.finished = YES;
    self.task.running = NO;
    
    // The task has been cancelled
    if ([self isCancelled]) {
        HLSLoggerDebug(@"Task %@ has been cancelled", self.task);
        if ([taskDelegate respondsToSelector:@selector(taskDidCancel:)]) {
            [taskDelegate taskDidCancel:self.task];
        }        
    }
    // The task has been processed
    else {
        // Successful
        if (! self.task.error) {
            HLSLoggerDebug(@"Task %@ ends successfully", self.task);
        }
        // An error has been attached during processing
        else {
            HLSLoggerDebug(@"Task %@ has encountered an error", self.task);
        }
        
        if ([taskDelegate respondsToSelector:@selector(taskDidFinish:)]) {
            [taskDelegate taskDidFinish:self.task];
        }        
    }
    
    // If part of a task group
    if (taskGroup) {
        // Update an notify about the task group progress as well
        id<HLSTaskGroupDelegate> taskGroupDelegate = [self.taskManager delegateForTaskGroup:taskGroup];
        [taskGroup updateStatus];
        if ([taskGroupDelegate respondsToSelector:@selector(taskGroupDidProgress:)]) {
            [taskGroupDelegate taskGroupDidProgress:taskGroup];
        }
        
        // If the task group is now complete, update and notify as well
        if (taskGroup.finished) {
            taskGroup.running = NO;
            
            if (! taskGroup.cancelled) {
                HLSLoggerDebug(@"Task group %@ ends successfully", taskGroup);
                if ([taskGroupDelegate respondsToSelector:@selector(taskGroupDidFinish:)]) {
                    [taskGroupDelegate taskGroupDidFinish:taskGroup];
                }
            }
            else {
                HLSLoggerDebug(@"Task group %@ has been cancelled", taskGroup);
                if ([taskGroupDelegate respondsToSelector:@selector(taskGroupDidCancel:)]) {
                    [taskGroupDelegate taskGroupDidCancel:taskGroup];
                }
            }
        }
    }
    
    // Only the operation itself knows when it is done and can unregister itself from the manager it was
    // executed from
    [self.taskManager unregisterOperation:self];
}

- (void)notifySettingReturnInfo:(NSDictionary *)returnInfo
{
    self.task.returnInfo = returnInfo;
}

- (void)notifySettingError:(NSError *)error
{
    self.task.error = error;
}

@end
