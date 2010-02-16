//
//  NSDate-Extras.m
//  LastHistory
//
//  Created by Frederik Seiffert on 13.12.09.
//  Copyright 2009 Frederik Seiffert. All rights reserved.
//

#import "NSDate-Extras.h"


@implementation NSDate (Extras)

- (NSDate *)day
{
	NSCalendar *calendar = [NSCalendar currentCalendar];
	NSDateComponents *comps = [calendar components:(NSYearCalendarUnit | NSMonthCalendarUnit |  NSDayCalendarUnit)
										  fromDate:self];
	return [calendar dateFromComponents:comps];
}

- (NSInteger)year
{
	NSDateComponents *comps = [[NSCalendar currentCalendar] components:NSYearCalendarUnit fromDate:self];
	return [comps year];
}

- (NSInteger)month
{
	NSDateComponents *comps = [[NSCalendar currentCalendar] components:NSMonthCalendarUnit fromDate:self];
	return [comps month];
}

- (NSInteger)hour
{
	NSDateComponents *comps = [[NSCalendar currentCalendar] components:NSHourCalendarUnit fromDate:self];
	return [comps hour];
}

- (NSInteger)weekday
{
	NSDateComponents *comps = [[NSCalendar currentCalendar] components:NSWeekdayCalendarUnit fromDate:self];
	return [comps weekday];
}

@end
