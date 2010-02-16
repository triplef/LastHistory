//
//  LHStreamLayer.h
//  LastHistory
//
//  Created by Frederik Seiffert on 10.12.09.
//  Copyright 2009 Frederik Seiffert. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <QuartzCore/QuartzCore.h>

@class LHHistoryView;


@interface LHStreamLayer : CALayer {
	LHHistoryView __weak *_view;
	
	CALayer *_highlightedNode;
}

@property (readonly) LHHistoryView __weak *view;
@property (retain) CALayer *highlightedNode;

+ (Class)nodeClass;

- (id)initWithView:(LHHistoryView *)view;

- (void)setupLayer;
- (void)generateNodes;

- (void)removeAllSublayers;

- (void)mouseMoved:(NSEvent *)theEvent onLayer:(CALayer *)hitLayer;

@end
