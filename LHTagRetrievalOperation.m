//
//  LHTagRetrievalOperation.m
//  LastHistory
//
//  Created by Frederik Seiffert on 19.11.09.
//  Copyright 2009 Frederik Seiffert. All rights reserved.
//

#import "LHTagRetrievalOperation.h"

#import "LHAppDelegate.h"
#import "LHDocument.h"
#import "LHTrack.h"
#import "LHArtist.h"
#import "LHTrackTag.h"
#import "LHTag.h"
#import "LFWebService.h"


#define PROCESS_CHUNK_SIZE 10

#define TAG_MIN_COUNT 10


@implementation LHTagRetrievalOperation

- (void)process
{
	NSManagedObjectContext *context = self.context;
	
	// cache entity descriptions for faster inserting
	_tagEntity = [NSEntityDescription entityForName:@"Tag" inManagedObjectContext:context];
	_trackTagEntity = [NSEntityDescription entityForName:@"TrackTag" inManagedObjectContext:context];
	
	// fetch tracks
	NSArray *tracks = [self.document objectsForEntity:@"Track" withPredicate:nil fetchLimit:0 ascending:YES inContext:context];
	if (!tracks)
		return;
	
	self.progressMessage = [NSString stringWithFormat:@"Retrieving tags for %u tracks...", tracks.count];
	self.progressIndeterminate = NO;
	
	LFWebService *webService = [[NSApp delegate] lfWebService];
	NSAssert(webService, @"No web service");
	
	NSUInteger processedCount = 0;
	for (LHTrack *track in tracks)
	{
		if ([self isCancelled]) {
			[context rollback];
			return;
		}
		
		if (!track.artist.name || !track.name || track.trackTags.count > 0)
			continue;
		
		NSMutableDictionary *params = [NSMutableDictionary dictionaryWithCapacity:4];
		[params setObject:track.artist.name forKey:@"artist"];
		[params setObject:track.name forKey:@"track"];
		if (track.mbid)
			[params setObject:track.mbid forKey:@"mbid"];
		if (webService.userName)
			[params setObject:webService.userName forKey:@"username"];
		
		NSError *error = nil;
		NSXMLDocument *xml = [webService callMethod:@"track.getTopTags" withParameters:params error:&error];
		if (!xml && error && [error code] != 500) // ignore internal server errors
			[self.document presentError:error];
		
		NSArray *tagElements = [[[xml.rootElement elementsForName:@"toptags"] lastObject] children];
		
		for (NSXMLElement *tagElement in tagElements)
		{
			NSString *tagName = [[[tagElement elementsForName:@"name"] lastObject] stringValue];
			short tagCount = [[[[tagElement elementsForName:@"count"] lastObject] stringValue] intValue];
			if (tagName.length > 0 && tagCount >= TAG_MIN_COUNT)
			{
				LHTag *tag = [[LHTag fetchTagsWithName:context name:tagName] lastObject];
				if (!tag) {
					tag = [[LHTag alloc] initWithEntity:_tagEntity insertIntoManagedObjectContext:context];
					tag.name = tagName;
				}
				LHTrackTag *trackTag = [[LHTrackTag alloc] initWithEntity:_trackTagEntity insertIntoManagedObjectContext:context];
				trackTag.countValue = tagCount;
				trackTag.track = track;
				trackTag.tag = tag;
			}
		}
		
		self.progress = (float)processedCount / tracks.count;
		
		if ((++processedCount % PROCESS_CHUNK_SIZE) == 0) {
			if (![self saveContext])
				return;
			
//			NSLog(@"Retrieved tags for %u tracks", processedCount);
		}
	}
	
	[self saveContext];
	
	NSLog(@"Finished retrieving tags for tracks");
}

@end
