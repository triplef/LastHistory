#import "LHHistoryEntry.h"
#import "LHTrack.h"
#import "NSDate-Extras.h"
#import "LHCommonMacros.h"


#define INITIAL_WEIGHT 0.05
#define PLAYLIST_HOURS_RANGE 4
#define PLAYLIST_GAP_SECONDS 60*60		// 1 hour


@implementation LHHistoryEntry

@synthesize layer;
@synthesize hidden;

- (void)awakeFromInsert
{
	[super awakeFromInsert];
	
	// set defaults
	[self setPrimitiveValue:[NSNumber numberWithFloat:INITIAL_WEIGHT] forKey:@"weight"];
}

- (NSAttributedString *)attributedDisplayName
{
	NSDateFormatter *outputFormatter = [NSDateFormatter new];
	[outputFormatter setDateStyle:NSDateFormatterMediumStyle];
	[outputFormatter setTimeStyle:NSDateFormatterMediumStyle];
	NSString *dateString = [outputFormatter stringFromDate:self.timestamp];
	
	NSMutableAttributedString *result = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@: %@", dateString, self.track.displayName]
																			   attributes:nil];
	[result beginEditing];
	[result setAttributes:[NSDictionary dictionaryWithObjectsAndKeys:[NSColor darkGrayColor], NSForegroundColorAttributeName, nil]
					range:NSMakeRange(0, dateString.length+1)];
	[result endEditing];
	
	return [result copy];
}


- (NSArray *)adjacentEntries:(NSUInteger)numEntries ascending:(BOOL)ascending
{
	NSFetchRequest *request = [NSFetchRequest new];
	[request setEntity:self.entity];
	[request setFetchLimit:numEntries];
	
	NSString *predicateString = [NSString stringWithFormat:@"timestamp %@ %%@", ascending ? @">" : @"<"];
	[request setPredicate:[NSPredicate predicateWithFormat:predicateString, self.timestamp]];
	
	NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"timestamp" ascending:ascending];
	[request setSortDescriptors:[NSArray arrayWithObject:sortDescriptor]];
	
	NSError *error;
	return [[self managedObjectContext] executeFetchRequest:request error:&error];
}

// fetches all playlists within +/- 2 hours of all connected history entries
- (NSArray *)playlists
{
	NSFetchRequest *request = [NSFetchRequest new];
	[request setEntity:self.entity];
	
	NSCalendar *calendar = [NSCalendar currentCalendar];
	NSDateComponents *startDateComps = [NSDateComponents new];
	startDateComps.hour = -PLAYLIST_HOURS_RANGE/2;
	NSDateComponents *endDateComps = [NSDateComponents new];
	endDateComps.hour = PLAYLIST_HOURS_RANGE/2;
	
	NSSet *connectedEntries = self.track.historyEntries;
	NSMutableArray *predicates = [NSMutableArray arrayWithCapacity:[connectedEntries count]];
	
	for (LHHistoryEntry *entry in connectedEntries)
	{
		NSDate *startDate = [calendar dateByAddingComponents:startDateComps toDate:entry.timestamp options:0];
		NSDate *endDate = [calendar dateByAddingComponents:endDateComps toDate:entry.timestamp options:0];
		NSPredicate *predicate = [NSPredicate predicateWithFormat:@"timestamp > %@ AND timestamp < %@", startDate, endDate];
		[predicates addObject:predicate];
	}
	
	[request setPredicate:[NSCompoundPredicate orPredicateWithSubpredicates:predicates]];
	
	NSError *error;
	return [[self managedObjectContext] executeFetchRequest:request error:&error];
}

// returns the adjacent playlists entries for a given playlists array
- (NSArray *)adjacentEntriesInPlaylists:(NSArray *)playlists ascending:(BOOL)ascending
{
	NSString *predicateString = [NSString stringWithFormat:@"timestamp %@ %%@", ascending ? @">" : @"<"];
	NSArray *result = [playlists filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:predicateString, self.timestamp]];
	
	NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"timestamp" ascending:ascending];
	result = [result sortedArrayUsingDescriptors:[NSArray arrayWithObject:sortDescriptor]];
	
	// stop adjacent entries at playlist gap
	for (NSUInteger i = 0; i < [result count]; i++)
	{
		LHHistoryEntry *previousEntry = i == 0 ? self : [result objectAtIndex:i-1];
		LHHistoryEntry *entry = [result objectAtIndex:i];
		if (!ascending)
			swap((void *)&previousEntry, (void *)&entry);
		if ([entry.timestamp timeIntervalSinceDate:previousEntry.timestamp] > PLAYLIST_GAP_SECONDS) {
			result = [result subarrayWithRange:NSMakeRange(0, i)];
			break;
		}
	}
	
	return result;
}


- (LHHistoryEntry *)previousEntry
{
	return [[self adjacentEntries:1 ascending:NO] lastObject];
}

- (LHHistoryEntry *)nextEntry
{
	return [[self adjacentEntries:1 ascending:YES] lastObject];
}


- (NSDate *)day
{
	// cache day for performance reasons (used for every repositioning nodes)
	if (!_day)
		_day = [self.timestamp day];
	return _day;
}

- (NSInteger)year
{
	if (!_year)
		_year = [self.timestamp year];
	return _year;
}

- (NSInteger)month
{
	if (!_month)
		_month = [self.timestamp month];
	return _month;
}

- (NSInteger)hour
{
	if (!_hour)
		_hour = [self.timestamp hour];
	return _hour;
}

- (NSInteger)weekday
{
	if (!_weekday)
		_weekday = [self.timestamp weekday];
	return _weekday;
}

- (void)setTimestamp:(NSDate *)timestamp
{
	[self willChangeValueForKey:@"timestamp"];
	[self setPrimitiveValue:timestamp forKey:@"timestamp"];
	[self didChangeValueForKey:@"timestamp"];
	
	// calculate time from timestamp
	NSCalendar *calendar = [NSCalendar currentCalendar];
	NSDateComponents *comps = [calendar components:(NSHourCalendarUnit | NSMinuteCalendarUnit | NSSecondCalendarUnit)
										  fromDate:timestamp];
	[self setTimeValue:comps.hour*60*60 + comps.minute*60 + comps.second];
	
	_day = nil;
}

@end
