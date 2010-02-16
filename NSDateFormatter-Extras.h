//
//  NSDateFormatter-Extras.h
//  LastHistory
//
//  Created by Frederik Seiffert on 12.12.09.
//  Copyright 2009 Frederik Seiffert. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface NSDateFormatter (Extras)

- (NSUInteger)weekdayForString:(NSString *)token;
- (NSUInteger)monthForString:(NSString *)token;

@end
