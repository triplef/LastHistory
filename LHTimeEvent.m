//
//  LHTimeEvent.m
//  LastHistory
//
//  Created by Frederik Seiffert on 22.11.09.
//  Copyright 2009 Frederik Seiffert. All rights reserved.
//

#import "LHTimeEvent.h"


@implementation LHTimeEvent

@synthesize eventStart=_startDate;
@synthesize eventEnd=_endDate;
@synthesize eventStartTime=_startTime;
@synthesize eventEndTime=_endTime;

- (id)initWithStartTime:(NSInteger)startTime endTime:(NSInteger)endTime
{
	self = [self initWithStartDate:nil endDate:nil startTime:startTime endTime:endTime];
	return self;
}

- (id)initWithStartDate:(NSDate *)startDate endDate:(NSDate *)endDate startTime:(NSInteger)startTime endTime:(NSInteger)endTime
{
	self = [super init];
	if (self != nil) {
		_startDate = startDate;
		_endDate = endDate;
		_startTime = startTime;
		_endTime = endTime;
	}
	return self;
}

@end
