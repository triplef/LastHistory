//
//  LHHistoryView.h
//  LastHistory
//
//  Created by Frederik Seiffert on 05.10.09.
//  Copyright 2009 Frederik Seiffert. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <QuartzCore/QuartzCore.h>


#define STREAM_PADDING_X 200.0 // additional left/right padding for streams to enable display of all information

#define LAYER_DATA_KEY	@"data"

#define SECONDS_PER_DAY (24*60*60)
#define SECONDS_PER_HOUR (60*60)

// Z-Positions
enum {
	kHighlightLayerZ = -1,
	kDefaultZ = 0,
	kHighlightZ = 5,
	kPlayingZ = 10,
	kTopZ = 100
};


@class LHDocument;
@class LHHistoryEntry;
@class LHStreamLayer;
@class LHEventViewerLayer;
@protocol LHEvent;

@interface LHHistoryView : NSView {
	IBOutlet LHDocument *document;
	
	float _timeScaleFactor;
	float _nodeScaleFactor;
	BOOL _showHistoryEntryWeights;
	BOOL _flipTimeline;
	BOOL _showReferenceStreams;
	
	CAScrollLayer *_scrollLayer;
	CALayer *_labelsLayerX;
	CALayer *_labelsLayerY;
	CATextLayer *_infoLayer;
	CALayer *_crosshairXLayer;
	CALayer *_crosshairYLayer;
	CALayer *_highlightsLayer;					// container layer for event highlight layer
	CALayer *_eventHighlightLayer;				// for highlighting events on the timeline on mouse-over
	CALayer *_currentEventHighlightLayer;		// for highlighting playing event
	LHEventViewerLayer *_currentEventViewerLayer;	// for full-size photo viewing
	
	CALayer *_selectionRectLayer;
	
	id <LHEvent> __weak _highlightedEvent;
	CALayer __weak *_mouseOverLayer;
	
	NSMutableDictionary *_nodeImages;			// by label
	
	NSDate *_timelineStart;
	NSDate *_timelineEnd;
	
	BOOL isDragging;
}

@property (readonly) LHDocument *document;

@property (assign) float timeScaleFactor;
@property (assign) float nodeScaleFactor;
@property (assign) BOOL showHistoryEntryWeights;
@property (assign) BOOL flipTimeline;
@property (assign) BOOL showReferenceStreams;

@property (assign) __weak id <LHEvent> highlightedEvent;
@property (assign) __weak CALayer *mouseOverLayer;

@property (readonly) NSDate *timelineStart;
@property (readonly) NSDate *timelineEnd;

@property (readonly) NSSet *streams;

- (void)windowControllerDidLoad;
- (void)layoutIfNeeded;

- (IBAction)increaseTimeScaleFactor:(id)sender;
- (IBAction)decreaseTimeScaleFactor:(id)sender;

- (IBAction)increaseNodeScaleFactor:(id)sender;
- (IBAction)decreaseNodeScaleFactor:(id)sender;

- (void)scrollToDate:(NSDate *)date;

- (void)insertObjectsWithIDs:(NSSet *)objectIDs;
- (void)updateObjectsWithIDs:(NSSet *)objectIDs;

- (LHStreamLayer *)streamWithName:(NSString *)name;


// View utilities
- (CGFloat)xPositionForDate:(NSDate *)date;
- (CGFloat)yPositionForTime:(NSInteger)time;

@end
