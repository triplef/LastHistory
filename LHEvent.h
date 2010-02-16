//
//  LHEvent.h
//  LastHistory
//
//  Created by Frederik Seiffert on 13.11.09.
//  Copyright 2009 Frederik Seiffert. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#define LH_EVENT_TIME_UNDEFINED -1


@protocol LHEvent

@property (readonly) NSDate *eventStart;
@property (readonly) NSDate *eventEnd;

@property (readonly) NSInteger eventStartTime;
@property (readonly) NSInteger eventEndTime;

@end
