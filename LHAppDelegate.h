//
//  LHAppDelegate.h
//  LastHistory
//
//  Created by Frederik Seiffert on 29.10.09.
//  Copyright 2009 Frederik Seiffert. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class LFWebService;

@interface LHAppDelegate : NSObject {
	IBOutlet NSWindow *welcomeWindow;
	IBOutlet NSTextField *usernameField;
	IBOutlet NSPopUpButton *recentDocumentsButton;
	
	NSDate *_launchDate;
	BOOL _busy;
	LFWebService *_lfWebService;
}

@property (assign) BOOL busy;

@property (readonly) LFWebService *lfWebService;

- (IBAction)showWelcomeWindow:(id)sender;
- (IBAction)closeWelcomeWindow:(id)sender;

- (IBAction)openSurvey:(id)sender;
- (IBAction)openWebsite:(id)sender;

- (IBAction)lfAuthenticate:(id)sender;

- (BOOL)lfCheckUsername:(NSString *)username error:(NSError **)outError;

@end
