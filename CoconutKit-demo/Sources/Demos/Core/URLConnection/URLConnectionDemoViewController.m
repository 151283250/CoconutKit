//
//  URLConnectionDemoViewController.m
//  CoconutKit-demo
//
//  Created by Samuel Défago on 11.04.12.
//  Copyright (c) 2012 Hortis. All rights reserved.
//

#import "URLConnectionDemoViewController.h"

#import "Coconut.h"
#import "CoconutTableViewCell.h"

@interface URLConnectionDemoViewController ()

// We keep a reference to asynchronous connections we want to be able to cancel manually. A weak reference
// suffices since HLSURLConnection objects survive while running
@property (nonatomic, assign) HLSURLConnection *asynchronousConnection;

@property (nonatomic, retain) NSArray *coconuts;

- (void)disableUserInterfaceForAsynchronousConnection;
- (void)disableUserInterfaceForAsynchronousConnectionNoCancel;
- (void)enableUserInterface;

- (void)reloadData;

@end

@implementation URLConnectionDemoViewController

#pragma mark Object creation and destruction

- (void)dealloc
{
    self.asynchronousConnection = nil;
    self.coconuts = nil;
    
    [super dealloc];
}

- (void)releaseViews
{
    [super releaseViews];
    
    self.cachedImagesTableView = nil;
    self.nonCachedImagesTableView = nil;
    self.asynchronousLoadButton = nil;
    self.cancelButton = nil;
    self.synchronousLoadButton = nil;
    self.asynchronousLoadNoCancelButton = nil;
    self.clearButton = nil;
    self.progressView = nil;
    self.treatingHTTPErrorsAsFailuresSwitch = nil;
}

#pragma mark Accessors and mutators

@synthesize asynchronousConnection = m_asynchronousConnection;

@synthesize coconuts = m_coconuts;

@synthesize cachedImagesTableView = m_cachedImagesTableView;

@synthesize nonCachedImagesTableView = m_nonCachedImagesTableView;

@synthesize asynchronousLoadButton = m_asynchronousLoadButton;

@synthesize cancelButton = m_cancelButton;

@synthesize synchronousLoadButton = m_synchronousLoadButton;

@synthesize asynchronousLoadNoCancelButton = m_asynchronousLoadNoCancelButton;

@synthesize clearButton = m_clearButton;

@synthesize progressTestButton = m_progressTestButton;

@synthesize progressView = m_progressView;

@synthesize treatingHTTPErrorsAsFailuresSwitch = m_treatingHTTPErrorsAsFailuresSwitch;

#pragma mark View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.cachedImagesTableView.dataSource = self;
    self.cachedImagesTableView.delegate = self;
    self.cachedImagesTableView.rowHeight = [CoconutTableViewCell height];
    
    self.nonCachedImagesTableView.dataSource = self;
    self.nonCachedImagesTableView.delegate = self;
    self.nonCachedImagesTableView.rowHeight = [CoconutTableViewCell height];
    
    [self enableUserInterface];
    
    self.progressView.hidden = YES;
}

#pragma mark Orientation management

- (NSUInteger)supportedInterfaceOrientations
{
    return [super supportedInterfaceOrientations] & UIInterfaceOrientationMaskPortrait;
}

#pragma mark Localization

- (void)localize
{
    [super localize];
    
    self.title = NSLocalizedString(@"Networking with HLSURLConnection", @"Networking with HLSURLConnection");
    
    // Must sort coconuts by name again when switching languages
    NSSortDescriptor *nameSortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"name" 
                                                                         ascending:YES 
                                                                          selector:@selector(localizedCaseInsensitiveCompare:)];
    self.coconuts = [self.coconuts sortedArrayUsingDescriptor:nameSortDescriptor]; 
    
    [self reloadData];
}

#pragma mark User interface

- (void)disableUserInterfaceForAsynchronousConnection
{
    self.asynchronousLoadButton.hidden = YES;
    self.asynchronousLoadNoCancelButton.hidden = YES;
    self.synchronousLoadButton.hidden = YES;
    self.cancelButton.hidden = NO;
    self.clearButton.hidden = YES;
}

- (void)disableUserInterfaceForAsynchronousConnectionNoCancel
{
    self.asynchronousLoadButton.hidden = YES;
    self.asynchronousLoadNoCancelButton.hidden = YES;
    self.synchronousLoadButton.hidden = YES;
    self.cancelButton.hidden = YES;
    self.clearButton.hidden = YES;
}

- (void)enableUserInterface
{
    self.asynchronousLoadButton.hidden = NO;
    self.asynchronousLoadNoCancelButton.hidden = NO;
    self.synchronousLoadButton.hidden = NO;
    self.cancelButton.hidden = YES;
    self.clearButton.hidden = NO;
}

#pragma mark HLSURLConnectionDelegate protocol implementation

- (void)connection:(HLSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
    HLSLoggerInfo(@"Connection '%@' did receive response", connection.tag);
    
    // Cancel HTTP connections with errors (only for connections with treatingHTTPErrorsAsFailures = NO, otherwise this method
    // won't be called when an HTTP error status code is received)
    if ([response isKindOfClass:[NSHTTPURLResponse class]]) {
        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
        NSInteger statusCode = [httpResponse statusCode];
        if (statusCode >= 400) {
            [connection cancel];
            
            UIAlertView *alertView = [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"HTTP error", @"HTTP error") 
                                                                 message:[NSHTTPURLResponse localizedStringForStatusCode:statusCode]
                                                                delegate:nil 
                                                       cancelButtonTitle:NSLocalizedString(@"Dismiss", @"Dismiss")
                                                       otherButtonTitles:nil] autorelease];
            [alertView show];
        }
    }    
}

- (void)connectionDidReceiveData:(HLSURLConnection *)connection
{
    HLSLoggerInfo(@"Connection '%@' did receive data (progress = %f)", connection.tag, connection.progress);
    
    if ([connection.tag isEqualToString:@"httpGet"]) {
        self.progressView.progress = connection.progress;
    }
}

- (void)connectionDidFinishLoading:(HLSURLConnection *)connection
{
    HLSLoggerInfo(@"Connection '%@' did finish loading", connection.tag);
    
    if ([connection.tag isEqualToString:@"asynchronousConnection"]
            || [connection.tag isEqualToString:@"asynchronousConnectionNoCancel"]
            || [connection.tag isEqualToString:@"synchronousConnection"]) {
        [self enableUserInterface];
        
        NSDictionary *coconutsDictionary = [NSDictionary dictionaryWithContentsOfFile:connection.downloadFilePath];
        NSArray *coconuts = [Coconut coconutsFromDictionary:coconutsDictionary];
        
        NSSortDescriptor *nameSortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"name" 
                                                                             ascending:YES 
                                                                              selector:@selector(localizedCaseInsensitiveCompare:)];
        self.coconuts = [coconuts sortedArrayUsingDescriptor:nameSortDescriptor]; 
        
        [self reloadData];
    }
    else if ([connection.tag isEqualToString:@"httpGet"]) {
        self.progressTestButton.hidden = NO;
        self.progressView.hidden = YES;
        
        UIAlertView *alertView = [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Success", @"Success")
                                                             message:NSLocalizedString(@"The data was transferred", @"The data was transferred") 
                                                            delegate:nil 
                                                   cancelButtonTitle:NSLocalizedString(@"Dismiss", @"Dismiss") 
                                                   otherButtonTitles:nil] autorelease];
        [alertView show];
    }
}

- (void)connection:(HLSURLConnection *)connection didFailWithError:(NSError *)error
{
    HLSLoggerInfo(@"Connection '%@' did fail with error: %@", connection.tag, error);
    
    if ([connection.tag isEqualToString:@"asynchronousConnection"]
            || [connection.tag isEqualToString:@"asynchronousConnectionNoCancel"]
            || [connection.tag isEqualToString:@"synchronousConnection"]) {
        [self enableUserInterface];
        
        UIAlertView *alertView = [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Error", @"Error")
                                                             message:NSLocalizedString(@"The data could not be retrieved", @"The data could not be retrieved") 
                                                            delegate:nil 
                                                   cancelButtonTitle:NSLocalizedString(@"Dismiss", @"Dismiss")
                                                   otherButtonTitles:nil] autorelease];
        [alertView show];   
    }
    else if ([connection.tag isEqualToString:@"httpGet"]) {
        self.progressTestButton.hidden = NO;
        self.progressView.hidden = YES;
        
        UIAlertView *alertView = [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Error", @"Error")
                                                             message:NSLocalizedString(@"The data could not be transferred", @"The data could not be transferred")
                                                            delegate:nil 
                                                   cancelButtonTitle:NSLocalizedString(@"Dismiss", @"Dismiss") 
                                                   otherButtonTitles:nil] autorelease];
        [alertView show];
    }
    else if ([connection.tag isEqualToString:@"http404"]) {
        UIAlertView *alertView = [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Error", @"Error") 
                                                             message:NSLocalizedString(@"A connection failure occurred", @"A connection failure occurred")
                                                            delegate:nil 
                                                   cancelButtonTitle:NSLocalizedString(@"Dismiss", @"Dismiss")
                                                   otherButtonTitles:nil] autorelease];
        [alertView show];
    }
}

- (void)connectionDidCancel:(HLSURLConnection *)connection
{
    HLSLoggerInfo(@"Connection '%@' did cancel", connection.tag);
    
    [self enableUserInterface];
}

#pragma mark Updating the view

- (void)reloadData
{
    [self.cachedImagesTableView reloadData];
    [self.nonCachedImagesTableView reloadData];
}

#pragma mark UITableViewDataSource protocol implementation

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.coconuts count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath 
{
    return [CoconutTableViewCell cellForTableView:tableView];
}

#pragma mark UITableViewDelegate protocol implementation

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    CoconutTableViewCell *tableViewCell = (CoconutTableViewCell *)cell;
    
    Coconut *coconut = [self.coconuts objectAtIndex:indexPath.row];
    
    // We must use a customm cell here. If we try to use a standard cell style and its imageView property, refresh does
    // not work correctly. UITableViewCell implementation probably does some nasty things under the hood  
    if (coconut.thumbnailImageName) {
        NSURLRequest *request = nil;
        if (tableView == self.nonCachedImagesTableView) {
            request = [NSURLRequest requestWithURL:[[NSURL URLWithString:@"http://localhost:8087"] URLByAppendingPathComponent:coconut.thumbnailImageName]
                                       cachePolicy:NSURLRequestReloadIgnoringLocalCacheData
                                   timeoutInterval:HLSURLConnectionDefaultTimeout];
        }
        else {
            request = [NSURLRequest requestWithURL:[[NSURL URLWithString:@"http://localhost:8087"] URLByAppendingPathComponent:coconut.thumbnailImageName]
                                       cachePolicy:NSURLRequestReturnCacheDataElseLoad
                                   timeoutInterval:HLSURLConnectionDefaultTimeout];
            tableViewCell.thumbnailImageView.emptyImage = [UIImage imageNamed:@"img_image_placeholder.png"];
        }
        [tableViewCell.thumbnailImageView loadWithRequest:request];
    }
    else {
        [tableViewCell.thumbnailImageView loadWithRequest:nil];
    }
    tableViewCell.nameLabel.text = coconut.name;
    tableViewCell.thumbnailImageView.contentMode = UIViewContentModeScaleAspectFit;
    tableViewCell.selectionStyle = UITableViewCellSelectionStyleNone;
}

#pragma mark Event callbacks

- (IBAction)loadAsynchronously:(id)sender
{
    [self disableUserInterfaceForAsynchronousConnection];
    
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:@"http://localhost:8087/coconuts.plist"]
                                             cachePolicy:NSURLRequestReloadIgnoringLocalCacheData 
                                         timeoutInterval:HLSURLConnectionDefaultTimeout];
    self.asynchronousConnection = [HLSURLConnection connectionWithRequest:request];
    self.asynchronousConnection.tag = @"asynchronousConnection";
    self.asynchronousConnection.downloadFilePath = [HLSApplicationTemporaryDirectoryPath() stringByAppendingPathComponent:@"coconuts.plist"];
    self.asynchronousConnection.delegate = self;
    [self.asynchronousConnection start];
}

- (IBAction)loadAsynchronouslyNoCancel:(id)sender
{
    [self disableUserInterfaceForAsynchronousConnectionNoCancel];
    
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:@"http://localhost:8087/coconuts.plist"]
                                             cachePolicy:NSURLRequestReloadIgnoringLocalCacheData 
                                         timeoutInterval:HLSURLConnectionDefaultTimeout];
    
    // Does not need to keep any reference to the connection object
    HLSURLConnection *connection = [HLSURLConnection connectionWithRequest:request];
    connection.tag = @"asynchronousConnectionNoCancel";
    connection.downloadFilePath = [HLSApplicationTemporaryDirectoryPath() stringByAppendingPathComponent:@"coconuts.plist"];
    connection.delegate = self;
    [connection start];
}

- (IBAction)cancel:(id)sender
{    
    [self.asynchronousConnection cancel];
}

- (IBAction)loadSynchronously:(id)sender
{
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:@"http://localhost:8087/coconuts.plist"]
                                             cachePolicy:NSURLRequestReloadIgnoringLocalCacheData 
                                         timeoutInterval:HLSURLConnectionDefaultTimeout];
    HLSURLConnection *connection = [HLSURLConnection connectionWithRequest:request];
    connection.tag = @"synchronousConnection";
    connection.delegate = self;
    connection.downloadFilePath = [HLSApplicationTemporaryDirectoryPath() stringByAppendingPathComponent:@"coconuts.plist"];
    [connection startSynchronous];
}

- (IBAction)clear:(id)sender
{
    self.coconuts = nil;
    [self reloadData];
}

- (IBAction)testProgress:(id)sender
{
    self.progressTestButton.hidden = YES;
    self.progressView.hidden = NO;
    self.progressView.progress = 0.f;
    
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:@"http://localhost:8087/large_coconut.jpg"]
                                             cachePolicy:NSURLRequestReloadIgnoringLocalCacheData 
                                         timeoutInterval:HLSURLConnectionDefaultTimeout];
    
    HLSURLConnection *connection = [HLSURLConnection connectionWithRequest:request];
    connection.tag = @"httpGet";
    connection.delegate = self;
    [connection start];
}

- (IBAction)testHTTP404Error:(id)sender
{
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:@"http://localhost:8087/404_not_found.html"]
                                             cachePolicy:NSURLRequestReloadIgnoringLocalCacheData 
                                         timeoutInterval:HLSURLConnectionDefaultTimeout];
    HLSURLConnection *connection = [HLSURLConnection connectionWithRequest:request];
    connection.tag = @"http404";
    connection.treatingHTTPErrorsAsFailures = self.treatingHTTPErrorsAsFailuresSwitch.on;
    connection.delegate = self;
    [connection start];
}

@end
