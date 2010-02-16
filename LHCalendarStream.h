//
//  LHCalendarStream.h
//  LastHistory
//
//  Created by Frederik Seiffert on 10.12.09.
//  Copyright 2009 Frederik Seiffert. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "LHStreamLayer.h"


@interface LHCalendarStream : LHStreamLayer {
	NSArray *_calendars;
	NSArray *_calendarEvents;
}

@property (readonly) NSArray *calendars;
@property (readonly) NSArray *calendarEvents;

@end
