//
//  LHiPhotoRoll.h
//  LastHistory
//
//  Created by Frederik Seiffert on 10.11.09.
//  Copyright 2009 Frederik Seiffert. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "LHEvent.h"

@class LHiPhotoLibrary;
@class LHiPhotoPhoto;


@interface LHiPhotoRoll : NSObject <LHEvent> {
	LHiPhotoLibrary __weak *_library;
	
	NSString *_name;
	NSDate *_timestamp;
	
	NSString *_keyPhotoKey;
	NSArray *_photoKeys;
	
	NSArray __weak *_photos; // garbage-collected cache
}

- (id)initWithDictionary:(NSDictionary *)rollDict forLibrary:(LHiPhotoLibrary *)library;

@property (readonly) LHiPhotoLibrary __weak *library;

@property (readonly) NSString *name;
@property (readonly) NSDate *timestamp;

@property (readonly) LHiPhotoPhoto *keyPhoto;
@property (readonly) NSArray *photos;

@property (readonly) NSDate *eventStart;
@property (readonly) NSDate *eventEnd;

@end
