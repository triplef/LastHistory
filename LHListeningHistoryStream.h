//
//  LHListeningHistoryLayer.h
//  LastHistory
//
//  Created by Frederik Seiffert on 10.12.09.
//  Copyright 2009 Frederik Seiffert. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "LHStreamLayer.h"

#define HISTORY_PADDING_Y 10.0

@class LHHistoryEntry;


@interface LHListeningHistoryStream : LHStreamLayer {
	NSMutableDictionary *_nodeImages; // by label
	
	NSBezierPath *_directPath;
	NSBezierPath *_playlistPath;
	NSMutableSet *_playlistNodes;
}

- (void)weightNodes;

- (void)insertObject:(id)object;
- (void)updateObject:(id)object;

@end
