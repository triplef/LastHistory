//
//  CalEvent+LHEvent.h
//  LastHistory
//
//  Created by Frederik Seiffert on 13.11.09.
//  Copyright 2009 Frederik Seiffert. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <CalendarStore/CalendarStore.h>

#import "LHEvent.h"

// make CalEvent conform to the LHEvent protocol
@interface CalEvent (LHEvent) <LHEvent>
@end
