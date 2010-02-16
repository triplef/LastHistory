//
//  LHStreamLayer.m
//  LastHistory
//
//  Created by Frederik Seiffert on 10.12.09.
//  Copyright 2009 Frederik Seiffert. All rights reserved.
//

#import "LHStreamLayer.h"

#import "LHHistoryView.h"


@implementation LHStreamLayer

@synthesize view=_view;
@synthesize highlightedNode=_highlightedNode;

+ (Class)nodeClass
{
	return nil;
}

- (id)initWithView:(LHHistoryView *)view
{
	self = [super init];
	if (self != nil) {
		_view = view;
		
		[self setupLayer];
	}
	return self;
}

- (id)initWithLayer:(id)layer
{
	self = [super initWithLayer:layer];
	if (self != nil) {
		LHStreamLayer *object = layer;
		_view = object->_view;
		_highlightedNode = object->_highlightedNode;
	}
	return self;
}

//- (void)finalize
//{
//	NSLog(@"%@ finalize", self);
//	[super finalize];
//}

- (void)setupLayer
{
	// subclasses can override to setup layer geometry
}

- (void)generateNodes
{
	// subclasses should override to generate sublayers
}

- (void)removeAllSublayers
{
	[[self.sublayers copy] makeObjectsPerformSelector:@selector(removeFromSuperlayer)];
}

- (void)mouseMoved:(NSEvent *)theEvent onLayer:(CALayer *)hitLayer
{
	id hitData = [hitLayer valueForKey:LAYER_DATA_KEY];
	self.highlightedNode = [hitData isKindOfClass:[[self class] nodeClass]] ? hitLayer : nil;
}

@end
