//
//  LHEventViewerLayer.h
//  LastHistory
//
//  Created by Frederik Seiffert on 05.01.10.
//  Copyright 2010 Frederik Seiffert. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <QuartzCore/QuartzCore.h>

@class LHiPhotoRoll;


@interface LHEventViewerLayer : CALayer {
	LHiPhotoRoll *_photoRoll;
	NSInteger _photoRollIndex;
	
	BOOL _isPlaying;
	NSTimer *_playTimer;
}

@property (retain) LHiPhotoRoll *photoRoll;
@property (assign) NSInteger photoRollIndex;
@property (assign) BOOL isPlaying;

+ (LHEventViewerLayer *)layerWithPhotoRoll:(LHiPhotoRoll *)roll;

- (BOOL)handleMouseUpAtPoint:(CGPoint)mousePoint;

@end
