//
//  LHDocument.m
//  LastHistory
//
//  Created by Frederik Seiffert on 04.10.09.
//  Copyright Frederik Seiffert 2009 . All rights reserved.
//

#import "LHDocument.h"

#import "LHCommonMacros.h"
#import "LHAppDelegate.h"
#import "LHUser.h"
#import "LHTrack.h"
#import "LHArtist.h"
#import "LHTrackTag.h"
#import "LHTag.h"
#import "LHHistoryEntry.h"
#import "LHHistoryView.h"
#import "LHHistoryRetrievalOperation.h"
#import "LHWeightingOperation.h"
#import "LHTagRetrievalOperation.h"
#import "LHiTunesLibrary.h"
#import "NSDateFormatter-Extras.h"
#import "NSDate-Extras.h"


#define SEARCH_KEYS [NSArray arrayWithObjects:@"Any", @"Genre", @"Artist", @"Title", @"Album", @"Tags", nil]
#define SEARCH_KEY_MAPPING [NSDictionary dictionaryWithObjectsAndKeys: \
	@"track.genre LIKE[cd] %@", @"Genre", \
	@"track.artist.name CONTAINS[cd] %@", @"Artist", \
	@"track.name CONTAINS[cd] %@", @"Track", \
	@"track.album.name CONTAINS[cd] %@", @"Album", \
	@"ANY track.trackTags.tag.name LIKE[cd] %@", @"Tags",\
	nil]
#define INVERT_KEY @"NOT"

#define PLAYLIST_MAX_TRACKS 50


NSString *LHDocumentWillOpenNotification = @"LHDocumentWillOpenNotification";
NSString *LHDocumentDidOpenNotification = @"LHDocumentDidOpenNotification";
NSString *LHDocumentDidCloseNotification = @"LHDocumentDidCloseNotification";


@interface LHDocument (Player)
- (BOOL)historyEntryIsWithinCurrentEvent:(LHHistoryEntry *)historyEntry;
- (BOOL)loadHistoryEntry:(LHHistoryEntry *)historyEntry;
- (BOOL)loadNextAvailableHistoryEntryFromEntry:(LHHistoryEntry *)historyEntry ascending:(BOOL)ascending;
- (NSArray *)predicatesForEvent:(id <LHEvent>)event;
@end


@implementation LHDocument

@synthesize historyView;

@synthesize operationMode=_operationMode;
@synthesize chartsMode=_chartsMode;
@synthesize playlist=_playlist;

@synthesize currentHistoryEntry=_currentHistoryEntry;
@synthesize currentEvent=_currentEvent;
@synthesize currentSound=_currentSound;

@synthesize currentOperation=_currentOperation;


+ (NSSet *)keyPathsForValuesAffectingHistoryEntriesCount
{
	return [NSSet setWithObject:@"historyEntries"];
}

+ (NSSet *)keyPathsForValuesAffectingInfoString
{
	return [NSSet setWithObjects:@"historyEntries", @"visibleHistoryEntries", @"historyEntriesCount", nil];
}

- (id)init
{
	self = [super init];
	if (self != nil) {
		[[NSNotificationCenter defaultCenter] postNotificationName:LHDocumentWillOpenNotification object:self];
	}
	return self;
}

- (id)initWithType:(NSString *)typeName error:(NSError **)outError
{
	self = [super initWithType:typeName error:outError];
	if (self)
	{
		// make sure window is showing before calling action
		[self performSelector:@selector(loadHistory:) withObject:nil afterDelay:0];
	}
	return self;
}

- (void)setUsername:(NSString *)username
{
	if ([self countForEntity:@"User"] == 0)
	{
		// create a user
		LHUser *user = [LHUser insertInManagedObjectContext:[self managedObjectContext]];
		user.name = username;
	}
}


- (NSString *)displayName
{
	// use user name as default file name if document hasn't been saved yet
	if (![self fileURL])
	{
		LHUser *user = [[self objectsForEntity:@"User"] lastObject];
		if (user)
			return user.name;
	}
	
	return [super displayName];
}

- (NSString *)windowNibName 
{
	return @"LHDocument";
}

- (void)windowControllerDidLoadNib:(NSWindowController *)windowController 
{
	[super windowControllerDidLoadNib:windowController];
	
	// setup observers
	[self addObserver:self forKeyPath:@"operationMode" options:0 context:NULL];
	
	// setup history view
	[historyView windowControllerDidLoad];
	
	[[NSNotificationCenter defaultCenter] postNotificationName:LHDocumentDidOpenNotification object:self];
}

- (void)close
{
	[_queue cancelAllOperations];
	[self stop:nil];
	
	_firstHistoryEntry = nil;
	_lastHistoryEntry = nil;
	_cachedHistoryEntries = nil;
	_currentHistoryEntry = nil;
	_currentEvent = nil;
	_queue = nil;
	_currentOperation = nil;
	
	[super close];
	
	[[NSNotificationCenter defaultCenter] postNotificationName:LHDocumentDidCloseNotification object:self];
}

- (BOOL)ensureSavedDocumentBeforePerformingAction:(SEL)selector
{
	if ([[[[self managedObjectContext] persistentStoreCoordinator] persistentStores] count] == 0) {
		[self saveDocumentWithDelegate:self didSaveSelector:@selector(document:didSave:contextInfo:) contextInfo:selector];
		return NO;
	}
	
	return YES;
}

- (void)document:(NSDocument *)doc didSave:(BOOL)didSave contextInfo:(void *)contextInfo
{
	if (didSave) {
		[self performSelector:contextInfo withObject:nil afterDelay:0];
	} else {
		[self close];
	}
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
	if ([keyPath isEqualToString:@"operationMode"])
	{
		// setup view according to operation mode
		switch (self.operationMode) {
			case 0: // Analysis
				self.chartsMode = NO;
				historyView.showHistoryEntryWeights = NO;
				historyView.showReferenceStreams = NO;
				[historyView scrollToDate:self.firstHistoryEntry.timestamp];
				break;
			case 1: // Personal
				self.chartsMode = YES;
				historyView.showHistoryEntryWeights = YES;
				historyView.showReferenceStreams = YES;
				[historyView scrollToDate:self.lastHistoryEntry.timestamp];
				break;
		}
	}
}

- (void)runOperation:(LHOperation *)op
{
	if (!_queue)
		_queue = [[NSOperationQueue alloc] init];
	[_queue addOperation:op];
}

- (void)updateOperation:(LHOperation *)op
{
	if ([op isExecuting])
	{
		self.currentOperation = op;
	}
	else if ([op isFinished])
	{
		if (![op isCancelled])
		{
			// save file again so document is in sync with file
			NSError *error = nil;
			if (![self saveToURL:[self fileURL] ofType:[self fileType] forSaveOperation:NSSaveOperation error:&error])
				[self presentError:error];
		}
		
		if (op == self.currentOperation)
			self.currentOperation = nil;
	}
}

// called by LHOperations to merge changes from their context
- (void)mergeChanges:(NSNotification *)notification
{
	NSAssert([NSThread mainThread], @"Not on the main thread");
	
	if ([notification object] != [self managedObjectContext]
		&& [[[notification object] class] isEqual:[NSManagedObjectContext class]]) // ignore changes from CalManagedObjectContext
	{
		NSSet *insertedObjects = [[notification userInfo] objectForKey:NSInsertedObjectsKey];
		BOOL didInsertHistoryEntries = [[insertedObjects valueForKey:@"class"] containsObject:[LHHistoryEntry class]];
		BOOL isFirstHistoryEntry = didInsertHistoryEntries && _firstHistoryEntry == nil;
		
		// inserting the first history entry causes historyEntries to update
		// subsequent inserts only update historyEntriesCount
		if (isFirstHistoryEntry)
			[self willChangeValueForKey:@"historyEntries"];
		else if (didInsertHistoryEntries)
			[self willChangeValueForKey:@"historyEntriesCount"];
		// merge changes from other thread
		[[self managedObjectContext] mergeChangesFromContextDidSaveNotification:notification];
		if (isFirstHistoryEntry)
			[self didChangeValueForKey:@"historyEntries"];
		else if (didInsertHistoryEntries)
			[self didChangeValueForKey:@"historyEntriesCount"];
		
		// insert history entries
		if (!isFirstHistoryEntry && didInsertHistoryEntries) {
			_cachedHistoryEntries = nil;
			[historyView insertObjectsWithIDs:[insertedObjects valueForKey:@"objectID"]];
		}
		
		// update view
		NSSet *updatedObjectIDs = [[[notification userInfo] objectForKey:NSUpdatedObjectsKey] valueForKey:@"objectID"];
		[historyView updateObjectsWithIDs:updatedObjectIDs];
	}
}

- (NSArray *)objectsForEntity:(NSString *)entityName
				withPredicate:(NSPredicate *)predicate
				   fetchLimit:(NSUInteger)fetchLimit
					ascending:(BOOL)ascending
					inContext:(NSManagedObjectContext *)context
{
	NSFetchRequest *request = [NSFetchRequest new];
	NSEntityDescription *entity = [NSEntityDescription entityForName:entityName inManagedObjectContext:context];
	[request setEntity:entity];
	[request setPredicate:predicate];
	[request setFetchLimit:fetchLimit];
	
	// fetch all relationships for history entries
	if ([entityName isEqualToString:@"HistoryEntry"])
		[request setRelationshipKeyPathsForPrefetching:[NSArray arrayWithObject:@"track.trackTags.tag"]];
	
	// sort depending on entity
	NSDictionary *sortKeysByEntityName = [NSDictionary dictionaryWithObjectsAndKeys:
										  @"timestamp", @"HistoryEntry",
										  @"count", @"TrackTag", nil];
	NSString *sortKey = [sortKeysByEntityName objectForKey:entityName];
	if (sortKey) {
		NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:sortKey ascending:ascending];
		[request setSortDescriptors:[NSArray arrayWithObject:sortDescriptor]];
	}
	
	NSError *error = nil;
	NSArray *result = [context executeFetchRequest:request error:&error];
	if (error)
		[self presentError:error];
	
	return result;
}

- (NSArray *)objectsForEntity:(NSString *)entityName
{
	return [self objectsForEntity:entityName withPredicate:nil fetchLimit:0 ascending:YES inContext:[self managedObjectContext]];
}

- (NSUInteger)countForEntity:(NSString *)entityName
			   withPredicate:(NSPredicate *)predicate
				   inContext:(NSManagedObjectContext *)context
{
	NSFetchRequest *request = [NSFetchRequest new];
	NSEntityDescription *entity = [NSEntityDescription entityForName:entityName inManagedObjectContext:context];
	[request setEntity:entity];
	[request setPredicate:predicate];
	
	NSError *error;
	return [context countForFetchRequest:request error:&error];
}

- (NSUInteger)countForEntity:(NSString *)entityName
{
	return [self countForEntity:entityName withPredicate:nil inContext:[self managedObjectContext]];
}

- (NSString *)infoString
{
	NSUInteger historyEntriesCount = self.historyEntriesCount;
	NSUInteger tracksCount = self.tracksCount;
	
	if (_hiddenHistoryEntriesCount > 0)
	{
		NSUInteger visibleHistoryEntriesCount = historyEntriesCount - _hiddenHistoryEntriesCount;
		NSUInteger visibleTracksCount = tracksCount - _hiddenTracksCount;
		float historyEntriesPercent = historyEntriesCount > 0 ? (float)visibleHistoryEntriesCount / historyEntriesCount : 0.0;
		float tracksPercent = tracksCount > 0 ? (float)visibleTracksCount / tracksCount : 0.0;
		
		return [NSString stringWithFormat:@"%u of %u history entries (%.2f%%), %u of %u tracks (%.2f%%)",
				visibleHistoryEntriesCount, historyEntriesCount, historyEntriesPercent*100,
				visibleTracksCount, tracksCount, tracksPercent*100];
	}
	else
	{
		return [NSString stringWithFormat:@"%u history entries, %u tracks",
				historyEntriesCount, tracksCount];
	}
}

- (NSArray *)tracks
{
	return [self objectsForEntity:@"Track"];
}

- (NSUInteger)tracksCount
{
	return [self countForEntity:@"Track"];
}

- (NSArray *)historyEntries
{
	if (!_cachedHistoryEntries)
	{
		// result includes all relationships and can take up to multiple seconds to fetch
		LHLog(@"Fetching history entries...");
		_cachedHistoryEntries = [self objectsForEntity:@"HistoryEntry"];
		_hiddenHistoryEntriesCount = 0;
		_hiddenTracksCount = 0;
	}
	
	return _cachedHistoryEntries;
}

- (NSUInteger)historyEntriesCount
{
	return [self countForEntity:@"HistoryEntry"];
}

- (NSArray *)visibleHistoryEntries
{
	NSLog(@"visibleHistoryEntries");
	// this value is just for key-value observing when the "hidden" property of some history entries changes
	return nil;
}

- (LHHistoryEntry *)firstHistoryEntry
{
	if (!_firstHistoryEntry)
		_firstHistoryEntry = [[self objectsForEntity:@"HistoryEntry" withPredicate:nil fetchLimit:1 ascending:YES inContext:[self managedObjectContext]] lastObject];
	
	return _firstHistoryEntry;
}

- (LHHistoryEntry *)lastHistoryEntry
{
	if (!_lastHistoryEntry)
		_lastHistoryEntry = [[self objectsForEntity:@"HistoryEntry" withPredicate:nil fetchLimit:1 ascending:NO inContext:[self managedObjectContext]] lastObject];
	
	return _lastHistoryEntry;
}


#pragma mark -
#pragma mark Searching

- (NSArray *)tokenField:(NSTokenField *)tokenField completionsForSubstring:(NSString *)substring indexOfToken:(NSInteger)tokenIndex indexOfSelectedItem:(NSInteger *)selectedIndex
{
	NSMutableArray *result = [NSMutableArray arrayWithCapacity:5];
	NSPredicate *prefixPredicate = [NSPredicate predicateWithFormat:@"SELF BEGINSWITH[cd] %@", substring];
	
	// check genres
	[result addObject:[[LHTrack genres] filteredArrayUsingPredicate:prefixPredicate]];
	
	// check weekdays/months
	NSDateFormatter *formatter = [NSDateFormatter new];
	[formatter setLocale:[NSLocale currentLocale]];
	[result addObject:[[formatter standaloneWeekdaySymbols] filteredArrayUsingPredicate:prefixPredicate]];
	[result addObject:[[formatter standaloneMonthSymbols] filteredArrayUsingPredicate:prefixPredicate]];
	
	// check tags/artists
	NSPredicate *entityPredicate = [NSPredicate predicateWithFormat:@"name BEGINSWITH[cd] %@", substring];
	[result addObject:[[self objectsForEntity:@"Tag" withPredicate:entityPredicate fetchLimit:10 ascending:YES inContext:[self managedObjectContext]] valueForKey:@"name"]];
	[result addObject:[[self objectsForEntity:@"Artist" withPredicate:entityPredicate fetchLimit:10 ascending:YES inContext:[self managedObjectContext]] valueForKey:@"name"]];
	
	return [result valueForKeyPath:@"@distinctUnionOfArrays.self"];
}

- (id)tokenField:(NSTokenField *)tokenField representedObjectForEditingString:(NSString *)token
{
	NSDateFormatter *formatter = [NSDateFormatter new];
	[formatter setLocale:[NSLocale currentLocale]];
	
	NSMutableDictionary *result = [NSMutableDictionary dictionaryWithCapacity:5];
	
	if ([token hasPrefix:@"-"]) {
		// minus prefix => NOT
		token = [[token substringFromIndex:1] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
		[result setObject:[NSNumber numberWithBool:YES] forKey:@"invert"];
	}
	
	[result setObject:token forKey:@"token"];
	[result setObject:[SEARCH_KEYS objectAtIndex:0] forKey:@"searchKey"]; // default search key: Any
	
	// range specified?
	NSString *firstToken = token, *lastToken = token;
	NSArray *rangeTokens = [token componentsSeparatedByString:@"-"];
	if ([rangeTokens count] == 2) {
		firstToken = [rangeTokens objectAtIndex:0];
		lastToken = [rangeTokens objectAtIndex:1];
	}
	
	NSInteger start, end;
	if ([[NSScanner scannerWithString:firstToken] scanInteger:&start]
		&& [[NSScanner scannerWithString:lastToken] scanInteger:&end]
		&& start >= 0 && end >= 0 && end >= start)
	{
		[result setObject:[NSNumber numberWithInteger:start] forKey:@"start"];
		[result setObject:[NSNumber numberWithInteger:end] forKey:@"end"];
		
		// check year
		NSInteger startYear = [[formatter twoDigitStartDate] year];
		NSInteger endYear = [[NSDate date] year]+1;
		if (start >= startYear && start <= endYear && end >= startYear && end <= endYear)
		{
			[result setObject:@"year" forKey:@"key"];
			return result;
		}
		
		// check time
		if (start <= 24 && end <= 24)
		{
			[result setObject:@"hour" forKey:@"key"];
			return result;
		}
	}
	
	// check weekday
	start = [formatter weekdayForString:firstToken];
	end = [formatter weekdayForString:lastToken];
	if (start != NSNotFound && end != NSNotFound)
	{
		[result setObject:[NSNumber numberWithInteger:start] forKey:@"start"];
		[result setObject:[NSNumber numberWithInteger:end] forKey:@"end"];
		[result setObject:@"weekday" forKey:@"key"];
		[result setObject:[NSNumber numberWithInteger:7] forKey:@"ordinality"];
		return result;
	}
	
	// check month
	start = [formatter monthForString:firstToken];
	end = [formatter monthForString:lastToken];
	if (start != NSNotFound && end != NSNotFound)
	{
		[result setObject:[NSNumber numberWithInteger:start] forKey:@"start"];
		[result setObject:[NSNumber numberWithInteger:end] forKey:@"end"];
		[result setObject:@"month" forKey:@"key"];
		[result setObject:[NSNumber numberWithInteger:12] forKey:@"ordinality"];
		return result;
	}
	
	return result;
}

- (NSString *)tokenField:(NSTokenField *)tokenField displayStringForRepresentedObject:(id)token
{
	NSString *result = nil;
	
	if ([token objectForKey:@"start"] && [token objectForKey:@"end"])
	{
		// range token
		NSString *key = [token objectForKey:@"key"];
		NSInteger start = [[token objectForKey:@"start"] integerValue];
		NSInteger end = [[token objectForKey:@"end"] integerValue];
		
		if ([token objectForKey:@"ordinality"])
		{
			// weekday or month range
			NSDateFormatter *formatter = [NSDateFormatter new];
			SEL symbolsSelector = NSSelectorFromString([NSString stringWithFormat:@"shortStandalone%@Symbols", [key capitalizedString]]);
			if ([formatter respondsToSelector:symbolsSelector])
			{
				NSArray *symbols = [formatter performSelector:symbolsSelector];
				if (start != end)
					result = [NSString stringWithFormat:@"%@-%@", [symbols objectAtIndex:start-1], [symbols objectAtIndex:end-1]];
				else
					result = [symbols objectAtIndex:start-1];
			}
		}
		else
		{
			// number (hour or year) range
			NSDictionary *suffixes = [NSDictionary dictionaryWithObjectsAndKeys:@"h", @"hour", @"", @"year", nil];
			NSString *suffix = [suffixes objectForKey:key];
			if (!suffix)
				suffix = @"";
			
			if (start != end)
				result = [NSString stringWithFormat:@"%d%@-%d%@", start, suffix, end, suffix];
			else
				result = [NSString stringWithFormat:@"%d%@", start, suffix];
		}
	}
	
	if (!result)
		result = [token objectForKey:@"token"];
	
	NSString *searchKey = [token objectForKey:@"searchKey"];
	if (searchKey && ![searchKey isEqualToString:[SEARCH_KEYS objectAtIndex:0]])
		result = [NSString stringWithFormat:@"%@[%@]", result, [searchKey uppercaseString]];
	
	if ([[token objectForKey:@"invert"] boolValue])
		result = [NSString stringWithFormat:@"NOT %@", result];
	
	[tokenField performSelector:@selector(setNeedsDisplay) withObject:nil afterDelay:0];
	
	return result;
}

- (NSString *)tokenField:(NSTokenField *)tokenField editingStringForRepresentedObject:(id)token
{
	return [token objectForKey:@"token"];
}

- (BOOL)tokenField:(NSTokenField *)tokenField hasMenuForRepresentedObject:(id)token
{
	return YES;
}

- (NSMenu *)tokenField:(NSTokenField *)tokenField menuForRepresentedObject:(id)token
{
	if (!token)
		return nil;
	
	NSMenu *menu = [NSMenu new];
	[menu setAutoenablesItems:NO];
	
	if (!([token objectForKey:@"start"] && [token objectForKey:@"end"]))
	{
		// add search key items
		NSString *searchKey = [token objectForKey:@"searchKey"];
		NSArray *searchKeys = SEARCH_KEYS;
		for (NSString *key in searchKeys)
		{
			NSMenuItem *item = [menu addItemWithTitle:key action:@selector(tokenFieldMenuAction:) keyEquivalent:@""];
			[item setTarget:self];
			[item setRepresentedObject:token];
			
			if ([key isEqualToString:searchKey]) {
				[item setState:NSOnState];
			} else if ([key isEqualToString:@"Genre"] && ![[LHTrack genres] containsObject:[[token objectForKey:@"token"] lowercaseString]]) {
				// disable Genre item if token is not a valid genre
				[item setEnabled:NO];
			}
			
			if ([key isEqualToString:[searchKeys objectAtIndex:0]])
				[menu addItem:[NSMenuItem separatorItem]];
		}
		
		[menu addItem:[NSMenuItem separatorItem]];
	}
	
	// add NOT item
	NSMenuItem *item = [menu addItemWithTitle:INVERT_KEY action:@selector(tokenFieldMenuAction:) keyEquivalent:@""];
	[item setTarget:self];
	[item setRepresentedObject:token];
	
	if ([[token objectForKey:@"invert"] boolValue])
		[item setState:NSOnState];
	
	return menu;
}

- (void)tokenFieldMenuAction:(id)sender
{
	NSMenuItem *item = sender;
	NSMutableDictionary *token = [item representedObject];
	
	if ([[item title] isEqualToString:INVERT_KEY])
	{
		[token setObject:[NSNumber numberWithBool:![item state]] forKey:@"invert"];
	}
	else
	{
		[token setObject:[item title] forKey:@"searchKey"];
	}
	
	// this updates the display string for the tokens
	[[searchField window] makeFirstResponder:searchField];
}

- (NSPredicate *)predicateForToken:(NSDictionary *)token format:(NSString *)format, ...
{
	va_list ap;
	va_start(ap, format);
	NSPredicate *predicate = [NSPredicate predicateWithFormat:format arguments:ap];
	va_end(ap);
	
	if ([[token objectForKey:@"invert"] boolValue])
		predicate = [NSCompoundPredicate notPredicateWithSubpredicate:predicate];
	
	return predicate;
}

- (IBAction)updateFilter:(id)sender
{
	NSMutableArray *orPredicates = [NSMutableArray array];
	NSMutableArray *andPredicates = [NSMutableArray array];
	
	NSArray *searchTokens = [searchField objectValue];
	for (NSDictionary *token in searchTokens)
	{
		NSString *key = [token objectForKey:@"key"];
		NSNumber *start = [token objectForKey:@"start"];
		NSNumber *end = [token objectForKey:@"end"];
		
		if (key && start && end)
		{
			if ([token objectForKey:@"ordinality"])
			{
				// search discrete value range (weekday, month)
				NSInteger ordinality = [[token objectForKey:@"ordinality"] integerValue];
				NSMutableArray *subpredicates = [NSMutableArray arrayWithCapacity:ordinality];
				
				NSUInteger index = [start integerValue]-1;
				while (1) {
					NSString *format = [NSString stringWithFormat:@"%@ = %%d", key];
					[subpredicates addObject:[NSPredicate predicateWithFormat:format, index+1]];
					if (index+1 == [end integerValue])
						break;
					index = ++index % ordinality;
				}
				
				NSPredicate *predicate = [NSCompoundPredicate orPredicateWithSubpredicates:subpredicates];
				if ([[token objectForKey:@"invert"] boolValue])
					predicate = [NSCompoundPredicate notPredicateWithSubpredicate:predicate];
				[orPredicates addObject:predicate];
			}
			else
			{
				// search range
				NSString *format = [NSString stringWithFormat:@"%@ >= %%d AND %@ <= %%d", key, key];
				NSPredicate *p = [self predicateForToken:token format:format, [start intValue], [end intValue]];
				[orPredicates addObject:p];
			}
		}
		else
		{
			// search title/artist
			NSDictionary *searchKeyMapping = SEARCH_KEY_MAPPING;
			NSString *searchExpression = [searchKeyMapping objectForKey:[token objectForKey:@"searchKey"]];
			NSString *searchString = [token objectForKey:@"token"];
			
			if (searchExpression) {
				// search selected key
				NSPredicate *p = [self predicateForToken:token format:searchExpression, searchString];
				[andPredicates addObject:p];
			} else {
				// search all keys
				NSMutableArray *subpredicates = [NSMutableArray arrayWithCapacity:[searchKeyMapping count]];
				for (NSString *key in SEARCH_KEYS) {
					searchExpression = [searchKeyMapping objectForKey:key];
					if (searchExpression)
						[subpredicates addObject:[NSPredicate predicateWithFormat:searchExpression, searchString]];
				}
				
				NSPredicate *predicate = [NSCompoundPredicate orPredicateWithSubpredicates:subpredicates];
				if ([[token objectForKey:@"invert"] boolValue])
					predicate = [NSCompoundPredicate notPredicateWithSubpredicate:predicate];
				[andPredicates addObject:predicate];
			}
		}
	}
	
	// integrate or-parts into predicate strings
	if ([orPredicates count]) {
		NSPredicate *predicate = [NSCompoundPredicate orPredicateWithSubpredicates:orPredicates];
		[andPredicates insertObject:predicate atIndex:0];
	}
	
	NSPredicate *filter = nil;
	if ([andPredicates count]) {
		filter = [NSCompoundPredicate andPredicateWithSubpredicates:andPredicates];
		NSLog(@"filter: %@", filter);
	}
	
	[self willChangeValueForKey:@"visibleHistoryEntries"];
	
	// apply filter
	_hiddenHistoryEntriesCount = 0;
	for (LHHistoryEntry *historyEntry in self.historyEntries) {
		BOOL hidden = filter ? ![filter evaluateWithObject:historyEntry] : NO;
		historyEntry.hidden = hidden;
		if (hidden)
			_hiddenHistoryEntriesCount++;
	}

	// calculate number of visible tracks
	NSPredicate *hiddenTracksPredicate = [NSPredicate predicateWithFormat:@"ANY historyEntries.hidden = YES"];
	_hiddenTracksCount = [[self.tracks filteredArrayUsingPredicate:hiddenTracksPredicate] count];
	
	[self didChangeValueForKey:@"visibleHistoryEntries"];
	
	// un-focus search field
	[[searchField window] makeFirstResponder:nil];
}


#pragma mark -
#pragma mark Actions

- (void)performFindPanelAction:(id)sender
{
	[[searchField window] makeFirstResponder:searchField];
}

- (IBAction)toggleFullScreenMode:(id)sender
{
	if ([historyView isInFullScreenMode])
		[historyView exitFullScreenModeWithOptions:nil];
	else
		[historyView enterFullScreenMode:[NSScreen mainScreen]
							 withOptions:[NSDictionary dictionaryWithObjectsAndKeys:
										  [NSNumber numberWithBool:NO], NSFullScreenModeAllScreens,
										  nil]];
}

- (IBAction)showTrackIniTunes:(id)sender
{
	LHTrack *track = self.currentHistoryEntry.track;
	LHiTunesLibrary *library = [LHiTunesLibrary defaultLibrary];
	NSDictionary *iTunesTrackDict = [library trackForTrack:track.name artist:track.artist.name];
	[library revealTrack:iTunesTrackDict];
}

- (IBAction)createPlaylistIniTunes:(id)sender
{
	if ([self.playlist count] > 0)
	{
		[NSApp beginSheet:playlistNameSheet
		   modalForWindow:[self windowForSheet]
			modalDelegate:self
		   didEndSelector:nil
			  contextInfo:nil];
	}
}

- (IBAction)closePlaylistNameSheet:(id)sender
{
	if ([sender tag] == 1)
	{
		NSString *playlistName = [playlistNameField stringValue];
		if ([playlistName length] > 0)
		{
			LHiTunesLibrary *library = [LHiTunesLibrary defaultLibrary];
			
			NSMutableArray *playlistTracks = [NSMutableArray arrayWithCapacity:[self.playlist count]];
			for (LHTrack *track in self.playlist)
			{
				NSDictionary *iTunesTrackDict = [library trackForTrack:track.name artist:track.artist.name];
				if (iTunesTrackDict)
					[playlistTracks addObject:iTunesTrackDict];
			}
			
			[library createPlaylist:playlistName withTracks:playlistTracks];
		}
		else
		{
			NSRunAlertPanel(@"Invalid playlist name", @"Please enter a valid playlist name", nil, nil, nil);
			return;
		}
	}
	
	[NSApp endSheet:playlistNameSheet];
	[playlistNameSheet orderOut:nil];
}

- (IBAction)stop:(id)sender
{
	if (self.currentHistoryEntry)
	{
		[self.currentSound stop];
		self.currentSound = nil;
		self.currentHistoryEntry = nil;
		self.currentEvent = nil;
	}
}

- (IBAction)pause:(id)sender
{
	if (_currentSoundIsPaused)
		_currentSoundIsPaused = ![self.currentSound resume];
	else
		_currentSoundIsPaused = [self.currentSound pause];
}

- (IBAction)skipBackwards:(id)sender
{
	[self loadNextAvailableHistoryEntryFromEntry:self.currentHistoryEntry ascending:NO];
}

- (IBAction)skipForward:(id)sender
{
	[self loadNextAvailableHistoryEntryFromEntry:self.currentHistoryEntry ascending:YES];
}

- (BOOL)playHistoryEntry:(LHHistoryEntry *)historyEntry
{
	// reset current event if track is not within
	if (![self historyEntryIsWithinCurrentEvent:historyEntry])
		self.currentEvent = nil;
	
	self.playlist = nil; // reset playlist
	
	return [self loadHistoryEntry:historyEntry];
}

- (BOOL)playHistoryEntriesForEvent:(id <LHEvent>)event
{
	self.currentEvent = event;
	self.playlist = nil; // reset playlist
	
	return [self loadNextAvailableHistoryEntryFromEntry:nil ascending:YES];
}

- (NSUInteger)numberOfHistoryEntriesForEvent:(id <LHEvent>)event
{
	NSArray *subpredicates = [self predicatesForEvent:event];
	NSPredicate *predicate = [NSCompoundPredicate andPredicateWithSubpredicates:subpredicates];
	
	return [self countForEntity:@"HistoryEntry" withPredicate:predicate inContext:[self managedObjectContext]];
}


#pragma mark -
#pragma mark History Loading

- (void)loadHistoryForUser:(NSString *)username
{
	LHHistoryRetrievalOperation *operation = [[LHHistoryRetrievalOperation alloc] initWithDocument:self
																					   andUsername:username];
	[self runOperation:operation];
	
	// add weighting and tag retrieval operations
	LHWeightingOperation *weightingOperation = [[LHWeightingOperation alloc] initWithDocument:self];
	[weightingOperation addDependency:operation];
	[self runOperation:weightingOperation];
	
	LHTagRetrievalOperation *tagRetrievalOperation = [[LHTagRetrievalOperation alloc] initWithDocument:self];
	[tagRetrievalOperation addDependency:weightingOperation];
	[self runOperation:tagRetrievalOperation];
}

- (IBAction)loadHistory:(id)sender
{
	if (![self ensureSavedDocumentBeforePerformingAction:@selector(loadHistory:)])
		return;
	
	LHUser *user = [[self objectsForEntity:@"User"] lastObject];
	if (user.name.length > 0) {
		[self loadHistoryForUser:user.name];
	} else {
		[NSApp beginSheet:usernameSheet
		   modalForWindow:[self windowForSheet]
			modalDelegate:self
		   didEndSelector:nil
			  contextInfo:nil];
	}
}

- (IBAction)closeUsernameSheet:(id)sender
{
	if ([sender tag] == 1)
	{
		NSString *username = [usernameField stringValue];
		if ([username length] > 0) {
			[self loadHistoryForUser:username];
		} else {
			NSRunAlertPanel(@"Invalid username", @"Please enter a valid username", nil, nil, nil);
			return;
		}
	}
	
	[NSApp endSheet:usernameSheet];
	[usernameSheet orderOut:nil];
}


#pragma mark -
#pragma mark Last.fm Tag Loading

- (IBAction)retrieveTags:(id)sender
{
	if (![self ensureSavedDocumentBeforePerformingAction:@selector(retrieveTags:)])
		return;
	
	LHTagRetrievalOperation *tagRetrievalOperation = [[LHTagRetrievalOperation alloc] initWithDocument:self];
	[self runOperation:tagRetrievalOperation];
}

- (IBAction)showTopTags:(id)sender
{
	NSArray *tags = [self objectsForEntity:@"Tag" withPredicate:nil fetchLimit:0 ascending:NO inContext:[self managedObjectContext]];
	NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"countSum" ascending:NO];
	NSArray *sortedTags = [tags sortedArrayUsingDescriptors:[NSArray arrayWithObject:sortDescriptor]];
	
	for (LHTag *tag in [sortedTags subarrayWithRange:NSMakeRange(0, 100)])
	{
		NSLog(@"%u: %@", tag.countSum, tag.name);
	}
}

@end


#pragma mark -
@implementation LHDocument (Player)

- (BOOL)historyEntryIsWithinCurrentEvent:(LHHistoryEntry *)historyEntry
{
	BOOL withinDate = [self.currentEvent.eventStart compare:historyEntry.timestamp] == NSOrderedAscending && [self.currentEvent.eventEnd compare:historyEntry.timestamp] == NSOrderedDescending;
	BOOL withinTime = self.currentEvent.eventStartTime <= historyEntry.timeValue && self.currentEvent.eventEndTime >= historyEntry.timeValue;
	
	if (!self.currentEvent)
		return YES;
	else if (self.currentEvent.eventStart && self.currentEvent.eventEnd && self.currentEvent.eventStartTime != LH_EVENT_TIME_UNDEFINED && self.currentEvent.eventEndTime != LH_EVENT_TIME_UNDEFINED)
		return withinDate && withinTime;
	else if (self.currentEvent.eventStart && self.currentEvent.eventEnd)
		return withinDate;
	else if (self.currentEvent.eventStartTime && self.currentEvent.eventEndTime)
		return withinTime;
	else
		return NO;
}

- (BOOL)loadHistoryEntry:(LHHistoryEntry *)historyEntry
{
	// play track from iTunes
	LHTrack *track = historyEntry.track;
	NSDictionary *iTunesTrack = [[LHiTunesLibrary defaultLibrary] trackForTrack:track.name
																		 artist:track.artist.name];
	if (iTunesTrack)
	{
		if ([[iTunesTrack objectForKey:@"Protected"] boolValue]) {
			// skip DRM-protected songs
			return NO;
		}
		
		NSFileManager *fileManager = [NSFileManager defaultManager];
		NSURL *location = [NSURL URLWithString:[iTunesTrack objectForKey:@"Location"]];
		if (location && [fileManager fileExistsAtPath:[location path]])
		{
			NSSound *sound = [[NSSound alloc] initWithContentsOfURL:location byReference:YES];
			if (sound) {
				[self.currentSound stop];
				
				NSString *artist = [iTunesTrack objectForKey:@"Artist"];
				NSString *name = [iTunesTrack objectForKey:@"Name"];
				[sound setName:(artist && name) ? [NSString stringWithFormat:@"%@ - %@", artist, name] : name];
				[sound setDelegate:self];
				[sound play];
				self.currentHistoryEntry = historyEntry;
				self.currentSound = sound;
				_currentSoundIsPaused = NO;
			} else {
				NSLog(@"Error: Failed to load '%@'.", location);
				return NO;
			}
		}
		else
		{
			NSLog(@"Error: Invalid track location in iTunes library for '%@'.", historyEntry.track.trackID);
			return NO;
		}
	}
	else if (historyEntry)
	{
//		NSLog(@"Error: Unable to find track in iTunes library '%@'.", historyEntry.track.trackID);
		return NO;
	}
	
	// create playlist
	if (!self.playlist)
	{
		NSArray *entries = [self objectsForEntity:@"HistoryEntry"
									withPredicate:[NSPredicate predicateWithFormat:@"timestamp >= %@", historyEntry.timestamp]
									   fetchLimit:PLAYLIST_MAX_TRACKS
										ascending:YES
										inContext:[self managedObjectContext]];
		self.playlist = [entries valueForKey:@"track"];
	}
	
	return YES;
}

- (BOOL)loadNextAvailableHistoryEntryFromEntry:(LHHistoryEntry *)historyEntry ascending:(BOOL)ascending
{
	// always play in direction of timeline
	if (historyView.flipTimeline && !self.chartsMode)
		ascending = !ascending;
	
	BOOL chartsMode = self.chartsMode && self.currentEvent;
	NSArray *currentEventPredicates = [self predicatesForEvent:self.currentEvent];
	
	// find next history entry, skipping over failing tracks, and stopping if not within current event (if set)
	NSUInteger tries = 0;
	do
	{
		NSMutableArray *subpredicates = [NSMutableArray arrayWithCapacity:3];
		if (historyEntry && !chartsMode)
		{
			// entry has to be later/earlier than current entry
			NSPredicate *predicate = [NSPredicate predicateWithFormat:[NSString stringWithFormat:@"timestamp %@ %%@", ascending ? @">" : @"<"], historyEntry.timestamp];
			[subpredicates addObject:predicate];
		}
		if (currentEventPredicates)
			[subpredicates addObjectsFromArray:currentEventPredicates];
		
		NSPredicate *predicate = [NSCompoundPredicate andPredicateWithSubpredicates:subpredicates];
		NSArray *entries = nil;
		
		if (!chartsMode || !self.playlist) {
			// fetch entries
			entries = [self objectsForEntity:@"HistoryEntry"
							   withPredicate:predicate
								  fetchLimit:chartsMode ? 0 : PLAYLIST_MAX_TRACKS
								   ascending:ascending
								   inContext:[self managedObjectContext]];
		}
		
		// save playlist
		if (!self.playlist)
		{
			NSArray *playlist = nil;
			
			if (chartsMode)
			{
				// get tracks with counts
				NSCountedSet *tracks = [[NSCountedSet alloc] initWithArray:[entries valueForKey:@"track"]];
				NSMutableArray *intermediatePlaylist = [NSMutableArray arrayWithCapacity:[tracks count]];
				for (LHTrack *track in tracks) {
					NSUInteger count = [tracks countForObject:track];
					[intermediatePlaylist addObject:[NSDictionary dictionaryWithObjectsAndKeys:
													 track, @"track",
													 [NSNumber numberWithUnsignedInteger:count], @"count", nil]];
				}
				
				// create sorted playlist
				NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"count" ascending:NO];
				[intermediatePlaylist sortUsingDescriptors:[NSArray arrayWithObject:sortDescriptor]];
				playlist = intermediatePlaylist;
			}
			else
			{
				playlist = entries;
			}
			
			playlist = [playlist subarrayWithRange:NSMakeRange(0, MIN([playlist count], PLAYLIST_MAX_TRACKS))];
			self.playlist = [playlist valueForKey:@"track"];
		}
		
		// find next track
		if (chartsMode)
		{
			LHTrack *track = nil;
			if (historyEntry)
			{
				// next playlist entry
				NSUInteger position = [self.playlist indexOfObject:historyEntry.track];
				if (position != NSNotFound) {
					if (ascending && position < [self.playlist count]-1)
						track = [self.playlist objectAtIndex:position+1];
					else if (!ascending && position > 0)
						track = [self.playlist objectAtIndex:position-1];
				}
			}
			else if ([self.playlist count] > 0)
			{
				// first playlist entry
				track = [self.playlist objectAtIndex:0];
			}
			
			historyEntry = [[track.historyEntries filteredSetUsingPredicate:predicate] anyObject];
		}
		else
		{
			historyEntry = [entries count] > 0 ? [entries objectAtIndex:0] : nil;
		}
		
		// try to play entry
		if ([self loadHistoryEntry:historyEntry])
			break; // success
		
		if (++tries >= 100) {
			// abort
			historyEntry = nil;
		}
		
	} while (historyEntry);
	
	// reset everything if we didn't find a track
	if (!historyEntry) {
		[self.currentSound stop];
		self.currentSound = nil;
		self.currentHistoryEntry = nil;
		self.currentEvent = nil;
	}
	
	return historyEntry != nil;
}

- (NSArray *)predicatesForEvent:(id <LHEvent>)event
{
	if (event)
	{
		NSMutableArray *result = [NSMutableArray arrayWithCapacity:2];
		
		// entry has to be within current event
		if (event.eventStart && event.eventEnd)
		{
			NSPredicate *predicate = [NSPredicate predicateWithFormat:@"timestamp >= %@ AND timestamp <= %@", event.eventStart, event.eventEnd];
			[result addObject:predicate];
		}
		if (event.eventStartTime != LH_EVENT_TIME_UNDEFINED && event.eventEndTime != LH_EVENT_TIME_UNDEFINED)
		{
			NSPredicate *predicate = [NSPredicate predicateWithFormat:@"time >= %d AND time <= %d", event.eventStartTime, event.eventEndTime];
			[result addObject:predicate];
		}
		
		return result;
	}
	else
	{
		return nil;
	}
}

- (void)sound:(NSSound *)sound didFinishPlaying:(BOOL)finishedPlaying
{
	if (sound == self.currentSound && finishedPlaying) {
		// play next track
		[self skipForward:nil];
	}
}

@end
