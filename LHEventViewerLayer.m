//
//  LHEventViewerLayer.m
//  LastHistory
//
//  Created by Frederik Seiffert on 05.01.10.
//  Copyright 2010 Frederik Seiffert. All rights reserved.
//

#import "LHEventViewerLayer.h"

#import "LHiPhotoRoll.h"
#import "NSImage-Extras.h"

#define NEXT_BUTTON_LAYER_NAME @"nextButtonLayer"
#define PREV_BUTTON_LAYER_NAME @"prevButtonLayer"
#define EXIT_BUTTON_LAYER_NAME @"exitButtonLayer"
#define PLAY_BUTTON_LAYER_NAME @"playButtonLayer"

#define BUTTON_SIZE 40.0
#define BUTTON_INSET 6.0
#define BUTTON_ICON_INSET 6.0

#define PLAY_TIMER_INTERVAL 3.5


@implementation LHEventViewerLayer

@synthesize photoRoll=_photoRoll;
@synthesize photoRollIndex=_photoRollIndex;
@synthesize isPlaying=_isPlaying;

+ (LHEventViewerLayer *)layerWithPhotoRoll:(LHiPhotoRoll *)roll
{
	LHEventViewerLayer *layer = [self layer];
	layer.photoRoll = roll;
	layer.photoRollIndex = 0;
	return layer;
}

+ (id <CAAction>)defaultActionForKey:(NSString *)key
{
	if ([key isEqualToString:@"contents"])
	{
		// override fade animation
		CATransition *animation = [CATransition animation];
		animation.duration = 0.5;
		animation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut];
		return animation;
	}
	
	return [super defaultActionForKey:key];
}

- (id<CAAction>)actionForKey:(NSString *)key
{
	if ([key isEqualToString:kCAOnOrderIn])
	{
		// start timer when layer is added
		self.isPlaying = YES;
	}
	else if ([key isEqualToString:kCAOnOrderOut])
	{
		// stop timer when layer is removed
		self.isPlaying = NO;
	}
	
	return [super actionForKey:key];
}

- (CALayer *)buttonLayerWithName:(NSString *)layerName
{
	CALayer *layer = [CALayer layer];
	
	layer.name = layerName;
	layer.delegate = self;
	layer.bounds = CGRectMake(0, 0, BUTTON_SIZE, BUTTON_SIZE);
	layer.anchorPoint = CGPointMake(0, 0);
	[layer addConstraint:[CAConstraint constraintWithAttribute:kCAConstraintMinY relativeTo:@"superlayer" attribute:kCAConstraintMinY offset:BUTTON_SIZE]];
	
	[self addSublayer:layer];
	[layer setNeedsDisplay];
	
	return layer;
}

- (id)init
{
	self = [super init];
	if (self != nil) {
		self.backgroundColor = (CGColorRef) CFMakeCollectable(CGColorCreateGenericGray(0, 1.0)); // black
		self.contentsGravity = kCAGravityResizeAspect;
		self.anchorPoint = CGPointMake(0, 0);
		self.layoutManager = [CAConstraintLayoutManager layoutManager];
		
		[self addConstraint:[CAConstraint constraintWithAttribute:kCAConstraintMidY relativeTo:@"superlayer" attribute:kCAConstraintMidY]];
		[self addConstraint:[CAConstraint constraintWithAttribute:kCAConstraintHeight relativeTo:@"superlayer" attribute:kCAConstraintHeight]];
		[self addConstraint:[CAConstraint constraintWithAttribute:kCAConstraintMidX relativeTo:@"superlayer" attribute:kCAConstraintMidX]];
		[self addConstraint:[CAConstraint constraintWithAttribute:kCAConstraintWidth relativeTo:@"superlayer" attribute:kCAConstraintWidth]];
		
		CALayer *exitButton = [self buttonLayerWithName:EXIT_BUTTON_LAYER_NAME];
		[exitButton addConstraint:[CAConstraint constraintWithAttribute:kCAConstraintMaxX relativeTo:@"superlayer" attribute:kCAConstraintMidX offset:-BUTTON_SIZE]];
		
		CALayer *prevButton = [self buttonLayerWithName:PREV_BUTTON_LAYER_NAME];
		[prevButton addConstraint:[CAConstraint constraintWithAttribute:kCAConstraintMaxX relativeTo:@"superlayer" attribute:kCAConstraintMidX]];
		
		CALayer *nextButton = [self buttonLayerWithName:NEXT_BUTTON_LAYER_NAME];
		[nextButton addConstraint:[CAConstraint constraintWithAttribute:kCAConstraintMinX relativeTo:@"superlayer" attribute:kCAConstraintMidX]];
		
		CALayer *playButton = [self buttonLayerWithName:PLAY_BUTTON_LAYER_NAME];
		[playButton addConstraint:[CAConstraint constraintWithAttribute:kCAConstraintMinX relativeTo:@"superlayer" attribute:kCAConstraintMidX offset:BUTTON_SIZE]];
	}
	return self;
}

- (id)initWithLayer:(id)layer
{
	self = [super initWithLayer:layer];
	if (self != nil) {
		LHEventViewerLayer *object = layer;
		_photoRoll = object->_photoRoll;
		_photoRollIndex = object->_photoRollIndex;
		_isPlaying = object->_isPlaying;
	}
	return self;
}

- (void)drawLayer:(CALayer *)theLayer inContext:(CGContextRef)theContext
{
	CGMutablePathRef strokePath = CGPathCreateMutable();
	CGMutablePathRef fillPath = CGPathCreateMutable();
	CGFloat inset = BUTTON_INSET+BUTTON_ICON_INSET;
	
	// add circle
	CGPathAddEllipseInRect(strokePath, NULL, CGRectInset(theLayer.bounds, BUTTON_INSET, BUTTON_INSET));
	
	if ([theLayer.name isEqualToString:EXIT_BUTTON_LAYER_NAME])
	{
		// draw X
		CGPathMoveToPoint(strokePath, NULL, inset, inset);
		CGPathAddLineToPoint(strokePath, NULL, BUTTON_SIZE-inset, BUTTON_SIZE-inset);
		CGPathMoveToPoint(strokePath, NULL, BUTTON_SIZE-inset, inset);
		CGPathAddLineToPoint(strokePath, NULL, inset, BUTTON_SIZE-inset);
	}
	else if ([theLayer.name isEqualToString:PREV_BUTTON_LAYER_NAME])
	{
		// draw <
		const CGPoint points[] = {
			CGPointMake(BUTTON_SIZE-inset-2, inset),
			CGPointMake(inset-1, BUTTON_SIZE/2),
			CGPointMake(BUTTON_SIZE-inset-2, BUTTON_SIZE-inset)};
		CGPathAddLines(strokePath, NULL, points, 3);
	}
	else if ([theLayer.name isEqualToString:NEXT_BUTTON_LAYER_NAME])
	{
		// draw >
		const CGPoint points[] = {
			CGPointMake(inset+2, inset),
			CGPointMake(BUTTON_SIZE-inset+1, BUTTON_SIZE/2),
			CGPointMake(inset+2, BUTTON_SIZE-inset)};
		CGPathAddLines(strokePath, NULL, points, 3);
	}
	else if ([theLayer.name isEqualToString:PLAY_BUTTON_LAYER_NAME])
	{
		if (self.isPlaying)
		{
			// draw ||
			CGPathAddRect(fillPath, NULL, CGRectMake(BUTTON_SIZE/2-BUTTON_SIZE/8-1.5, inset, BUTTON_SIZE/8, BUTTON_SIZE-inset*2));
			CGPathAddRect(fillPath, NULL, CGRectMake(BUTTON_SIZE/2+1.5, inset, BUTTON_SIZE/8, BUTTON_SIZE-inset*2));
		}
		else
		{
			// draw >
			const CGPoint points[] = {
				CGPointMake(inset+2, inset),
				CGPointMake(inset+2, BUTTON_SIZE-inset),
				CGPointMake(BUTTON_SIZE-inset+1, BUTTON_SIZE/2)};
			CGPathAddLines(fillPath, NULL, points, 3);
		}
	}
	
	CGContextSetStrokeColorWithColor(theContext, (CGColorRef) CFMakeCollectable(CGColorCreateGenericGray(1.0, 1.0)));
	CGContextSetFillColorWithColor(theContext, (CGColorRef) CFMakeCollectable(CGColorCreateGenericGray(1.0, 1.0)));
	CGContextSetLineWidth(theContext, 2.0);
	
	CGContextBeginPath(theContext);
	CGContextAddPath(theContext, strokePath);
	CGContextStrokePath(theContext);
	CGContextBeginPath(theContext);
	CGContextAddPath(theContext, fillPath);
	CGContextFillPath(theContext);
	
	CFRelease(strokePath);
	CFRelease(fillPath);
}

- (void)setPhotoRollIndex:(NSInteger)newIndex
{
	NSArray *photos = self.photoRoll.photos;
	
	if (newIndex < 0)
		newIndex = [photos count] - abs(newIndex);
	newIndex = newIndex % [photos count];
	
	self.contents = (id)[[[photos objectAtIndex:newIndex] image] cgImage];
	
	_photoRollIndex = newIndex;
}

- (void)setIsPlaying:(BOOL)value
{
	_isPlaying = value;
	if (_isPlaying) {
		_playTimer = [NSTimer scheduledTimerWithTimeInterval:PLAY_TIMER_INTERVAL target:self selector:@selector(onPlayTimer:) userInfo:nil repeats:YES];
	} else {
		[_playTimer invalidate];
		_playTimer = nil;
	}
	
	CALayer *playButton = [[[self sublayers] filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"name = %@", PLAY_BUTTON_LAYER_NAME]] lastObject];
	[playButton setNeedsDisplay];
}

- (void)onPlayTimer:(NSTimer *)timer
{
	self.photoRollIndex++;
	
	// collect image references after animation
	[[NSGarbageCollector defaultCollector] performSelector:@selector(collectExhaustively)
												withObject:nil
												afterDelay:PLAY_TIMER_INTERVAL/2];
}

- (BOOL)handleMouseUpAtPoint:(CGPoint)mousePoint
{
	CALayer *hitLayer = [self hitTest:mousePoint];
	
	if ([hitLayer.name isEqualToString:PLAY_BUTTON_LAYER_NAME])
		self.isPlaying = !self.isPlaying;
	else if ([hitLayer.name isEqualToString:EXIT_BUTTON_LAYER_NAME])
		return NO; // exit
	else if ([hitLayer.name isEqualToString:PREV_BUTTON_LAYER_NAME])
		self.photoRollIndex--;
	else
		self.photoRollIndex++;
	
	return YES;
}

@end
