//
//  LHAppDelegate.m
//  LastHistory
//
//  Created by Frederik Seiffert on 29.10.09.
//  Copyright 2009 Frederik Seiffert. All rights reserved.
//

#import "LHAppDelegate.h"

#import "LHDocument.h"
#import "LFWebService.h"


#define SURVEY_ASK				1
#define SURVEY_MIN_USAGE_TIME	10*60 // seconds
#define SURVEY_URL				@"http://www.frederikseiffert.de/lasthistory/survey"
#define SURVEY_ASKED_DEFAULT	@"SurveyAsked"

#define WEBSITE_URL				@"http://www.frederikseiffert.de/lasthistory"

#define LF_API_KEY @"fbc78d2f82dbb5f20ce6dff0dad331f1"
#define LF_SECRET @"4aa601de9f102d69361eeacd4c9632c7"

#define LF_DEFAULTS_USER_NAME @"LFUserName"
#define LF_DEFAULTS_SESSION_KEY @"LFSessionKey"


@implementation LHAppDelegate

@synthesize busy=_busy;

- (void)applicationWillFinishLaunching:(NSNotification *)aNotification
{
	_launchDate = [NSDate date];
	
	// register for document opening/closing notifications to show/hide welcome window
	NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
	[nc addObserver:self selector:@selector(documentWillOpen:) name:LHDocumentWillOpenNotification object:nil];
	[nc addObserver:self selector:@selector(closeWelcomeWindow:) name:LHDocumentDidOpenNotification object:nil];
	[nc addObserver:self selector:@selector(documentDidClose:) name:LHDocumentDidCloseNotification object:nil];
}

- (BOOL)applicationOpenUntitledFile:(NSApplication *)theApplication
{
	[self showWelcomeWindow:nil];
	return YES;
}

#if SURVEY_ASK
- (NSApplicationTerminateReply)applicationShouldTerminate:(NSApplication *)sender
{
	// ask about survey
	if (![[NSUserDefaults standardUserDefaults] boolForKey:SURVEY_ASKED_DEFAULT]
		&& [[NSDate date] timeIntervalSinceDate:_launchDate] >= SURVEY_MIN_USAGE_TIME)
	{
		NSInteger alertResult = NSRunInformationalAlertPanel(NSLocalizedString(@"LastHistory Usage Survey", nil),
															 NSLocalizedString(@"Thank you for using LastHistory. Being part of a research project, we would appreciate your feedback on the application.\n\nPlease take the time to fill out a short survey about your usage of the application. The survey will only take 5-10 minutes to complete.\n\nYou can also always go back to the survey at a later time from the \"LastHistory\" menu.\n", nil),
															 NSLocalizedString(@"Open Survey", nil),
															 NSLocalizedString(@"Later", nil),
															 nil);
		if (alertResult == NSAlertDefaultReturn) {
			[[NSUserDefaults standardUserDefaults] setBool:YES forKey:SURVEY_ASKED_DEFAULT];
			[self openSurvey:nil];
		}
	}
	
	return NSTerminateNow;
}
#endif

- (IBAction)openSurvey:(id)sender
{
	[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:SURVEY_URL]];
}

- (IBAction)openWebsite:(id)sender
{
	[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:WEBSITE_URL]];
}


- (NSMenu *)recentDocumentsMenu
{
	NSArray *recentDocuments = [[NSDocumentController sharedDocumentController] recentDocumentURLs];
	if (![recentDocuments count])
		return nil;
	
	NSMenu *menu = [[NSMenu allocWithZone:[NSMenu menuZone]] initWithTitle:@""];
	[menu addItemWithTitle:NSLocalizedString(@"Open Recent", nil) action:nil keyEquivalent:@""];
	
	// add recent documents
	for (NSURL *url in recentDocuments)
	{
		NSString *title = [[[url path] lastPathComponent] stringByDeletingPathExtension];
		NSMenuItem *recentItem = [menu addItemWithTitle:title action:@selector(openRecentItem:) keyEquivalent:@""];
		[recentItem setTarget:self];
		[recentItem setRepresentedObject:url];
		
		NSImage *icon = [[NSWorkspace sharedWorkspace] iconForFile:[url path]];
		if (icon) {
			[icon setSize:NSMakeSize(16, 16)];
			[recentItem setImage:icon];
		}
	}
	
	// add "open document" item
	[menu addItem:[NSMenuItem separatorItem]];
	NSMenuItem *openItem = [menu addItemWithTitle:NSLocalizedString(@"Open...", nil) action:@selector(openDocument:) keyEquivalent:@""];
	[openItem setTarget:[NSDocumentController sharedDocumentController]];
	
	return menu;
}

- (void)openRecentItem:(id)sender
{
	NSURL *url = [sender representedObject];
	NSError *error = nil;
	LHDocument *document = [[NSDocumentController sharedDocumentController] openDocumentWithContentsOfURL:url display:YES error:&error];
	if (!document)
		[NSApp presentError:error];
}

- (IBAction)showWelcomeWindow:(id)sender
{
	if (![welcomeWindow isVisible])
	{
		NSMenu *recentMenu = [self recentDocumentsMenu];
		[recentDocumentsButton setHidden:(recentMenu == nil)];
		if (recentMenu)
			[recentDocumentsButton setMenu:recentMenu];

		[welcomeWindow center];
		[welcomeWindow makeKeyAndOrderFront:nil];
	}
}

- (IBAction)closeWelcomeWindow:(id)sender
{
	NSInteger tag = [sender respondsToSelector:@selector(tag)] ? [sender tag] : -1;
	if (tag == 1)	// ok
	{
		self.busy = YES;
		
		NSString *username = [usernameField stringValue];
		
		// check Last.fm profile
		NSError *error = nil;
		if (![self lfCheckUsername:username error:&error]) {
			[NSApp presentError:error];
			goto fail;
		}
		
		// create document
		LHDocument *document = [[NSDocumentController sharedDocumentController] openUntitledDocumentAndDisplay:YES error:&error];
		if (!document) {
			[NSApp presentError:error];
			goto fail;
		} else {
			[document setUsername:username];
		}
	}
	else if (tag == 2)	// quit
	{
		[NSApp terminate:self];
	}
	
	[welcomeWindow close];
	
fail:
	self.busy = NO;
}

- (void)documentWillOpen:(NSNotification *)sender
{
	NSArray *documents = [[NSDocumentController sharedDocumentController] documents];
	if ([documents count] == 0)
		[self showWelcomeWindow:nil];
	
	self.busy = YES;
}

- (void)documentDidClose:(NSNotification *)sender
{
	NSArray *documents = [[NSDocumentController sharedDocumentController] documents];
	if ([documents count] == 0)
		[self showWelcomeWindow:nil];
}


- (IBAction)lfAuthenticate:(id)sender
{
	LFWebService *webService = self.lfWebService;
	
	if (!webService.isAuthenticated)
	{
		NSURL *authURL = [webService authenticateGetAuthorizationURL];
		if (authURL)
		{
			[[NSWorkspace sharedWorkspace] openURL:authURL];
			NSInteger alertResult = NSRunInformationalAlertPanel(NSLocalizedString(@"Last.fm Authentication in Progress...", nil),
																 NSLocalizedString(@"Please press \"Continue\" after authenticating on the Last.fm website.", nil),
																 NSLocalizedString(@"Continue", nil),
																 NSLocalizedString(@"Cancel", nil),
																 nil);
			if (alertResult == NSAlertDefaultReturn && [webService authenticateFinish])
			{
				// save session in user defaults
				NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
				[defaults setValue:webService.userName forKey:LF_DEFAULTS_USER_NAME];
				[defaults setValue:webService.sessionKey forKey:LF_DEFAULTS_SESSION_KEY];
			}
		}
	}
	else
	{
		NSInteger alertResult = NSRunInformationalAlertPanel(NSLocalizedString(@"Last.fm Authentication", nil),
															 NSLocalizedString(@"The application is already authenticated as \"%@\".", nil),
															 nil, NSLocalizedString(@"Delete Authentication", nil), nil,
															 webService.userName);
		if (alertResult == NSAlertAlternateReturn)
		{
			NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
			[defaults removeObjectForKey:LF_DEFAULTS_USER_NAME];
			[defaults removeObjectForKey:LF_DEFAULTS_SESSION_KEY];
		}
	}
}

- (LFWebService *)lfWebService
{
	if (!_lfWebService) {
		NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
		_lfWebService = [[LFWebService alloc] initWithApiKey:LF_API_KEY
													  secret:LF_SECRET
													userName:[defaults stringForKey:LF_DEFAULTS_USER_NAME]
												  sessionKey:[defaults stringForKey:LF_DEFAULTS_SESSION_KEY]];
	}
	
	return _lfWebService;
}

- (BOOL)lfCheckUsername:(NSString *)username error:(NSError **)outError
{
	LFWebService *webService = self.lfWebService;
	
	NSMutableDictionary *params = [NSMutableDictionary dictionaryWithCapacity:4];
	[params setValue:username forKey:@"user"];
	[params setValue:@"1" forKey:@"limit"];
	if (webService.userName)
		[params setObject:webService.userName forKey:@"username"];
	
	NSError *error = nil;
	if (![webService callMethod:@"user.getRecentTracks" withParameters:params error:&error])
	{
		if (outError)
			*outError = error;
		return NO;
	}
	
	return YES;
}

@end
