//
//  LHiTunesLibrary.m
//  LastHistory
//
//  Created by Frederik Seiffert on 08.11.09.
//  Copyright 2009 Frederik Seiffert. All rights reserved.
//

#import "LHiTunesLibrary.h"

#import "SBiTunes.h"


@implementation LHiTunesLibrary

@synthesize libraryURL=_libraryURL;

+ (LHiTunesLibrary *)defaultLibrary
{
	static id defaultLibrary = nil;
	if (!defaultLibrary) {
		[[NSUserDefaults standardUserDefaults] synchronize];
		NSArray *dbs = [[[NSUserDefaults standardUserDefaults] persistentDomainForName:@"com.apple.iApps"] objectForKey:@"iTunesRecentDatabases"];
		if ([dbs count] > 0) {
			NSURL *url = [NSURL URLWithString:[dbs objectAtIndex:0]];
			if ([url isFileURL])
				defaultLibrary = [[self alloc] initWithURL:url];
		}
	}
	return defaultLibrary;
}

- (id)initWithURL:(NSURL *)libraryURL
{
	self = [super init];
	if (self != nil) {
		_libraryURL = [libraryURL retain];
	}
	return self;
}

- (NSDictionary *)tracks
{
	if (_tracks)
		return _tracks;
	
	NSURL *libraryURL = self.libraryURL;
	if (!libraryURL)
		return nil;
	
	NSLog(@"Reading iTunes library: %@", libraryURL);
	NSDictionary *library = [NSDictionary dictionaryWithContentsOfURL:libraryURL];
	if (!library) {
		NSLog(@"Error: unable to read iTunes library from '%@'.", libraryURL);
		return nil;
	}
	
	NSDictionary *tracks = [library objectForKey:@"Tracks"];
	if (!tracks) {
		NSLog(@"Error: No tracks found in iTunes library.");
		return nil;
	}
	
	NSLog(@"Read %d tracks from iTunes.", tracks.count);
	
	NSMutableDictionary *result = [NSMutableDictionary dictionaryWithCapacity:tracks.count];
	for (NSDictionary *track in tracks.allValues)
	{
		NSString *name = [track valueForKey:@"Name"];
		NSString *artist = [track valueForKey:@"Artist"];
		NSString *trackID = [[NSString stringWithFormat:@"%@ - %@", artist, name] lowercaseString];
		
		[result setObject:track forKey:trackID];
	}
	
	_tracks = [result copy];
	return _tracks;
}

- (NSDictionary *)trackForTrack:(NSString *)name artist:(NSString *)artist
{
	NSString *trackID = [[NSString stringWithFormat:@"%@ - %@", artist, name] lowercaseString];
	return [self.tracks objectForKey:trackID];
}


#pragma mark -
#pragma mark iTunes Scripting

- (SBiTunesApplication *)app
{
	if (!_app)
		_app = [SBApplication applicationWithBundleIdentifier:@"com.apple.iTunes"];
	
	return _app;
}

- (SBiTunesSource *)source
{
	for (SBiTunesSource *source in [[self app] sources]) {
		if ([source kind] == SBiTunesESrcLibrary)
			return source;
	}
	
	return nil;
}

// master music library playlist
- (SBiTunesPlaylist *)masterPlaylist
{
	if (!_masterPlaylist)
	{
		for (SBiTunesPlaylist *playlist in [[self source] playlists]) {
			if ([playlist specialKind] == SBiTunesESpKMusic) {
				_masterPlaylist = playlist;
				break;
			}
		}
	}
	
	return _masterPlaylist;
}

- (SBiTunesTrack *)trackForTrack:(NSDictionary *)track
{
	SBiTunesPlaylist *masterPlaylist = [self masterPlaylist];
	
	NSString *persistentID = [track objectForKey:@"Persistent ID"];
	return [[[masterPlaylist tracks] filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"persistentID == %@", persistentID]] lastObject];
}

- (void)revealTrack:(NSDictionary *)track
{
	if (track)
	{
		SBiTunesTrack *iTunesTrack = [self trackForTrack:track];
		[iTunesTrack reveal];
	}
}

- (void)createPlaylist:(NSString *)name withTracks:(NSArray *)tracks
{
	if ([tracks count] > 0)
	{
		NSDictionary *playlistProperties = [NSDictionary dictionaryWithObject:name forKey:@"name"];
		SBiTunesPlaylist *playlist = [[[[self app] classForScriptingClass:@"playlist"] alloc] initWithProperties:playlistProperties];
		[[[self source] userPlaylists] insertObject:playlist atIndex:0];
		
		for (NSDictionary *track in tracks)
		{
			SBiTunesTrack *iTunesTrack = [self trackForTrack:track];
			if (iTunesTrack)
				[iTunesTrack duplicateTo:playlist];
		}
	}
}

@end
