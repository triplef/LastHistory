//
//  LHHistoryEntryWeightingOperation.m
//  LastHistory
//
//  Created by Frederik Seiffert on 19.11.09.
//  Copyright 2009 Frederik Seiffert. All rights reserved.
//

#import "LHWeightingOperation.h"

#import "LHDocument.h"
#import "LHHistoryEntry.h"
#import "LHTrack.h"
#import "LHArtist.h"


#define PROCESS_CHUNK_SIZE 1000

#define HISTORY_ENTRY_DEFAULT_WEIGHT 0.01
#define HISTORY_ENTRY_WEIGHT_DATE_RANGE	30 // days
#define TIME_POINT_MODIFIER_WEIGHT 0.5


@implementation LHWeightingOperation

- (void)process
{
	NSManagedObjectContext *context = self.context;
	
	// setup predicate for similar entries
	NSPredicate *similarEntriesPredicate = [NSPredicate predicateWithFormat:@"track == $track AND timestamp >= $startDate AND timestamp <= $endDate"];
	
	// fetch tracks and history entries
	NSArray *tracks = [self.document objectsForEntity:@"Track" withPredicate:nil fetchLimit:0 ascending:YES inContext:context];
	NSArray *historyEntries = [self.document objectsForEntity:@"HistoryEntry" withPredicate:nil fetchLimit:0 ascending:YES inContext:context];
	if (historyEntries.count == 0)
		return;
	
	self.progressMessage = [NSString stringWithFormat:@"Calculating weights for %u history entries...", historyEntries.count];
	self.progressIndeterminate = NO;
	
	NSUInteger maxTrackCount = [[tracks valueForKeyPath:@"@max.historyEntries.@count"] unsignedIntegerValue];
	NSLog(@"max. track count: %u", maxTrackCount);
	
	LHHistoryEntry *firstHistoryEntry = [historyEntries objectAtIndex:0];
	LHHistoryEntry *lastHistoryEntry = [historyEntries lastObject];
	NSDate *historyStartDate = firstHistoryEntry.timestamp;
	NSTimeInterval historyDuration = [lastHistoryEntry.timestamp timeIntervalSinceDate:historyStartDate];
	
	NSCalendar *calendar = [NSCalendar currentCalendar];
	NSDateComponents *comps = [NSDateComponents new];
	
	NSUInteger processedCount = 0;
	for (LHHistoryEntry *historyEntry in historyEntries)
	{
		if ([self isCancelled]) {
			[context rollback];
			return;
		}
		
		float weight = HISTORY_ENTRY_DEFAULT_WEIGHT;
		LHTrack *track = historyEntry.track;
		NSUInteger trackCount = track.trackCount;
		NSAssert(track, @"track");
		
		if (trackCount >= 2)
		{
			comps.day = HISTORY_ENTRY_WEIGHT_DATE_RANGE/2;
			NSDate *endDate = [calendar dateByAddingComponents:comps toDate:historyEntry.timestamp options:0];
			comps.day = -HISTORY_ENTRY_WEIGHT_DATE_RANGE/2;
			NSDate *startDate = [calendar dateByAddingComponents:comps toDate:historyEntry.timestamp options:0];
			
			NSPredicate *predicate = [similarEntriesPredicate predicateWithSubstitutionVariables:[NSDictionary dictionaryWithObjectsAndKeys:
																								  track, @"track",
																								  startDate, @"startDate",
																								  endDate, @"endDate",
																								  nil]];
			NSUInteger similarHistoryEntryCount = [self.document countForEntity:@"HistoryEntry" withPredicate:predicate inContext:context];
			
			NSTimeInterval timeSinceHistoryStart = [historyEntry.timestamp timeIntervalSinceDate:historyStartDate];
			float timePointModifier = (1.0 - TIME_POINT_MODIFIER_WEIGHT/2) + ((timeSinceHistoryStart / historyDuration) * TIME_POINT_MODIFIER_WEIGHT);
			
			weight = ((float)similarHistoryEntryCount / trackCount) * ((float)trackCount / maxTrackCount) * timePointModifier;
//			NSLog(@"%f: %@ - %@, time: %f", weight, track.artist.name, track.name, timePointModifier);
			
			if (weight > 1.0) {
//				NSLog(@"outlier: %f: %@ - %@", weight, track.artist.name, track.name);
				weight = 1.0;
			}
		}
		
		[historyEntry setWeightValue:weight];
		
		if ((++processedCount % PROCESS_CHUNK_SIZE) == 0) {
			self.progress = (float)processedCount / historyEntries.count;
			
			if (![self saveContext])
				return;
			
//			NSLog(@"Calculated %u history entries", processedCount);
		}
	}
	
	[self saveContext];
	
	NSLog(@"Finished calculating history entries");
}

@end
