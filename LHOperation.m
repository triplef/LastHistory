//
//  LHOperation.m
//  LastHistory
//
//  Created by Frederik Seiffert on 20.11.09.
//  Copyright 2009 Frederik Seiffert. All rights reserved.
//

#import "LHOperation.h"

#import "LHDocument.h"


@implementation LHOperation

@synthesize document=_document;
@synthesize context=_context;

@synthesize progressMessage=_progressMessage;
@synthesize progress=_progress;
@synthesize progressIndeterminate=_progressIndeterminate;


- (id)initWithDocument:(LHDocument *)document
{
	self = [super init];
	if (self != nil) {
		_document = document;
		
		// setup managed object context
		_context = [[NSManagedObjectContext alloc] init];
		[_context setPersistentStoreCoordinator:[[self.document managedObjectContext] persistentStoreCoordinator]];
		[_context setUndoManager:nil];
		
		
		[self addObserver:self forKeyPath:@"isExecuting" options:0 context:NULL];
		[self addObserver:self forKeyPath:@"isFinished" options:0 context:NULL];
		
		[[NSNotificationCenter defaultCenter] addObserver:self
												 selector:@selector(contextDidChange:)
													 name:NSManagedObjectContextDidSaveNotification
												   object:_context];
		
		self.progressIndeterminate = YES;
	}
	return self;
}

- (void)finalize
{
	[self removeObserver:self forKeyPath:@"isExecuting"];
	[self removeObserver:self forKeyPath:@"isFinished"];
	
	[super finalize];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
	if ([keyPath isEqualToString:@"isExecuting"] || [keyPath isEqualToString:@"isFinished"])
	{
		[self.document performSelectorOnMainThread:@selector(updateOperation:)
										withObject:self
									 waitUntilDone:NO];
	}
}

- (void)contextDidChange:(NSNotification *)notification 
{
	// merge changes with document context
	[_document performSelectorOnMainThread:@selector(mergeChanges:)
								withObject:notification
							 waitUntilDone:NO];
}

- (BOOL)saveContext
{
	NSError *error = nil;
	BOOL result = [_context save:&error];
	if (!result)
		[self.document presentError:error];
	
	return result;
}

- (void)process
{
	// perform task
}

- (void)main
{
	@try {
		[self process];
	}
	@catch (NSException *e) {
		NSLog(@"Error in %@: %@", [self className], e);
	}
}

@end
