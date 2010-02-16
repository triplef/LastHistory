//
//  NSDateFormatter-Extras.m
//  LastHistory
//
//  Created by Frederik Seiffert on 12.12.09.
//  Copyright 2009 Frederik Seiffert. All rights reserved.
//

#import "NSDateFormatter-Extras.h"


@implementation NSDateFormatter (Extras)

// returns the weekday number for the given weekday string reprensentation,
// or NSNotFound if the string does not represent a weekday
- (NSUInteger)weekdayForString:(NSString *)token
{
	token = [token lowercaseString];
	
	// check short symbols
	NSMutableArray *shortSymbols = [NSMutableArray arrayWithCapacity:[[self shortStandaloneWeekdaySymbols] count]];
	for (NSString *symbol in [[self shortStandaloneWeekdaySymbols] valueForKey:@"lowercaseString"]) {
		if ([symbol hasSuffix:@"."])
			symbol = [symbol substringToIndex:[symbol length]-1];
		[shortSymbols addObject:symbol];
	}
	NSUInteger index = [shortSymbols indexOfObject:token];
	
	// check long symbols
	if (index == NSNotFound)
	{
		NSArray *symbols = [[self standaloneWeekdaySymbols] valueForKey:@"lowercaseString"];
		// allow "s" suffix for full weekday somboly, e.g. "fridays"
		if ([token hasSuffix:@"s"])
			token = [token substringToIndex:[token length]-1];
		index = [symbols indexOfObject:token];
	}
	
	return index == NSNotFound ? NSNotFound : ++index;
}

- (NSUInteger)monthForString:(NSString *)token
{
	token = [token lowercaseString];
	
	// check short symbols
	NSArray *shortSymbols = [[self shortStandaloneMonthSymbols] valueForKey:@"lowercaseString"];
	NSUInteger index = [shortSymbols indexOfObject:token];
	
	// check long symbols
	if (index == NSNotFound)
	{
		NSArray *symbols = [[self standaloneMonthSymbols] valueForKey:@"lowercaseString"];
		index = [symbols indexOfObject:token];
	}
	
	return index == NSNotFound ? NSNotFound : ++index;
}

@end
