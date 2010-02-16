//
//  LHiTunesLibrary.h
//  LastHistory
//
//  Created by Frederik Seiffert on 08.11.09.
//  Copyright 2009 Frederik Seiffert. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class SBiTunesApplication;
@class SBiTunesPlaylist;


@interface LHiTunesLibrary : NSObject {
	NSURL *_libraryURL;
	NSDictionary *_tracks;
	
	SBiTunesApplication *_app;
	SBiTunesPlaylist *_masterPlaylist;
}

+ (LHiTunesLibrary *)defaultLibrary;

- (id)initWithURL:(NSURL *)libraryURL;

@property (readonly) NSURL *libraryURL;
@property (readonly) NSDictionary *tracks;

- (NSDictionary *)trackForTrack:(NSString *)name artist:(NSString *)artist;


// iTunes Scripting

- (void)revealTrack:(NSDictionary *)track;
- (void)createPlaylist:(NSString *)name withTracks:(NSArray *)tracks;

@end
