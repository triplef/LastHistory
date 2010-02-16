//
//  LHPhotoStream.m
//  LastHistory
//
//  Created by Frederik Seiffert on 10.12.09.
//  Copyright 2009 Frederik Seiffert. All rights reserved.
//

#import "LHPhotoStream.h"

#import "LHHistoryView.h"
#import "LHDocument.h"
#import "LHHistoryEntry.h"
#import "LHiPhotoLibrary.h"
#import "NSImage-Extras.h"


#define PHOTOS_HEIGHT_MIN 10.0
#define PHOTOS_HEIGHT_MAX 50.0


@implementation LHPhotoStream

+ (Class)nodeClass
{
	return [LHiPhotoRoll class];
}

- (void)setupLayer
{
	self.anchorPoint = CGPointMake(0, 0);
	self.bounds = CGRectMake(0, 0, self.superlayer.bounds.size.width, PHOTOS_HEIGHT_MAX);
}

- (void)generateNodes
{
	[self removeAllSublayers];
	
	// load iPhoto library
	LHiPhotoLibrary *library = [LHiPhotoLibrary defaultLibrary];
	NSArray *rolls = library.rolls;
	
	NSLog(@"Generating photo nodes...");
	
	NSDate *startDate = self.view.document.firstHistoryEntry.timestamp;
	NSDate *endDate = self.view.document.lastHistoryEntry.timestamp;
	CGFloat photoPosY = self.bounds.size.height / 2.0;
	
	NSUInteger processedCount = 0;
	for (LHiPhotoRoll *roll in rolls)
	{
		if ([roll.eventEnd compare:startDate] == NSOrderedDescending
			&& [roll.eventStart compare:endDate] == NSOrderedAscending)
		{
			CALayer *layer = [CALayer layer];
			[layer setValue:roll forKey:LAYER_DATA_KEY];
			
			NSUInteger historyEntryCount = [self.view.document numberOfHistoryEntriesForEvent:roll];
			float weightFactor = MAX(1.0, MIN(PHOTOS_HEIGHT_MAX/PHOTOS_HEIGHT_MIN, (float)historyEntryCount / 10.0));
			NSImage *image = roll.keyPhoto.thumb;
			float aspectRatio = image.size.width / image.size.height;
			
			layer.contentsGravity = kCAGravityResizeAspect;
			layer.contents = (id)[image cgImage];
			layer.anchorPoint = CGPointMake(1.0, 0.5);
			layer.bounds = CGRectMake(0, 0, PHOTOS_HEIGHT_MIN * weightFactor * aspectRatio, PHOTOS_HEIGHT_MIN * weightFactor);
			layer.position = CGPointMake([self.view xPositionForDate:roll.eventStart] + layer.bounds.size.width, photoPosY);
			
			[self addSublayer:layer];
			processedCount++;
		}
	}
	
	NSLog(@"Generated %u photo nodes", processedCount);
}

- (void)layoutSublayers
{
	if (self.superlayer.isHidden)
		return;
	
	CGFloat photoPosY = self.bounds.size.height / 2.0;
	
	// reposition nodes
	for (CALayer *layer in self.sublayers)
	{
		LHiPhotoRoll *roll = [layer valueForKey:LAYER_DATA_KEY];
		layer.position = CGPointMake([self.view xPositionForDate:roll.eventStart] + layer.bounds.size.width, photoPosY);
	}
}

- (void)setHighlightedNode:(CALayer *)newLayer
{
	if (_highlightedNode != newLayer)
	{
		// restore key photo
		LHiPhotoRoll *highlightedRoll = [_highlightedNode valueForKey:LAYER_DATA_KEY];
		_highlightedNode.contents = (id)[highlightedRoll.keyPhoto.thumb cgImage];
		
		// reset cache
		[_highlightedNode setValue:nil forKey:@"currentPhoto"];
		
		// set zPosition
		_highlightedNode.zPosition = kDefaultZ;
		newLayer.zPosition = kHighlightZ;
		
		// scale to highlight
		[_highlightedNode setValue:[NSNumber numberWithFloat:1.0] forKeyPath:@"transform.scale"];
		float weightFactor = PHOTOS_HEIGHT_MAX / newLayer.bounds.size.height;
		[newLayer setValue:[NSNumber numberWithFloat:3.0 * weightFactor] forKeyPath:@"transform.scale"];
		
		_highlightedNode = newLayer;
	}
}

- (void)mouseMoved:(NSEvent *)theEvent onLayer:(CALayer *)hitLayer
{
	// set highlighted node
	[super mouseMoved:theEvent onLayer:hitLayer];
	
	// show roll photos on mouse-over
	if (self.highlightedNode)
	{
		CALayer *rollLayer = self.highlightedNode;
		LHiPhotoRoll *roll = [rollLayer valueForKey:LAYER_DATA_KEY];
		
		// convert mouse coordianates
		NSPoint mousePointInView = [self.view convertPoint:theEvent.locationInWindow fromView:nil];
		CGPoint mousePointInRoll = [self.view.layer convertPoint:NSPointToCGPoint(mousePointInView) toLayer:rollLayer];
		
		// find photo to display
		float partOfRoll = mousePointInRoll.x / rollLayer.bounds.size.width; // between 0 and 1
		NSUInteger photoIndex = roll.photos.count * partOfRoll;
		
		if (photoIndex >= 0 && photoIndex < roll.photos.count)
		{
			LHiPhotoPhoto *photo = [roll.photos objectAtIndex:photoIndex];
			if (![photo isEqual:[rollLayer valueForKey:@"currentPhoto"]]) {
				rollLayer.contents = (id)[photo.thumb cgImage];
				[rollLayer setValue:photo forKey:@"currentPhoto"];
			}
		}
	}
}

@end
