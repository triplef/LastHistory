//
//  LHHistoryView.m
//  LastHistory
//
//  Created by Frederik Seiffert on 05.10.09.
//  Copyright 2009 Frederik Seiffert. All rights reserved.
//

#import "LHHistoryView.h"

#import <CalendarStore/CalendarStore.h>

#import "LHCommonMacros.h"
#import "LHDocument.h"

#import "LHListeningHistoryStream.h"
#import "LHCalendarStream.h"
#import "LHPhotoStream.h"
#import "LHEventViewerLayer.h"

#import "LHTrack.h"
#import "LHArtist.h"
#import "LHAlbum.h"
#import "LHHistoryEntry.h"
#import "LHEvent.h"
#import "LHiPhotoRoll.h"
#import "LHTimeEvent.h"
#import "CalEvent+LHEvent.h"
#import "NSImage-Extras.h"


#define TIME_SCALE_FACTOR_MIN 0.1
#define TIME_SCALE_FACTOR_MAX 20.0

#define TIME_SCALE_FACTOR_INCREASE 0.1
#define NODE_SCALE_FACTOR_INCREASE 0.5

#define SCROLL_END_PADDING 20.0

#define YEAR_POSITION_Y 8.0
#define LABELS_X_HEIGHT 40.0
#define LABELS_Y_WIDTH 30.0

#define CROSSHAIR_ALPHA .1

#define LISTENING_HISTORY_STREAM @"listeningHistoryStream"
#define CALENDAR_STREAM @"calendarStream"
#define PHOTO_STREAM @"photoStream"


@interface LHHistoryView ()
- (void)setCurrentEvent:(id <LHEvent, NSObject>)event;

- (void)setupStreams;
- (void)setupReferenceStreams;
- (void)generateLabels;
- (void)repositionCurrentEventLayer;
- (NSAttributedString *)infoStringForLayerData:(id)data;
@end


@implementation LHHistoryView

@synthesize document;

@synthesize timeScaleFactor=_timeScaleFactor;
@synthesize nodeScaleFactor=_nodeScaleFactor;
@synthesize showHistoryEntryWeights=_showHistoryEntryWeights;
@synthesize flipTimeline=_flipTimeline;
@synthesize showReferenceStreams=_showReferenceStreams;

@synthesize highlightedEvent=_highlightedEvent;
@synthesize mouseOverLayer=_mouseOverLayer;


- (void)awakeFromNib
{
	// set initial values
	self.timeScaleFactor = 0.8;
	self.nodeScaleFactor = 5.0;
	self.showHistoryEntryWeights = NO;
	self.flipTimeline = NO;
	self.showReferenceStreams = NO;
	
	[self addObserver:self forKeyPath:@"timeScaleFactor" options:0 context:NULL];
	[self addObserver:self forKeyPath:@"flipTimeline" options:0 context:NULL];
	[self addObserver:self forKeyPath:@"showReferenceStreams" options:0 context:NULL];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didResize:) name:NSWindowDidResizeNotification object:self.window];
	
	// add tracking area for mouse moved events
	NSTrackingArea *trackingArea = [[NSTrackingArea alloc] initWithRect:NSZeroRect
																options:(NSTrackingMouseMoved | NSTrackingActiveInActiveApp | NSTrackingInVisibleRect)
																  owner:self
															   userInfo:NULL];
	[self addTrackingArea:trackingArea];
}

// called by LHDocument when window controller is loaded
- (void)windowControllerDidLoad
{
	[self.document addObserver:self forKeyPath:@"historyEntries" options:NSKeyValueObservingOptionInitial context:NULL];
	[self.document addObserver:self forKeyPath:@"currentEvent" options:(NSKeyValueObservingOptionNew) context:NULL];	
}

- (void)layoutIfNeeded
{
	LHListeningHistoryStream *listeningHistory = (LHListeningHistoryStream *)[self streamWithName:LISTENING_HISTORY_STREAM];
	
	// reset highlights
	CALayer *mouseOverLayer = self.mouseOverLayer;
	id <LHEvent> highlightedEvent = self.highlightedEvent;
	CALayer *highlightedHistoryLayer = listeningHistory.highlightedNode;
	self.mouseOverLayer = nil;
	self.highlightedEvent = nil;
	listeningHistory.highlightedNode = nil;
	
	[CATransaction begin];
	[CATransaction setValue:(id)kCFBooleanTrue forKey:kCATransactionDisableActions];
	
	// reposition labels, history entry nodes and calendar
	[self generateLabels];
	[self.layer layoutSublayers];
	[self.streams makeObjectsPerformSelector:@selector(layoutSublayers)];
	
	// reposition current event highlight
	if (_currentEventHighlightLayer.superlayer)
		[self repositionCurrentEventLayer];
	
	[CATransaction commit];
	
	// re-calculate highlights
	self.mouseOverLayer = mouseOverLayer;
	self.highlightedEvent = highlightedEvent;
	listeningHistory.highlightedNode = highlightedHistoryLayer;
	
	LHHistoryEntry *highlightedNode = [highlightedHistoryLayer valueForKey:LAYER_DATA_KEY];
	[self scrollToDate:highlightedNode.timestamp];
}

- (void)insertObjectsWithIDs:(NSSet *)objectIDs
{
	NSManagedObjectContext *context = [self.document managedObjectContext];
	
	for (NSManagedObjectID *objectID in objectIDs)
	{
		NSManagedObject *object = [context objectWithID:objectID];
		[(LHListeningHistoryStream *)[self streamWithName:LISTENING_HISTORY_STREAM] insertObject:object];
	}
}

- (void)updateObjectsWithIDs:(NSSet *)objectIDs
{
	NSManagedObjectContext *context = [self.document managedObjectContext];
	
	for (NSManagedObjectID *objectID in objectIDs)
	{
		NSManagedObject *object = [context objectWithID:objectID];
		[context refreshObject:object mergeChanges:YES];
		[(LHListeningHistoryStream *)[self streamWithName:LISTENING_HISTORY_STREAM] updateObject:object];
	}
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
	if ([keyPath isEqualToString:@"timeScaleFactor"])
	{
		[self layoutIfNeeded];
	}
	else if ([keyPath isEqualToString:@"flipTimeline"])
	{
		// reset start/end dates
		_timelineStart = nil;
		_timelineEnd = nil;
		[self layoutIfNeeded];
	}
	else if ([keyPath isEqualToString:@"showReferenceStreams"])
	{
		[self setupReferenceStreams];
	}
	else if ([keyPath isEqualToString:@"historyEntries"])
	{
		[CATransaction begin];
		[CATransaction setValue:(id)kCFBooleanTrue forKey:kCATransactionDisableActions];
		
		if (!_scrollLayer) {
			// first update of history entries => setup view and all streams
			[self setupStreams];
		} else {
			// subsequent update of history entries => update history entries stream
			[[self streamWithName:LISTENING_HISTORY_STREAM] generateNodes];
		}
		
		[CATransaction commit];
	}
	else if ([keyPath isEqualToString:@"currentEvent"]) // highlighting of current event
	{
		id <LHEvent, NSObject> event = [change objectForKey:NSKeyValueChangeNewKey];
		[self setCurrentEvent:event];
	}
}

- (BOOL)enterFullScreenMode:(NSScreen *)screen withOptions:(NSDictionary *)options
{
	BOOL result = [super enterFullScreenMode:screen withOptions:options];
	[self layoutIfNeeded];
	return result;
}

- (void)exitFullScreenModeWithOptions:(NSDictionary *)options
{
	[super exitFullScreenModeWithOptions:options];
	[self layoutIfNeeded];
}

#pragma mark -
#pragma mark Setters & Actions

- (NSDate *)timelineStart
{
	if (!_timelineStart)
		_timelineStart = self.flipTimeline ? self.document.lastHistoryEntry.day : self.document.firstHistoryEntry.day;
	return _timelineStart;
}

- (NSDate *)timelineEnd
{
	if (!_timelineEnd)
		_timelineEnd = self.flipTimeline ? self.document.firstHistoryEntry.day : self.document.lastHistoryEntry.day;
	return _timelineEnd;
}

- (void)setTimeScaleFactor:(float)value
{
	// make sure value is within bounds
	_timeScaleFactor = MIN(TIME_SCALE_FACTOR_MAX, MAX(TIME_SCALE_FACTOR_MIN, value));
}

- (IBAction)increaseTimeScaleFactor:(id)sender
{
	self.timeScaleFactor += TIME_SCALE_FACTOR_INCREASE;
}

- (IBAction)decreaseTimeScaleFactor:(id)sender
{
	self.timeScaleFactor -= TIME_SCALE_FACTOR_INCREASE;
}

- (IBAction)increaseNodeScaleFactor:(id)sender
{
	self.nodeScaleFactor += NODE_SCALE_FACTOR_INCREASE;
}

- (IBAction)decreaseNodeScaleFactor:(id)sender
{
	self.nodeScaleFactor -= NODE_SCALE_FACTOR_INCREASE;
}

- (void)scrollToDate:(NSDate *)date
{
	if (date)
	{
		CGPoint position = _scrollLayer.bounds.origin;
		if ([date isEqualToDate:self.document.firstHistoryEntry.timestamp]) {
			position.x = STREAM_PADDING_X - LABELS_Y_WIDTH - SCROLL_END_PADDING;
		} else if ([date isEqualToDate:self.document.lastHistoryEntry.timestamp]) {
			position.x = [self xPositionForDate:date] - _scrollLayer.bounds.size.width + SCROLL_END_PADDING;
		} else {
			position.x = [self xPositionForDate:date] - (_scrollLayer.bounds.size.width / 2.0);
		}
		[_scrollLayer scrollToPoint:position];
	}
}

- (void)setCurrentEvent:(id <LHEvent, NSObject>)event
{
	if (event && ![[NSNull null] isEqual:event])
	{
		[_currentEventHighlightLayer setValue:event forKey:LAYER_DATA_KEY];
		[self repositionCurrentEventLayer];
		
		[_currentEventHighlightLayer removeAllAnimations];
		[_currentEventHighlightLayer addAnimation:[CATransition animation] forKey:nil]; // fade-in animation
	}
	else
	{
		[_currentEventHighlightLayer removeFromSuperlayer];
	}
	
	// full-size event viewing
	[_currentEventViewerLayer removeFromSuperlayer];
	if ([event isKindOfClass:[LHiPhotoRoll class]])
	{
		LHEventViewerLayer *viewerLayer = [LHEventViewerLayer layerWithPhotoRoll:event];
		viewerLayer.zPosition = kTopZ;
		
		_scrollLayer.hidden = YES;
		_currentEventViewerLayer = viewerLayer;
		[self.layer addSublayer:viewerLayer];
	}
	else
	{
		BOOL wasShowing = _currentEventViewerLayer != nil;
		_scrollLayer.hidden = NO;
		_currentEventViewerLayer = nil;
		
		// layout again in case we were resized during full-size viewing
		if (wasShowing)
			[self layoutIfNeeded];
	}
}

- (void)setHighlightedEvent:(id <LHEvent>)newEvent
{
	if (_highlightedEvent != newEvent)
	{
		// highlight event on the timeline
		if (newEvent)
		{
			CGFloat startPoint = [self xPositionForDate:self.flipTimeline ? newEvent.eventEnd : newEvent.eventStart];
			CGFloat endPoint = [self xPositionForDate:self.flipTimeline ? newEvent.eventStart : newEvent.eventEnd];
			
			CGRect bounds = _eventHighlightLayer.bounds;
			bounds.size.width = endPoint - startPoint;
			_eventHighlightLayer.bounds = bounds;
			_eventHighlightLayer.position = CGPointMake(startPoint, _eventHighlightLayer.position.y);
			_eventHighlightLayer.hidden = NO;
		}
		else
		{
			_eventHighlightLayer.hidden = YES;
		}
		
		_highlightedEvent = newEvent;
	}
}

- (void)setMouseOverLayer:(CALayer *)newLayer
{
	if (_mouseOverLayer != newLayer)
	{
		id newData = [newLayer valueForKey:LAYER_DATA_KEY];
		id lastInfoData = [_infoLayer valueForKey:LAYER_DATA_KEY];
		if (newLayer && ![newData isEqual:lastInfoData])
		{
			NSAttributedString *infoString = [self infoStringForLayerData:newData];
			NSSize infoStringSize = infoString.size;
			_infoLayer.bounds = CGRectMake(0, 0, infoStringSize.width, infoStringSize.height);
			[_infoLayer removeAllAnimations];
			_infoLayer.string = infoString;
			
			// make sure info is visible even when we are close to the top border
//			BOOL overlappingTopBorder = (hitPoint.y > CGRectGetMaxY(_scrollLayer.bounds) - infoStringSize.height);
//			BOOL overlappingRightBorder = (hitPoint.x > CGRectGetMaxX(_scrollLayer.bounds) - 200); // hard-coded info string width, otherwise the info box moves around too much
//			_infoLayer.anchorPoint = CGPointMake(overlappingRightBorder ? 1 : 0, overlappingTopBorder ? 1 : 0);
			
			// set position below/right of layer position as to not obscure cursor
			CGPoint position = CGPointMake(CGRectGetMaxX(newLayer.frame), CGRectGetMaxY(newLayer.frame));
			if ([newLayer.superlayer isKindOfClass:[LHListeningHistoryStream class]]) {
				position = newLayer.position;
				position.x += 8.0;
				position.y -= 12.0;
			}
			_infoLayer.position = [_scrollLayer convertPoint:position fromLayer:newLayer.superlayer];
			
			[_infoLayer setValue:newData forKey:LAYER_DATA_KEY];
			_infoLayer.hidden = NO;
		}
		else if (!newLayer)
		{
			[_infoLayer setValue:nil forKey:LAYER_DATA_KEY];
			_infoLayer.hidden = YES;
		}
		
		_mouseOverLayer = newLayer;
	}
}

- (NSSet *)streams
{
	NSMutableSet *result = [NSMutableSet setWithCapacity:_scrollLayer.sublayers.count];
	for (CALayer *layer in _scrollLayer.sublayers)
	{
		if ([layer isKindOfClass:[LHStreamLayer class]])
			[result addObject:layer];
	}
	return result;
}

- (LHStreamLayer *)streamWithName:(NSString *)name
{
	for (CALayer *layer in _scrollLayer.sublayers)
	{
		if ([layer isKindOfClass:[LHStreamLayer class]] && [layer.name isEqualToString:name])
			return (LHStreamLayer *)layer;
	}
	return nil;
}


#pragma mark -
#pragma mark Event Handling

- (CALayer *)hitLayerForEvent:(NSEvent *)theEvent hitPoint:(CGPoint *)outHitPoint
{
	// convert mouse coordianates
	CGPoint mousePointInView = NSPointToCGPoint([self convertPoint:theEvent.locationInWindow fromView:nil]);
	CGPoint mousePointInScrollLayer = [self.layer convertPoint:mousePointInView toLayer:_scrollLayer];
	
	if (outHitPoint)
		*outHitPoint = mousePointInScrollLayer;
	
	// check history entries and calendar layers for data
	CALayer *hitLayer = [[self streamWithName:PHOTO_STREAM] hitTest:mousePointInScrollLayer];
	if (!hitLayer)
		hitLayer = [[self streamWithName:CALENDAR_STREAM] hitTest:mousePointInScrollLayer];
	if (!hitLayer)
		hitLayer = [[self streamWithName:LISTENING_HISTORY_STREAM] hitTest:mousePointInScrollLayer];
	
	return hitLayer;
}

- (BOOL)mouseDownCanMoveWindow
{
	return NO;
}

- (BOOL)acceptsFirstResponder
{
	return YES;
}

- (void)didResize:(NSNotification *)notification
{
	// resize in next run-loop run, as at this point our layer hasn't update its size yet
	if (![self inLiveResize])
		[self performSelector:@selector(layoutIfNeeded) withObject:nil afterDelay:0.0];
}

- (void)viewDidEndLiveResize
{
	[self performSelector:@selector(layoutIfNeeded) withObject:nil afterDelay:0.0];
}

- (void)keyDown:(NSEvent *)theEvent
{
	if (theEvent.keyCode == 53) // escape
	{
		if ([self isInFullScreenMode]) {
			// exit full-screen mode
			[self exitFullScreenModeWithOptions:nil];
		} else {
			// stop / exit event viewing mode
			[self.document stop:nil];
		}
	} else {
		[super keyDown:theEvent];
	}
}

- (void)magnifyWithEvent:(NSEvent *)theEvent
{
	CGFloat scaleDelta = theEvent.deltaZ * 0.01;
	self.timeScaleFactor += scaleDelta;
}

- (void)scrollWheel:(NSEvent *)theEvent
{
//	NSLog(@"x: %f, y: %f", theEvent.deltaX, theEvent.deltaY);
	
	// vertical: zooming
//	if (fabs(theEvent.deltaY) >= 1.0)
//	{
//		CGFloat scaleDelta = theEvent.deltaY * 0.1;
//		self.timeScaleFactor = self.timeScaleFactor + scaleDelta;
//	}
	
	// horizontal: scrolling
	if (fabs(theEvent.deltaX) >= 0.0)
	{
		CGPoint position = _scrollLayer.bounds.origin;
		position.x -= theEvent.deltaX * 5.0;
		[_scrollLayer scrollToPoint:position];
	}
}

- (void)mouseDown:(NSEvent *)theEvent
{
	// ignore in viewing mode
	if (_currentEventViewerLayer)
		return;
	
	CGPoint mousePointInView = NSPointToCGPoint([self convertPoint:theEvent.locationInWindow fromView:nil]);
	CGPoint mousePointInScrollLayer = [self.layer convertPoint:mousePointInView toLayer:_scrollLayer];
	
	BOOL rightClick = (theEvent.modifierFlags & NSControlKeyMask) || theEvent.type == NSRightMouseDown;
	BOOL selectionX = [_labelsLayerX hitTest:mousePointInScrollLayer] != nil;
	BOOL selectionY = [_labelsLayerY hitTest:mousePointInView] != nil;
	
	if (rightClick || selectionX || selectionY)
	{
		// create time selection layer
		_selectionRectLayer = [CALayer layer];
		_selectionRectLayer.backgroundColor = (CGColorRef) CFMakeCollectable(CGColorCreateGenericGray(0, .1));
		
		// set autoresize mask to indicate type of time selection
		NSUInteger autoresizingMask = kCALayerNotSizable;
		CGPoint position = mousePointInView;
		CGSize size = self.layer.bounds.size;
		if (rightClick) {
			autoresizingMask = kCALayerHeightSizable | kCALayerWidthSizable;
			size = CGSizeMake(1, 1);
		} else if (selectionX) {
			autoresizingMask = kCALayerWidthSizable;
			position.y = CGRectGetMaxY(self.layer.bounds);
			size.width = 1;
		} else if (selectionY) {
			autoresizingMask = kCALayerHeightSizable;
			position.x = 0;
			size.height = 1;
		}
		
		_selectionRectLayer.anchorPoint = CGPointMake(0, 1); // top-left
		_selectionRectLayer.bounds = CGRectMake(0, 0, size.width, size.height);
		_selectionRectLayer.autoresizingMask = autoresizingMask;
		_selectionRectLayer.position = position;
		
		[self.layer addSublayer:_selectionRectLayer];
	}
}

- (void)mouseUp:(NSEvent *)theEvent
{
	if (_currentEventViewerLayer)
	{
		// convert mouse coordianates
		CGPoint mousePointInView = NSPointToCGPoint([self convertPoint:theEvent.locationInWindow fromView:nil]);
		CGPoint mousePointInLayer = [self.layer convertPoint:mousePointInView toLayer:_currentEventViewerLayer];
		
		if (![_currentEventViewerLayer handleMouseUpAtPoint:mousePointInLayer])
			[self.document stop:nil]; // exit viewer
	}
	else if (_selectionRectLayer)
	{
		// play time selection
		NSInteger startTime = LH_EVENT_TIME_UNDEFINED, endTime = LH_EVENT_TIME_UNDEFINED;
		NSDate *startDate = nil, *endDate = nil;
		
		if (_selectionRectLayer.autoresizingMask & kCALayerHeightSizable)
		{
			CGFloat startPoint = CGRectGetMaxY(_labelsLayerY.frame) - _selectionRectLayer.position.y;
			CGFloat endPoint = startPoint + _selectionRectLayer.bounds.size.height;
			CGFloat dayHeight = _labelsLayerY.bounds.size.height;
			
			startTime = (startPoint / dayHeight) * SECONDS_PER_DAY;
			endTime = (endPoint / dayHeight) * SECONDS_PER_DAY;
		}
		if (_selectionRectLayer.autoresizingMask & kCALayerWidthSizable)
		{
			CGFloat startPoint = CGRectGetMinX(_scrollLayer.bounds) + _selectionRectLayer.position.x - STREAM_PADDING_X;
			CGFloat endPoint = startPoint + _selectionRectLayer.bounds.size.width;
			
			if (self.flipTimeline)
				swap((void *)&startPoint, (void *)&endPoint);
			
			NSTimeInterval referenceDate = [self.timelineStart timeIntervalSinceReferenceDate];
			startDate = [NSDate dateWithTimeIntervalSinceReferenceDate:referenceDate + (startPoint / (self.timeScaleFactor / SECONDS_PER_DAY)) * (self.flipTimeline ? -1.0: 1.0)];
			endDate = [NSDate dateWithTimeIntervalSinceReferenceDate:referenceDate + (endPoint / (self.timeScaleFactor / SECONDS_PER_DAY)) * (self.flipTimeline ? -1.0: 1.0)];
		}
		
		LHTimeEvent *event = [[LHTimeEvent alloc] initWithStartDate:startDate endDate:endDate startTime:startTime endTime:endTime];
		[self.document playHistoryEntriesForEvent:event];
		
		[_selectionRectLayer removeFromSuperlayer];
		_selectionRectLayer = nil;
	}
	else if (!isDragging)
	{
		// play song or event
		BOOL success = NO;
		CALayer *hitLayer = [self hitLayerForEvent:theEvent hitPoint:NULL];
		id hitData = [hitLayer valueForKey:LAYER_DATA_KEY];
		
		if ([hitData isKindOfClass:[LHHistoryEntry class]]) {
			LHHistoryEntry *historyEntry = (LHHistoryEntry *)hitData;
			success = [self.document playHistoryEntry:historyEntry];
		} else if ([hitData conformsToProtocol:@protocol(LHEvent)]) {
			id <LHEvent> event = hitData;
			success = [self.document playHistoryEntriesForEvent:event];
		} else {
			[self.document stop:nil];
			success = YES;
		}
		
		// start shake animation if failed to play song
		if (!success)
		{
			CAKeyframeAnimation *shakeAnimation = [CAKeyframeAnimation animationWithKeyPath:@"position.x"];
			const CGFloat delta = 5.0;
			shakeAnimation.values = [NSArray arrayWithObjects:
									 [NSNumber numberWithFloat:-delta], [NSNumber numberWithFloat:delta],
									 [NSNumber numberWithFloat:-delta], [NSNumber numberWithFloat:delta],
									 [NSNumber numberWithFloat:0.0], nil];
			shakeAnimation.duration = .5;
			shakeAnimation.additive = YES;
			[hitLayer addAnimation:shakeAnimation forKey:@"playingFailAnimation"];
		}
	}
	
	isDragging = NO;
	_crosshairXLayer.hidden = NO;
	_crosshairYLayer.hidden = NO;
}

- (void)mouseDragged:(NSEvent *)theEvent
{
	isDragging = YES;
	_crosshairXLayer.hidden = YES;
	_crosshairYLayer.hidden = YES;
	
	if (_selectionRectLayer)
	{
		NSPoint mousePoint = [self convertPoint:theEvent.locationInWindow fromView:nil];
		CGSize newSize = _selectionRectLayer.bounds.size;
		
		if (_selectionRectLayer.autoresizingMask & kCALayerHeightSizable) {
			CGFloat startPoint = _selectionRectLayer.position.y;
			CGFloat dayMax = _labelsLayerY.position.y;
			newSize.height = MAX(dayMax, mousePoint.y) - startPoint;
		}
		if (_selectionRectLayer.autoresizingMask & kCALayerWidthSizable) {
			CGFloat startPoint = _selectionRectLayer.position.x;
			newSize.width = mousePoint.x - startPoint;
		}
		
		_selectionRectLayer.bounds = CGRectMake(0, 0, newSize.width, newSize.height);
	}
	else if (fabs(theEvent.deltaX) > 0.0)
	{
		CGPoint position = _scrollLayer.bounds.origin;
		position.x -= theEvent.deltaX;
		[_scrollLayer scrollToPoint:position];
	}
}

- (void)mouseMoved:(NSEvent *)theEvent
{
	CGPoint hitPoint;
	CALayer *hitLayer = [self hitLayerForEvent:theEvent hitPoint:&hitPoint];
	
	// crosshair handling
	
	_crosshairXLayer.position = CGPointMake(_crosshairXLayer.position.x, hitPoint.y);
	_crosshairYLayer.position = CGPointMake(hitPoint.x, _crosshairYLayer.position.y);
	
	// notify streams
	
	for (LHStreamLayer *stream in self.streams)
		[stream mouseMoved:theEvent onLayer:hitLayer];
	
	// mouse-over handling
	
	CALayer *newMouseOverLayer = nil;
	id <LHEvent> newHighlightedEvent = nil;
	
	id hitData = [hitLayer valueForKey:LAYER_DATA_KEY];
	BOOL hitDataHidden = [hitData respondsToSelector:@selector(hidden)] && [hitData hidden];
	if (hitData && !hitDataHidden && ![hitLayer isKindOfClass:[LHListeningHistoryStream class]])
	{
		newMouseOverLayer = hitLayer;
		
		// highlight current event
		if ([hitData conformsToProtocol:@protocol(LHEvent)])
			newHighlightedEvent = hitData;
	}
	
	// change layers according to mouse-over information
	self.mouseOverLayer = newMouseOverLayer;
	self.highlightedEvent = newHighlightedEvent;
}

- (void)rightMouseDown:(NSEvent *)theEvent
{
	// forward
	[self mouseDown:theEvent];
}

- (void)rightMouseUp:(NSEvent *)theEvent
{
	// forward
	[self mouseUp:theEvent];
}

- (void)rightMouseDragged:(NSEvent *)theEvent
{
	// forward
	[self mouseDragged:theEvent];
}


#pragma mark -
#pragma mark View Utilities

- (CGFloat)xPositionForDate:(NSDate *)date
{
	NSTimeInterval time = self.flipTimeline ? [self.timelineStart timeIntervalSinceDate:date] : [date timeIntervalSinceDate:self.timelineStart];
	return time * (self.timeScaleFactor / SECONDS_PER_DAY) + STREAM_PADDING_X;
}

- (CGFloat)yPositionForTime:(NSInteger)time
{
	return (_labelsLayerY.bounds.size.height / SECONDS_PER_DAY) * (SECONDS_PER_DAY - time);
}


#pragma mark -
#pragma mark Drawing

- (void)setupStreams
{
	// make the view layer-backed
	CALayer *mainLayer = self.layer;
	mainLayer.name = @"mainLayer";
	mainLayer.backgroundColor = (CGColorRef) CFMakeCollectable(CGColorCreateGenericGray(1.0, 1.0));
	mainLayer.layoutManager = [CAConstraintLayoutManager layoutManager]; // for viewing layer
	
	if (!self.document.firstHistoryEntry)
		return;
	
	CGFloat layerWidth = mainLayer.bounds.size.width;
	
	// create scroll layer
	_scrollLayer = [CAScrollLayer layer];
	_scrollLayer.name = @"scrollLayer";
	_scrollLayer.scrollMode = kCAScrollHorizontally;
	_scrollLayer.autoresizingMask = (kCALayerWidthSizable | kCALayerHeightSizable);
	_scrollLayer.anchorPoint = CGPointMake(0, 0); // make bounds origin at lower-left corner
	_scrollLayer.bounds = mainLayer.bounds;
	_scrollLayer.layoutManager = [CAConstraintLayoutManager layoutManager];
	[mainLayer addSublayer:_scrollLayer];
	
	// create container layers for labels, history entries and calendar entries
	_labelsLayerX = [CALayer layer];
//	_labelsLayerX.backgroundColor = (CGColorRef) CFMakeCollectable(CGColorCreateGenericGray(0, .2));
	_labelsLayerX.name = @"labelsLayerX";
	_labelsLayerX.anchorPoint = CGPointMake(0, 0);
	_labelsLayerX.bounds = CGRectMake(0, 0, layerWidth, LABELS_X_HEIGHT);
	[_labelsLayerX addConstraint:[CAConstraint constraintWithAttribute:kCAConstraintMinY relativeTo:@"superlayer" attribute:kCAConstraintMinY]];
	[_labelsLayerX addConstraint:[CAConstraint constraintWithAttribute:kCAConstraintWidth relativeTo:@"superlayer" attribute:kCAConstraintWidth]];
	[_scrollLayer addSublayer:_labelsLayerX];
	
	_labelsLayerY = [CALayer layer];
	_labelsLayerY.name = @"labelsLayerY";
	_labelsLayerY.anchorPoint = CGPointMake(0, 0);
	_labelsLayerY.autoresizingMask = kCALayerMinYMargin;
	_labelsLayerY.contentsGravity = kCAGravityBottomLeft;
	_labelsLayerY.backgroundColor = (CGColorRef) CFMakeCollectable(CGColorCreateGenericGray(1.0, .8));
	[mainLayer addSublayer:_labelsLayerY];
	
	LHListeningHistoryStream *listeningHistoryStream = [[LHListeningHistoryStream alloc] initWithView:self];
//	listeningHistoryStream.backgroundColor = (CGColorRef) CFMakeCollectable(CGColorCreateGenericGray(0, .2));
	listeningHistoryStream.name = LISTENING_HISTORY_STREAM;
	[_scrollLayer addSublayer:listeningHistoryStream];
	
	_infoLayer = [CATextLayer layer];
	_infoLayer.name = @"infoLayer";
	_infoLayer.zPosition = kHighlightZ;
	_infoLayer.anchorPoint = CGPointMake(0, 1); // position info box below/right cursor
	_infoLayer.cornerRadius = 5.0;
	_infoLayer.backgroundColor = (CGColorRef) CFMakeCollectable(CGColorCreateGenericGray(1.0, .5));
	_infoLayer.hidden = YES;
	[_scrollLayer addSublayer:_infoLayer];
	
	_crosshairXLayer = [CALayer layer];
	_crosshairXLayer.name = @"crosshairXLayer";
	_crosshairXLayer.backgroundColor = (CGColorRef) CFMakeCollectable(CGColorCreateGenericGray(0, CROSSHAIR_ALPHA));
	_crosshairXLayer.zPosition = 1;
	_crosshairXLayer.bounds = CGRectMake(0, 0, layerWidth, 1.0);
	[_crosshairXLayer addConstraint:[CAConstraint constraintWithAttribute:kCAConstraintWidth relativeTo:@"superlayer" attribute:kCAConstraintWidth]];
	[_crosshairXLayer addConstraint:[CAConstraint constraintWithAttribute:kCAConstraintMidX relativeTo:@"superlayer" attribute:kCAConstraintMidX]];
	[_scrollLayer addSublayer:_crosshairXLayer];
	
	_crosshairYLayer = [CALayer layer];
	_crosshairYLayer.name = @"crosshairYLayer";
	_crosshairYLayer.backgroundColor = (CGColorRef) CFMakeCollectable(CGColorCreateGenericGray(0, CROSSHAIR_ALPHA));
	_crosshairYLayer.zPosition = 1;
	_crosshairYLayer.bounds = CGRectMake(0, 0, 1.0, mainLayer.bounds.size.height);
	[_crosshairYLayer addConstraint:[CAConstraint constraintWithAttribute:kCAConstraintHeight relativeTo:@"superlayer" attribute:kCAConstraintHeight]];
	[_crosshairYLayer addConstraint:[CAConstraint constraintWithAttribute:kCAConstraintMidY relativeTo:@"superlayer" attribute:kCAConstraintMidY]];
	[_scrollLayer addSublayer:_crosshairYLayer];
	
	// container layer for event highlight layers
	_highlightsLayer = [CALayer layer];
	_highlightsLayer.name = @"highlightsLayer";
	_highlightsLayer.zPosition = kHighlightLayerZ;
	_highlightsLayer.anchorPoint = CGPointMake(0, 0);
	_highlightsLayer.bounds = CGRectMake(0, 0, 1.0, 1.0);
	[_highlightsLayer addConstraint:[CAConstraint constraintWithAttribute:kCAConstraintMidY relativeTo:@"superlayer" attribute:kCAConstraintMidY]];
	[_highlightsLayer addConstraint:[CAConstraint constraintWithAttribute:kCAConstraintHeight relativeTo:@"superlayer" attribute:kCAConstraintHeight]];
	_highlightsLayer.layoutManager = [CAConstraintLayoutManager layoutManager];
	[_scrollLayer addSublayer:_highlightsLayer];
	
	// mouse-over event highlight layer
	_eventHighlightLayer = [CALayer layer];
	_eventHighlightLayer.name = @"eventHighlightLayer";
	_eventHighlightLayer.anchorPoint = CGPointMake(0, 0);
	_eventHighlightLayer.backgroundColor = (CGColorRef) CFMakeCollectable(CGColorCreateGenericGray(0.0, .15));
	_eventHighlightLayer.hidden = YES;
	[_eventHighlightLayer addConstraint:[CAConstraint constraintWithAttribute:kCAConstraintMidY relativeTo:@"superlayer" attribute:kCAConstraintMidY]];
	[_eventHighlightLayer addConstraint:[CAConstraint constraintWithAttribute:kCAConstraintHeight relativeTo:@"superlayer" attribute:kCAConstraintHeight]];
	[_highlightsLayer addSublayer:_eventHighlightLayer];
	
	// playing event highlight layer
	_currentEventHighlightLayer = [CALayer layer]; // will be added to superlayer later
	_currentEventHighlightLayer.name = @"currentEventHighlightLayer";
	_currentEventHighlightLayer.anchorPoint = CGPointMake(0, 0);
	_currentEventHighlightLayer.backgroundColor = (CGColorRef) CFMakeCollectable(CGColorCreateGenericRGB(0, 0.5, 0, .15));
	
	[self setupReferenceStreams];
	[listeningHistoryStream generateNodes];
	
	[self scrollToDate:self.document.firstHistoryEntry.timestamp];
}

- (void)setupReferenceStreams
{
	NSMutableSet *streams = [NSMutableSet setWithCapacity:2];
	
	if (self.showReferenceStreams && ![self streamWithName:CALENDAR_STREAM]) {
		LHCalendarStream *calendarStream = [[LHCalendarStream alloc] initWithView:self];
//		calendarStream.backgroundColor = (CGColorRef) CFMakeCollectable(CGColorCreateGenericGray(0, .5));
		calendarStream.name = CALENDAR_STREAM;
		[calendarStream addConstraint:[CAConstraint constraintWithAttribute:kCAConstraintMinY relativeTo:@"labelsLayerX" attribute:kCAConstraintMaxY offset:10.0]];
		[_scrollLayer addSublayer:calendarStream];
		[streams addObject:calendarStream];
	} else {
		[[self streamWithName:CALENDAR_STREAM] removeFromSuperlayer];
	}
	
	if (self.showReferenceStreams && ![self streamWithName:PHOTO_STREAM])
	{
		LHPhotoStream *photoStream = [[LHPhotoStream alloc] initWithView:self];
//		photoStream.backgroundColor = (CGColorRef) CFMakeCollectable(CGColorCreateGenericGray(0, .2));
		photoStream.name = PHOTO_STREAM;
		photoStream.zPosition = 1; // show photos above everything else
		[photoStream addConstraint:[CAConstraint constraintWithAttribute:kCAConstraintMinY relativeTo:CALENDAR_STREAM attribute:kCAConstraintMaxY offset:5.0]];
		[_scrollLayer addSublayer:photoStream];
		[streams addObject:photoStream];
	} else {
		[[self streamWithName:PHOTO_STREAM] removeFromSuperlayer];
	}
	
	// update listening history constraints
	NSArray *constraints = [NSArray arrayWithObjects:
							[CAConstraint constraintWithAttribute:kCAConstraintMinY relativeTo:(self.showReferenceStreams ? PHOTO_STREAM : @"labelsLayerX") attribute:kCAConstraintMaxY offset:10.0],
							[CAConstraint constraintWithAttribute:kCAConstraintMaxY relativeTo:@"superlayer" attribute:kCAConstraintMaxY],
							nil];
	[self streamWithName:LISTENING_HISTORY_STREAM].constraints = constraints;
	
	// run layout manager
	[_scrollLayer layoutSublayers];
	
	// create labels and streams
	[self generateLabels];
	[streams makeObjectsPerformSelector:@selector(generateNodes)];
}

- (void)generateLabels
{
	// clear all existing layers
	[[_labelsLayerX.sublayers copy] makeObjectsPerformSelector:@selector(removeFromSuperlayer)];
	
	NSCalendar *calendar = [NSCalendar currentCalendar];
	NSDate *firstDate = [calendar dateFromComponents:[calendar components:(NSYearCalendarUnit | NSMonthCalendarUnit)
																 fromDate:self.document.firstHistoryEntry.timestamp]];
	NSDate *lastDate = [calendar dateFromComponents:[calendar components:(NSYearCalendarUnit | NSMonthCalendarUnit)
																fromDate:self.document.lastHistoryEntry.timestamp]];
	if (!firstDate || !lastDate)
		return;
	
	// create month markings
	{
		NSDate *markingDate = firstDate;
		NSDateComponents *markingDateAddComps = [NSDateComponents new];
		markingDateAddComps.month = 1;
		
		NSArray *monthNames = [[NSDateFormatter new] shortStandaloneMonthSymbols];
		NSDictionary *stringAttrs = [NSDictionary dictionaryWithObjectsAndKeys:
									 [NSColor grayColor], NSForegroundColorAttributeName,
									 [NSFont systemFontOfSize:9], NSFontAttributeName, nil];
		
		const CGFloat padding = 20.0 * self.timeScaleFactor; // x-padding to avoid cutting off text at start/end
		NSSize markingImageSize = NSMakeSize([self xPositionForDate:self.timelineEnd]-STREAM_PADDING_X+(padding*2), LABELS_X_HEIGHT);
		NSImage *markingImage = [[NSImage alloc] initWithSize:markingImageSize];
		[markingImage lockFocus];
		[[NSColor grayColor] setFill];
		
		while ([markingDate compare:lastDate] == NSOrderedAscending)
		{
			NSDate *nextMarkingDate = [calendar dateByAddingComponents:markingDateAddComps toDate:markingDate options:0];
			NSInteger month = [calendar components:NSMonthCalendarUnit fromDate:markingDate].month;
			
			// draw marking
			CGFloat monthPosX = [self xPositionForDate:markingDate]-STREAM_PADDING_X+padding;
			NSRectFill(NSMakeRect(monthPosX, 0,
								  1, month == 1 ? markingImageSize.height : markingImageSize.height/4.0));
			
			// draw month name
			CGFloat monthWidth = [self xPositionForDate:nextMarkingDate]-STREAM_PADDING_X+padding - monthPosX;
			NSAttributedString *monthString = [[NSAttributedString alloc] initWithString:[monthNames objectAtIndex:(month-1)]
																			  attributes:stringAttrs];
			NSSize monthSize = [monthString size];
			[monthString drawAtPoint:NSMakePoint((monthPosX + monthWidth/2.0) - monthSize.width/2.0, 1.0)];
			
			markingDate = nextMarkingDate;
		}
		
		[markingImage unlockFocus];
		
		CALayer *markingLayer = [CALayer layer];
		markingLayer.anchorPoint = CGPointMake(0, 0);
		markingLayer.bounds = CGRectMake(0, 0, markingImageSize.width, markingImageSize.height);
		markingLayer.position = CGPointMake([self xPositionForDate:self.timelineStart]-padding, 0);
		markingLayer.contents = (id)[markingImage cgImage];
		markingLayer.contentsGravity = kCAGravityBottomLeft;
		[_labelsLayerX addSublayer:markingLayer];
	}
	
	// create year labels
	{
		NSDateComponents *dateComps = [NSDateComponents new];
		NSInteger startYear = [calendar components:NSYearCalendarUnit fromDate:firstDate].year;
		NSInteger endYear = [calendar components:NSYearCalendarUnit fromDate:lastDate].year;
		NSDictionary *stringAttrs = [NSDictionary dictionaryWithObjectsAndKeys:[NSFont boldSystemFontOfSize:24.0], NSFontAttributeName, [NSColor grayColor], NSForegroundColorAttributeName, nil];
		for (NSInteger year = startYear; year <= endYear; year++)
		{
			NSAttributedString *yearString = [[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"%d", year]
																			 attributes:stringAttrs];
			CATextLayer *layer = [CATextLayer layer];
			layer.string = yearString;
			layer.anchorPoint = CGPointMake(0.5, 0); // position string centered/above layer position
			
			NSSize yearStringSize = yearString.size;
			layer.bounds = CGRectMake(0, 0, yearStringSize.width, yearStringSize.height);
			
			// position text in the middle of the year
			dateComps.year = year;
			dateComps.month = 12/2;
			dateComps.day = 31;
			NSDate *date = [calendar dateFromComponents:dateComps];
			layer.position = CGPointMake([self xPositionForDate:date], YEAR_POSITION_Y);
			
			[_labelsLayerX addSublayer:layer];
		}
	}
	
	// create day-hour labels
	{
		_labelsLayerY.bounds = CGRectMake(0, 0, LABELS_Y_WIDTH, [self streamWithName:LISTENING_HISTORY_STREAM].bounds.size.height - HISTORY_PADDING_Y*2);
		_labelsLayerY.position = CGPointMake(0, ([self streamWithName:LISTENING_HISTORY_STREAM]).position.y + HISTORY_PADDING_Y);
		
		NSSize markingImageSize = NSSizeFromCGSize(_labelsLayerY.bounds.size);
		NSImage *markingImage = [[NSImage alloc] initWithSize:markingImageSize];
		[markingImage lockFocus];
		[[NSColor grayColor] setFill];
		for (NSUInteger hour = 1; hour <= 24; hour++)
		{
			CGFloat positionY = [self yPositionForTime:hour*SECONDS_PER_HOUR];
			NSRectFill(NSMakeRect(0.0, positionY, markingImageSize.width, 1.0));
			
			NSString *label = [NSString stringWithFormat:@"%u h", hour];
			[label drawAtPoint:NSMakePoint(2.0, positionY + 2.0)
				withAttributes:[NSDictionary dictionaryWithObjectsAndKeys:[NSColor grayColor], NSForegroundColorAttributeName, nil]];
		}
		[markingImage unlockFocus];
		
		_labelsLayerY.contents = (id)[markingImage cgImage];
	}
}

- (void)repositionCurrentEventLayer
{
	id <LHEvent> event = [_currentEventHighlightLayer valueForKey:LAYER_DATA_KEY];
	CALayer *superlayer = nil;
	CGPoint position = CGPointZero;
	CGSize size = _scrollLayer.bounds.size;
	
	if (event.eventStartTime != LH_EVENT_TIME_UNDEFINED && event.eventEndTime != LH_EVENT_TIME_UNDEFINED) {
		CGFloat endPosition = [self yPositionForTime:event.eventEndTime];
		position.y = _labelsLayerY.position.y + endPosition;
		size.height = [self yPositionForTime:event.eventStartTime] - endPosition;
		superlayer = self.layer;
	}
	if (event.eventStart && event.eventEnd) {
		NSDate *left = self.flipTimeline ? event.eventEnd : event.eventStart;
		NSDate *right = self.flipTimeline ? event.eventStart : event.eventEnd;
		position.x = [self xPositionForDate:left];
		size.width = [self xPositionForDate:right] - position.x;
		superlayer = _highlightsLayer;
	}
	
	if (_currentEventHighlightLayer.superlayer != superlayer) {
		[_currentEventHighlightLayer removeFromSuperlayer];
		[superlayer addSublayer:_currentEventHighlightLayer];
	}
	
	_currentEventHighlightLayer.bounds = CGRectMake(0, 0, size.width, size.height);
	_currentEventHighlightLayer.position = position;
}

- (NSAttributedString *)infoStringForLayerData:(id)data
{
	NSString *infoStringText = nil;
	NSRange infoStringLargeRange = NSMakeRange(0, 0);
	NSRange infoStringSmallRange = NSMakeRange(0, 0);
	NSRange infoStringBoldRange = NSMakeRange(0, 0);
	NSDateFormatter *outputFormatter = [NSDateFormatter new];
	[outputFormatter setDateStyle:NSDateFormatterFullStyle];
	
	if ([data isKindOfClass:[LHHistoryEntry class]])
	{
		LHHistoryEntry *historyEntry = (LHHistoryEntry *)data;
		LHTrack *track = historyEntry.track;
		[outputFormatter setTimeStyle:NSDateFormatterMediumStyle];
		
		NSString *titleText = [NSString stringWithFormat:@"%@\n%@", track.name, track.artist.name];
		NSString *text = [NSString stringWithFormat:@"%@\n%@%@%@\nPlays: %u, Weight: %.2f\nGenre: %@\n",
						  titleText, 
						  (track.album ? track.album.name : @""), (track.album ? @"\n" : @""),
						  [outputFormatter stringFromDate:historyEntry.timestamp],
						  track.trackCount, [historyEntry weightValue],
						  track.genre];
		NSString *smallText = [NSString stringWithFormat:@"Tags: %@", [track tagsStringWrappedAt:80]];
		infoStringText = [text stringByAppendingString:smallText];
		infoStringLargeRange = NSMakeRange(0, titleText.length);
		infoStringSmallRange = NSMakeRange(text.length, smallText.length);
		infoStringBoldRange = NSMakeRange(0, track.name.length);
	}
	else if ([data isKindOfClass:[CalEvent class]])
	{
		CalEvent *event = (CalEvent *)data;
		
		NSString *titleText = [NSString stringWithFormat:@"%@\n%@ - %@",
							   event.title,
							   [outputFormatter stringFromDate:event.startDate], [outputFormatter stringFromDate:event.endDate]];
		infoStringText = [NSString stringWithFormat:@"%@\n%u history entries", titleText, [self.document numberOfHistoryEntriesForEvent:event]];
		infoStringLargeRange = NSMakeRange(0, titleText.length);
		infoStringBoldRange = NSMakeRange(0, event.title.length);
	}
	else if ([data isKindOfClass:[LHiPhotoRoll class]])
	{
		LHiPhotoRoll *roll = (LHiPhotoRoll *)data;
		
		NSString *startDate = [outputFormatter stringFromDate:roll.eventStart];
		NSString *endDate = [outputFormatter stringFromDate:roll.eventEnd];
		NSString *dateString = startDate;
		if (![startDate isEqualToString:endDate])
			dateString = [NSString stringWithFormat:@"%@ - %@", startDate, endDate];
		
		NSString *titleText = [NSString stringWithFormat:@"%@\n%@", roll.name, dateString];
		infoStringText = [NSString stringWithFormat:@"%@\n%u history entries\n%u photos", titleText, [self.document numberOfHistoryEntriesForEvent:roll], roll.photos.count];
		infoStringLargeRange = NSMakeRange(0, titleText.length);
		infoStringBoldRange = NSMakeRange(0, roll.name.length);
	}
	
	NSMutableAttributedString *infoString = nil;
	if (infoStringText)
	{
		infoString = [[NSMutableAttributedString alloc] initWithString:infoStringText
															attributes:[NSDictionary dictionaryWithObjectsAndKeys:[NSFont systemFontOfSize:11.0], NSFontAttributeName, nil]];
		[infoString beginEditing];
		if (infoStringLargeRange.length > 0)
			[infoString setAttributes:[NSDictionary dictionaryWithObjectsAndKeys:[NSFont systemFontOfSize:14.0], NSFontAttributeName, nil] range:infoStringLargeRange];
		if (infoStringSmallRange.length > 0)
			[infoString setAttributes:[NSDictionary dictionaryWithObjectsAndKeys:[NSFont systemFontOfSize:9.0], NSFontAttributeName, nil] range:infoStringSmallRange];
		if (infoStringBoldRange.length > 0)
			[infoString setAttributes:[NSDictionary dictionaryWithObjectsAndKeys:[NSFont boldSystemFontOfSize:14.0], NSFontAttributeName, nil] range:infoStringBoldRange];
		[infoString endEditing];
	}
	
	return infoString;
}

@end
