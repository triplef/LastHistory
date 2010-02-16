//
//  CalEvent+LHEvent.m
//  LastHistory
//
//  Created by Frederik Seiffert on 13.11.09.
//  Copyright 2009 Frederik Seiffert. All rights reserved.
//

#import "CalEvent+LHEvent.h"


@implementation CalEvent (LHEvent)

- (NSDate *)eventStart {return self.startDate;}
- (NSDate *)eventEnd {return self.endDate;}

- (NSInteger)eventStartTime {return LH_EVENT_TIME_UNDEFINED;}
- (NSInteger)eventEndTime {return LH_EVENT_TIME_UNDEFINED;}

@end