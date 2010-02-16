//
//  LHCalendarStream.m
//  LastHistory
//
//  Created by Frederik Seiffert on 10.12.09.
//  Copyright 2009 Frederik Seiffert. All rights reserved.
//

#import "LHCalendarStream.h"

#import <CalendarStore/CalendarStore.h>

#import "LHCommonMacros.h"
#import "LHHistoryView.h"
#import "LHDocument.h"
#import "LHHistoryEntry.h"
#import "NSImage-Extras.h"
#import "NSColor-Extras.h"


#define EVENT_HEIGHT 5.0
#define EVENT_MARGIN 1.0


@implementation LHCalendarStream

+ (Class)nodeClass
{
	return [CalEvent class];
}

- (id)initWithLayer:(id)layer
{
	self = [super initWithLayer:layer];
	if (self != nil) {
		LHCalendarStream *object = layer;
		_calendars = object->_calendars;
		_calendarEvents = object->_calendarEvents;
	}
	return self;
}

- (void)setupLayer
{
	self.anchorPoint = CGPointMake(0, 0);
	self.bounds = CGRectMake(0, 0, self.superlayer.bounds.size.width, self.calendars.count * (EVENT_HEIGHT + EVENT_MARGIN));
}

- (void)generateNodes
{
	[self removeAllSublayers];
	
	// load calendar events
	NSArray *calendarEvents = self.calendarEvents;
	
	NSLog(@"Generating calendar nodes...");
	
	NSUInteger processedCount = 0;
	for (CalEvent *event in calendarEvents)
	{
		CALayer *layer = [CALayer layer];
		[layer setValue:event forKey:LAYER_DATA_KEY];
		layer.anchorPoint = CGPointMake(0, 0);
		layer.backgroundColor = [event.calendar.color cgColor];
		
		[self addSublayer:layer];
		processedCount++;
	}
	
	[self layoutSublayers];
	
	NSLog(@"Generated %u calendar nodes", processedCount);
}

- (void)layoutSublayers
{
	if (self.superlayer.isHidden)
		return;
	
	for (CALayer *layer in self.sublayers)
	{
		CalEvent *event = [layer valueForKey:LAYER_DATA_KEY];
		
		CGFloat startPoint = [self.view xPositionForDate:self.view.flipTimeline ? event.endDate : event.startDate];
		CGFloat endPoint = [self.view xPositionForDate:self.view.flipTimeline ? event.startDate : event.endDate];
		layer.bounds = CGRectMake(0, 0, endPoint - startPoint, EVENT_HEIGHT);
		
		NSUInteger layerCalendarPosition = [self.calendars indexOfObject:event.calendar];
		layer.position = CGPointMake(startPoint, layerCalendarPosition * (EVENT_HEIGHT + EVENT_MARGIN));
	}
}


- (NSArray *)calendars
{
	if (!_calendars)
		_calendars = [[CalCalendarStore defaultCalendarStore].calendars filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"type == %@", CalCalendarTypeLocal]];
	
	return _calendars;
}

- (NSArray *)calendarEvents
{
	if (!_calendarEvents)
	{
		NSDate *startDate = self.view.document.firstHistoryEntry.timestamp;
		NSDate *endDate = self.view.document.lastHistoryEntry.timestamp;
		if (!startDate)
			return nil;
		
		LHLog(@"Fetching calendar events...");
		
		// get all all-day events from local calendars
		// we have to fetch them in batches, because eventsWithPredicate: only fetches 4 years at a time
		NSCalendar *calendar = [NSCalendar currentCalendar];
		NSDateComponents *fourYears = [NSDateComponents new];
		fourYears.year = 4;
		NSDateComponents *oneSecond = [NSDateComponents new];
		fourYears.second = 1;
		
		NSDate *batchStartDate = startDate;
		NSDate *batchEndDate = nil;
		NSArray *events = [NSArray array];
		
		do {
			batchEndDate = [calendar dateByAddingComponents:fourYears toDate:batchStartDate options:0];
			if ([batchEndDate compare:endDate] == NSOrderedDescending)
				batchEndDate = endDate;
			
			NSPredicate *eventsPredicate = [CalCalendarStore eventPredicateWithStartDate:batchStartDate
																				 endDate:batchEndDate
																			   calendars:self.calendars];
			NSArray *batchEvents = [[CalCalendarStore defaultCalendarStore] eventsWithPredicate:eventsPredicate];
			batchEvents = [batchEvents filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"isAllDay == TRUE"]];
			events = [events arrayByAddingObjectsFromArray:batchEvents];
			
			batchStartDate = [calendar dateByAddingComponents:oneSecond toDate:batchEndDate options:0];
		} while ([batchEndDate compare:endDate] == NSOrderedAscending);
		
		_calendarEvents = events;
	}
	
	return _calendarEvents;
}

@end
