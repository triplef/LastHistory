//
//  LHListeningHistoryLayer.m
//  LastHistory
//
//  Created by Frederik Seiffert on 10.12.09.
//  Copyright 2009 Frederik Seiffert. All rights reserved.
//

#import "LHListeningHistoryStream.h"

#import "LHHistoryView.h"
#import "LHDocument.h"
#import "LHHistoryEntry.h"
#import "LHTrack.h"
#import "NSImage-Extras.h"


#define NODE_OPACITY_HIDDEN		0.025
#define NODE_OPACITY_DEFAULT	0.75
#define NODE_OPACITY_HIGHLIGHT	1.0
#define NODE_OPACITY_PLAYING	1.0

#define NODE_BASE_SIZE 10.0
#define NODE_BASE_WEIGHT 0.085
#define NODE_MIN_WEIGHT 0.04
#define NODE_MAX_WEIGHT 0.2
#define NODE_LABEL_HIGHLIGHT	@"highlight"

#define PLAYLIST_DIST_MAX 4


@interface LHListeningHistoryStream ()

// Utilities
- (CGPoint)nodePositionForHistoryEntry:(LHHistoryEntry *)historyEntry;
- (id)nodeContentsForLabel:(NSString *)label;
- (void)weightNode:(LHHistoryEntry *)historyEntry;

@end



@implementation LHListeningHistoryStream

+ (Class)nodeClass
{
	return [LHHistoryEntry class];
}

+ (id <CAAction>)defaultActionForKey:(NSString *)key
{
	// prevent default animation for contents to speed up display
	if ([key isEqualToString:@"contents"])
		return (id <CAAction>)[NSNull null];
	
	return [super defaultActionForKey:key];
}

- (id)initWithLayer:(id)layer
{
	self = [super initWithLayer:layer];
	if (self != nil) {
		LHListeningHistoryStream *object = layer;
		_nodeImages = object->_nodeImages;
		_directPath = object->_directPath;
		_playlistPath = object->_playlistPath;
	}
	return self;
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
	if ([keyPath isEqualToString:@"showHistoryEntryWeights"] || [keyPath isEqualToString:@"nodeScaleFactor"])
	{
		[self weightNodes];
	}
	else if ([keyPath isEqualToString:@"visibleHistoryEntries"])
	{
		// update history entries
		for (CALayer *layer in self.sublayers)
		{
			LHHistoryEntry *historyEntry = [layer valueForKey:LAYER_DATA_KEY];
			if (historyEntry.hidden) {
				layer.opacity = NODE_OPACITY_HIDDEN;
				layer.contents = [self nodeContentsForLabel:TRACK_GENRE_UNKNOWN];
			} else {
				layer.opacity = NODE_OPACITY_DEFAULT;
				layer.contents = [self nodeContentsForLabel:historyEntry.track.genre];
			}
		}
	}
	else if ([keyPath isEqualToString:@"currentHistoryEntry"]) // highlighting of current history entry
	{
		LHHistoryEntry *oldHistoryEntry = [change objectForKey:NSKeyValueChangeOldKey];
		if (oldHistoryEntry && ![oldHistoryEntry isEqual:[NSNull null]])
		{
			// restore normal look of layer
			CALayer *layer = oldHistoryEntry.layer;
			[layer removeAllAnimations];
			layer.opacity = NODE_OPACITY_DEFAULT;
			layer.zPosition = kDefaultZ;
		}
		
		LHHistoryEntry *newHistoryEntry = [change objectForKey:NSKeyValueChangeNewKey];
		if (newHistoryEntry && ![newHistoryEntry isEqual:[NSNull null]])
		{
			// visibly mark playing song
			CALayer *layer = newHistoryEntry.layer;
			layer.opacity = NODE_OPACITY_PLAYING;
			layer.zPosition = kPlayingZ;
			
			float scale = MAX([[layer valueForKeyPath:@"transform.scale"] floatValue], 1.0);
			CABasicAnimation *pulseAnimation = [CABasicAnimation animationWithKeyPath:@"transform.scale"];
			pulseAnimation.fromValue = [NSNumber numberWithFloat:scale];
			pulseAnimation.toValue = [NSNumber numberWithFloat:scale * 1.5];
			pulseAnimation.duration = 1.0;
			pulseAnimation.autoreverses = YES;
			pulseAnimation.repeatCount = 1000;
			[layer addAnimation:pulseAnimation forKey:@"playingAnimation"];
		}
	}
}

- (void)setupLayer
{
	self.anchorPoint = CGPointMake(0, 0); // lower-left corner
	self.bounds = CGRectMake(0, 0, 1.0, 1.0);
	
	[self.view addObserver:self forKeyPath:@"showHistoryEntryWeights" options:0 context:NULL];
	[self.view addObserver:self forKeyPath:@"nodeScaleFactor" options:0 context:NULL];
	[self.view.document addObserver:self forKeyPath:@"visibleHistoryEntries" options:0 context:NULL];
	[self.view.document addObserver:self forKeyPath:@"currentHistoryEntry" options:(NSKeyValueObservingOptionOld|NSKeyValueObservingOptionNew) context:NULL];
}

- (void)generateNodes
{
	[self removeAllSublayers];
	
	// fetch history entries
	NSArray *historyEntries = self.view.document.historyEntries;
	
	NSLog(@"Generating history entry nodes...");
	
	NSUInteger processedCount = 0;
	for (LHHistoryEntry *historyEntry in historyEntries)
	{
		[self insertObject:historyEntry];
		
		if ((++processedCount % 5000) == 0)
			NSLog(@"Processed %u history entry nodes", processedCount);
	}
	
	NSLog(@"Generated %u history entry nodes", processedCount);
}

- (void)layoutSublayers
{
	if (self.superlayer.isHidden)
		return;
	
	// resize history entries layer
	CGFloat width = [self.view xPositionForDate:self.view.timelineEnd] - [self.view xPositionForDate:self.view.timelineStart];
	CGRect bounds = self.bounds;
	bounds.size.width = width + STREAM_PADDING_X*2;
	self.bounds = bounds;
	
	// reposition nodes
	for (CALayer *layer in self.sublayers)
	{
		LHHistoryEntry *historyEntry = [layer valueForKey:LAYER_DATA_KEY];
		layer.position = [self nodePositionForHistoryEntry:historyEntry];
	}
}

- (void)weightNodes
{
	NSLog(@"Weighting history entry nodes...");
	
	for (CALayer *layer in self.sublayers)
	{
		LHHistoryEntry *historyEntry = [layer valueForKey:LAYER_DATA_KEY];
		[self weightNode:historyEntry];
	}
}

- (void)insertObject:(id)object
{
	if ([object isKindOfClass:[LHHistoryEntry class]])
	{
		LHHistoryEntry *historyEntry = object;
		
		CALayer *layer = [CALayer layer];
		[layer setValue:historyEntry forKey:LAYER_DATA_KEY];
		
		layer.bounds = CGRectMake(0, 0, NODE_BASE_SIZE, NODE_BASE_SIZE);
		layer.opacity = NODE_OPACITY_DEFAULT;
		layer.position = [self nodePositionForHistoryEntry:historyEntry];
		layer.contents = [self nodeContentsForLabel:historyEntry.track.genre];
		
		[self addSublayer:layer];
		historyEntry.layer = layer;
		
		[self weightNode:historyEntry];
	}
}

- (void)updateObject:(id)object
{
	if ([object isKindOfClass:[LHTrack class]])
	{
		LHTrack *track = (LHTrack *)object;
		for (LHHistoryEntry *historyEntry in track.historyEntries) {
			historyEntry.layer.contents = [self nodeContentsForLabel:track.genre];
		}
	}
	else if ([object isKindOfClass:[LHHistoryEntry class]])
	{
		LHHistoryEntry *historyEntry = (LHHistoryEntry *)object;
		[self weightNode:historyEntry];
	}
}


#pragma mark -
#pragma mark Highlighting

// CALayer delegate
- (void)drawInContext:(CGContextRef)ctx
{
	[NSGraphicsContext saveGraphicsState];
	[NSGraphicsContext setCurrentContext:[NSGraphicsContext graphicsContextWithGraphicsPort:ctx flipped:NO]];
	
	[[NSColor redColor] setStroke];
	
	// draw path calculated in highlightedHistoryEntry
	[_directPath stroke];
	
	// draw playlist paths from adjacent tracks dashed
	const CGFloat pattern[] = {1.0, 2.0};
	[_playlistPath setLineDash:pattern count:2 phase:0.0];
	[_playlistPath stroke];
	
	[NSGraphicsContext restoreGraphicsState];
}

// helper method for setHighlightedHistoryEntry:
- (void)addLineFrom:(LHHistoryEntry *)start to:(LHHistoryEntry *)end toPath:(NSBezierPath *)path
{
	NSPoint startPoint = NSPointFromCGPoint(start.layer.position);
	NSPoint endPoint = NSPointFromCGPoint(end.layer.position);
	
	// draw path
	CGFloat offset = ABS(startPoint.y - endPoint.y) * 0.4; // curvage depends on vertical distance
	CGFloat controlOffsetX = offset * (startPoint.x < endPoint.x ? 1 : -1); // curve left/right
	CGFloat controlOffsetY = offset * 0.5 * (startPoint.y < endPoint.y ? 1 : -1); // curve up/down
	int controlOffsetEndXFlip = (ABS(startPoint.x - endPoint.x) > 100.0) ? -1 : 1; // approach end point from closer side if further away
	[path moveToPoint:startPoint];
	[path curveToPoint:endPoint
		 controlPoint1:NSMakePoint(startPoint.x + controlOffsetX, startPoint.y + controlOffsetY)
		 controlPoint2:NSMakePoint(endPoint.x + controlOffsetX * controlOffsetEndXFlip, endPoint.y - controlOffsetY)];
}

- (void)connectPlaylistEntries:(NSArray *)entries
					withTracks:(NSArray *)playlist
				toSimilarEntry:(LHHistoryEntry *)similarEntry
				   inPlaylists:(NSArray *)playlists
					 ascending:(BOOL)ascending
{
	NSArray *otherEntries = [similarEntry adjacentEntriesInPlaylists:playlists ascending:ascending];
	NSArray *otherPlaylist = [otherEntries valueForKey:@"track"];
	
	// loop through other playlist and try to find match
	for (NSUInteger i = 0; i < [otherEntries count]; i++)
	{
		LHHistoryEntry *otherPlaylistEntry = [otherEntries objectAtIndex:i];
		NSUInteger playlistIndex = [playlist indexOfObject:otherPlaylistEntry.track];
		
		if (playlistIndex != NSNotFound
			&& ABS(i - playlistIndex) <= PLAYLIST_DIST_MAX // ensure max. distance
			&& i == [otherPlaylist indexOfObject:otherPlaylistEntry.track]) // don't connect same track more than once
		{
			//NSLog(@"%u = %u: %@", i, playlistIndex, track.displayName);
			LHHistoryEntry *connectedEntry = [entries objectAtIndex:playlistIndex];
			
			[self addLineFrom:connectedEntry
						   to:otherPlaylistEntry
					   toPath:_playlistPath];
		}
		
	}
	//NSLog(@"=====");
}

- (void)setHighlightedNode:(CALayer *)newLayer
{
	if (_highlightedNode != newLayer)
	{
		// detect and draw lines to playlist sequences in adjacent history entries
		NSMutableSet *playlistNodes = nil;
		
		if (!_directPath && !_playlistPath) {
			_directPath = [NSBezierPath bezierPath];
			_playlistPath = [NSBezierPath bezierPath];
		} else {
			[_directPath removeAllPoints];
			[_playlistPath removeAllPoints];
		}
		
		if (newLayer) {
			LHHistoryEntry *newEntry = [newLayer valueForKey:LAYER_DATA_KEY];
			
			NSArray *playlists = [newEntry playlists];
			
			// fetch own playlist, stopping at gaps
			NSArray *entriesFwd = [newEntry adjacentEntriesInPlaylists:playlists ascending:YES];
			NSArray *entriesBack = [newEntry adjacentEntriesInPlaylists:playlists ascending:NO];
			NSArray *playlistFwd = [entriesFwd valueForKey:@"track"];
			NSArray *playlistBack = [entriesBack valueForKey:@"track"];
			
			
			// loop through other history entries for same track
			for (LHHistoryEntry *similarEntry in newEntry.track.historyEntries)
			{
				if ([similarEntry isEqual:newEntry])
					continue;
				
				// add lines to similar entry
				[self addLineFrom:newEntry
							   to:similarEntry
						   toPath:_directPath];
				
				// connect other entries' playlist (forward and backward)
				[self connectPlaylistEntries:entriesFwd
								  withTracks:playlistFwd
							  toSimilarEntry:similarEntry
								 inPlaylists:playlists
								   ascending:YES];
				[self connectPlaylistEntries:entriesBack
								  withTracks:playlistBack
							  toSimilarEntry:similarEntry
								 inPlaylists:playlists
								   ascending:NO];
			}
			
			if (self.view.showHistoryEntryWeights)
			{
				playlistNodes = [NSMutableSet setWithCapacity:entriesFwd.count + entriesBack.count + 1];
				[playlistNodes addObject:newEntry];
				[playlistNodes addObjectsFromArray:entriesFwd];
				[playlistNodes addObjectsFromArray:entriesBack];
			}
		}
		
		// highlight similar history entries
		LHHistoryEntry *oldEntry = [_highlightedNode valueForKey:LAYER_DATA_KEY];
		for (LHHistoryEntry *entry in oldEntry.track.historyEntries) {
			entry.layer.contents = [self nodeContentsForLabel:entry.track.genre];
			if (entry != self.view.document.currentHistoryEntry) // make sure playing song stays on top
				entry.layer.zPosition = kDefaultZ;
		}
		LHHistoryEntry *newEntry = [newLayer valueForKey:LAYER_DATA_KEY];
		for (LHHistoryEntry *entry in newEntry.track.historyEntries) {
			entry.layer.contents = [self nodeContentsForLabel:NODE_LABEL_HIGHLIGHT];
			entry.layer.zPosition = kHighlightZ;
		}
		
		// set size of nodes to default size
		if (self.view.showHistoryEntryWeights)
		{
			[_playlistNodes minusSet:playlistNodes];
			for (LHHistoryEntry *historyEntry in _playlistNodes) {
				[self weightNode:historyEntry];
			}
			for (LHHistoryEntry *historyEntry in playlistNodes) {
				[historyEntry.layer setValue:[NSNumber numberWithFloat:NODE_BASE_WEIGHT * self.view.nodeScaleFactor]
								  forKeyPath:@"transform.scale"];
			}
			
			_playlistNodes = playlistNodes;
		}
		
		// update view
		_highlightedNode = newLayer;
		[self setNeedsDisplay];
	}
}

- (void)mouseMoved:(NSEvent *)theEvent onLayer:(CALayer *)hitLayer
{
	// ignore mouse-moved when shift key is pressed
	if (!([theEvent modifierFlags] & NSShiftKeyMask))
	{
		CALayer *node = nil;
		id hitData = [hitLayer valueForKey:LAYER_DATA_KEY];
		if ([hitData isKindOfClass:[[self class] nodeClass]] && ![hitData hidden])
			node = hitLayer;
		
		// set highlighted node after slight delay to avoid excess calculations
		// of similar entries while moving the mouse
		[[self class] cancelPreviousPerformRequestsWithTarget:self];
		[self performSelector:@selector(setHighlightedNode:)
				   withObject:node
				   afterDelay:0.05];
	}
}


#pragma mark -
#pragma mark Utilities

- (CGPoint)nodePositionForHistoryEntry:(LHHistoryEntry *)historyEntry
{
	CGFloat layerHeight = self.bounds.size.height - HISTORY_PADDING_Y*2;
	CGFloat positionY = ((CGFloat)historyEntry.timeValue/SECONDS_PER_DAY) * layerHeight;
	return CGPointMake([self.view xPositionForDate:historyEntry.day], layerHeight - positionY + HISTORY_PADDING_Y);
}

- (id)nodeContentsForLabel:(NSString *)label
{
	static NSArray *genreColors = nil;
	if (!genreColors) {
		genreColors = [NSArray arrayWithObjects:
							 [NSColor colorWithCalibratedHue:0.084 saturation:1.0 brightness:1.0 alpha:1.0],
							 [NSColor colorWithCalibratedHue:0.167 saturation:1.0 brightness:1.0 alpha:1.0],
							 [NSColor colorWithCalibratedHue:0.333 saturation:1.0 brightness:1.0 alpha:1.0],
							 [NSColor colorWithCalibratedHue:0.500 saturation:1.0 brightness:1.0 alpha:1.0],
							 [NSColor colorWithCalibratedHue:0.667 saturation:1.0 brightness:1.0 alpha:1.0],
							 [NSColor colorWithCalibratedHue:0.790 saturation:1.0 brightness:1.0 alpha:1.0],
							 [NSColor colorWithCalibratedHue:0.916 saturation:1.0 brightness:1.0 alpha:1.0],
							 nil];
	}
	static NSColor *genreColorUnknown = nil;
	if (!genreColorUnknown)
		genreColorUnknown = [NSColor colorWithCalibratedWhite:.5 alpha:0.5];
	
	id result = [_nodeImages objectForKey:label];
	if (!result)
	{
		NSColor *color;
		if ([label isEqualToString:NODE_LABEL_HIGHLIGHT]) {
			color = [NSColor colorWithCalibratedRed:1.0 green:0.0 blue:0.0 alpha:1.0];
		} else if ([label isEqualToString:TRACK_GENRE_UNKNOWN]) {
			color = genreColorUnknown;
		} else { // default
			NSUInteger genreIndex = [LHTrack genreIndexForGenre:label];
			if (genreIndex < [genreColors count]) {
				color = [genreColors objectAtIndex:genreIndex];
			} else {
				NSLog(@"Unknown node color for label: %@", label);
				color = genreColorUnknown;
			}
		}
		
		NSImage *nodeImage = [[NSImage alloc] initWithSize:NSMakeSize(NODE_BASE_SIZE, NODE_BASE_SIZE)];
		[nodeImage lockFocus];
		[color setFill];
		[[NSBezierPath bezierPathWithOvalInRect:NSMakeRect(0.0, 0.0, NODE_BASE_SIZE, NODE_BASE_SIZE)] fill];
		[nodeImage unlockFocus];
		result = (id)[nodeImage cgImage];
		
		if (!_nodeImages)
			_nodeImages = [NSMutableDictionary dictionaryWithCapacity:10];
		[_nodeImages setObject:result forKey:label];
	}
	
	return result;
}

- (void)weightNode:(LHHistoryEntry *)historyEntry
{
	float weightFactor = MAX(NODE_MIN_WEIGHT, MIN(NODE_MAX_WEIGHT, self.view.showHistoryEntryWeights ? [historyEntry weightValue] : NODE_BASE_WEIGHT));
	weightFactor *= self.view.nodeScaleFactor;
	[historyEntry.layer setValue:[NSNumber numberWithFloat:weightFactor] forKeyPath:@"transform.scale"];
}

@end
