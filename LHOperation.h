//
//  LHOperation.h
//  LastHistory
//
//  Created by Frederik Seiffert on 20.11.09.
//  Copyright 2009 Frederik Seiffert. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class LHDocument;


@interface LHOperation : NSOperation {
	LHDocument __weak *_document;
	NSManagedObjectContext *_context;
	
	NSString *_progressMessage;
	float _progress;
	BOOL _progressIndeterminate;
}

@property (readonly) LHDocument __weak *document;
@property (readonly) NSManagedObjectContext *context;

@property (retain) NSString *progressMessage;
@property (assign) float progress;
@property (assign) BOOL progressIndeterminate;

- (id)initWithDocument:(LHDocument *)document;

- (BOOL)saveContext;

@end
