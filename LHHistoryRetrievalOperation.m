//
//  LHHistoryRetrievalOperation.m
//  LastHistory
//
//  Created by Frederik Seiffert on 13.12.09.
//  Copyright 2009 Frederik Seiffert. All rights reserved.
//

#import "LHHistoryRetrievalOperation.h"

#import "LHAppDelegate.h"
#import "LHDocument.h"
#import "LHUser.h"
#import "LHHistoryEntry.h"
#import "LHTrack.h"
#import "LHArtist.h"
#import "LHAlbum.h"
#import "LFWebService.h"

#define PROCESS_CHUNK_SIZE 10


@implementation LHHistoryRetrievalOperation

@synthesize username=_username;

- (id)initWithDocument:(LHDocument *)document andUsername:(NSString *)username
{
	self = [super initWithDocument:document];
	if (self != nil) {
		_username = username;
	}
	return self;
}

- (BOOL)processTrack:(NSXMLElement *)trackElement intoHistoryEntry:(LHHistoryEntry **)outHistoryEntry
{
	NSManagedObjectContext *context = self.context;
	
	NSString *trackName = [[[trackElement elementsForName:@"name"] lastObject] stringValue];
	NSInteger timestamp = [[[[[trackElement elementsForName:@"date"] lastObject] attributeForName:@"uts"] stringValue] integerValue];
	
	if (trackName.length > 0 && timestamp != 0)
	{
		// check for first last history entry
		if (timestamp == [_firstHistoryEntry.timestamp timeIntervalSince1970] ||
			timestamp == [_lastHistoryEntry.timestamp timeIntervalSince1970])
		{
			NSLog(@"Reached first existing or last history entry.");
			return NO;
		}
		
		// find or create artist
		LHArtist *artist = nil;
		NSXMLElement *artistElement = [[trackElement elementsForName:@"artist"] lastObject];
		NSString *artistName = [artistElement stringValue];
		if (artistName.length > 0) {
			artist = [[LHArtist fetchArtistsWithName:context name:artistName] lastObject];
			if (!artist) {
				artist = [[LHArtist alloc] initWithEntity:_artistEntity insertIntoManagedObjectContext:context];
				artist.name = artistName;
				
				NSString *mbid = [[artistElement attributeForName:@"mbid"] stringValue];
				if (mbid.length > 0)
					artist.mbid = mbid;
			}
		}
		
		LHTrack *track = [[LHTrack fetchTracksWithNameAndArtist:context name:trackName artist:artist] lastObject];
		if (!track) {
			track = [[LHTrack alloc] initWithEntity:_trackEntity insertIntoManagedObjectContext:context];
			track.name = trackName;
			track.artist = artist;
			
			NSString *mbid = [[[trackElement elementsForName:@"mbid"] lastObject] stringValue];
			if (mbid.length > 0)
				track.mbid = mbid;
		}
		
		// find or create album
		LHAlbum *album = track.album;
		if (!album) {
			NSXMLElement *albumElement = [[trackElement elementsForName:@"album"] lastObject];
			NSString *albumName = [albumElement stringValue];
			if (albumName.length > 0) {
				album = [[LHAlbum fetchAlbumsWithNameAndArtist:context name:albumName artist:artist] lastObject];
				if (!album) {
					album = [[LHAlbum alloc] initWithEntity:_albumEntity insertIntoManagedObjectContext:context];
					album.name = albumName;
					album.artist = artist;
					
					NSString *mbid = [[albumElement attributeForName:@"mbid"] stringValue];
					if (mbid.length > 0)
						album.mbid = mbid;
					
					NSString *imagePath = [[[trackElement nodesForXPath:@"image[@size='large']" error:nil] lastObject] stringValue];
					if (imagePath.length > 0)
						album.imagePath = imagePath;
				}
				track.album = album;
			}
		}
		
		// create history entry
		LHHistoryEntry *historyEntry = [[LHHistoryEntry alloc] initWithEntity:_historyEntryEntity insertIntoManagedObjectContext:context];
		historyEntry.user = _user;
		historyEntry.track = track;
		historyEntry.timestamp = [NSDate dateWithTimeIntervalSince1970:timestamp];
		
		if (outHistoryEntry)
			*outHistoryEntry = historyEntry;
	}
	
	return YES;
}

- (void)process
{
	NSAssert(_username, @"No username given");
	
	self.progressMessage = [NSString stringWithFormat:@"Retrieving listening history for %@...", self.username];
	
	NSManagedObjectContext *context = self.context;
	
	// fetch or create user
	LHUser *user = [[LHUser fetchUsersWithName:context name:self.username] lastObject];
	if (!user) {
		user = [LHUser insertInManagedObjectContext:context];
		user.name = self.username;
	}
	_user = user;
	_lastHistoryEntry = self.document.lastHistoryEntry;
	
	// cache entity descriptions for faster inserting
	_historyEntryEntity = [NSEntityDescription entityForName:@"HistoryEntry" inManagedObjectContext:context];
	_trackEntity = [NSEntityDescription entityForName:@"Track" inManagedObjectContext:context];
	_albumEntity = [NSEntityDescription entityForName:@"Album" inManagedObjectContext:context];
	_artistEntity = [NSEntityDescription entityForName:@"Artist" inManagedObjectContext:context];
	
	LFWebService *webService = [[NSApp delegate] lfWebService];
	NSAssert(webService, @"No web service");
	
	NSMutableDictionary *params = [NSMutableDictionary dictionaryWithCapacity:4];
	[params setValue:_user.name	forKey:@"user"];
	[params setValue:@"100"	forKey:@"limit"];
	if (webService.userName)
		[params setObject:webService.userName forKey:@"username"];
	
	NSUInteger page = 0;
	NSUInteger totalPages = NSUIntegerMax;
	
	BOOL abort = NO;
	while (!abort && page < totalPages)
	{
		if ([self isCancelled]) {
			[context rollback];
			return;
		}
		
		// fetch page
		[params setValue:[NSString stringWithFormat:@"%u", ++page] forKey:@"page"];
		
		NSError *error = nil;
		NSXMLDocument *pageXML = [webService callMethod:@"user.getRecentTracks" withParameters:params error:&error];
		if (!pageXML && error)
			[self.document presentError:error];
		
		NSXMLElement *container = [[pageXML.rootElement elementsForName:@"recenttracks"] lastObject];
		
		if (page == 1)
		{
			totalPages = [[[container attributeForName:@"totalPages"] stringValue] integerValue];
		
			if (self.document.historyEntriesCount == 0) {
				// get last history entry to define timespan
				[params setValue:[NSString stringWithFormat:@"%u", totalPages] forKey:@"page"];
				NSXMLDocument *lastPageXML = [webService callMethod:@"user.getRecentTracks" withParameters:params error:&error];
				if (!lastPageXML)
				{
					// try once more if "Error fetching recent tracks" from Last.fm
					if ([error code] == 8)
						lastPageXML = [webService callMethod:@"user.getRecentTracks" withParameters:params error:&error];
					if (!lastPageXML && error)
						[self.document presentError:error];
				}
				
				NSXMLElement *lastTrack = [[[[lastPageXML.rootElement elementsForName:@"recenttracks"] lastObject] children] lastObject];
				[self processTrack:lastTrack intoHistoryEntry:&_firstHistoryEntry];
			}
		}
		
//		NSLog(@"Page %u of %u", page, totalPages);
		
		for (NSXMLElement *trackElement in [container children]) {
			abort = ![self processTrack:trackElement intoHistoryEntry:nil];
			if (abort)
				break;
		}
		
		self.progress = (float)page / totalPages;
		self.progressIndeterminate = NO;
		
		if ((page % PROCESS_CHUNK_SIZE) == 0 || page == 1) { // save every 10 pages, and after first page to setup view
			if (![self saveContext])
				return;
			
//			NSLog(@"Retrieved %u listening history pages", page);
		}
	}
	
	[self saveContext];
	
	NSLog(@"Finished retrieving listening history");
}

@end
