//
//  NSDate-Extras.h
//  LastHistory
//
//  Created by Frederik Seiffert on 13.12.09.
//  Copyright 2009 Frederik Seiffert. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface NSDate (Extras)

- (NSDate *)day;
- (NSInteger)year;
- (NSInteger)month;
- (NSInteger)hour;
- (NSInteger)weekday;

@end
