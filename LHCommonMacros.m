//
//  LHCommonMacros.m
//  LastHistory
//
//  Created by Frederik Seiffert on 21.10.09.
//  Copyright 2009 Frederik Seiffert. All rights reserved.
//

#import "LHCommonMacros.h"
#include <stdarg.h>


#ifdef DEBUG_BUILD

void LHLog(NSString *format, ...)
{
	va_list ap; /* Points to each unamed argument in turn */
	
	va_start(ap, format); /* Make ap point to the first unnamed argument */
	NSLogv(format, ap);
	va_end(ap); /* clean up when done */
}

#else

//Insert a fake symbol so that plugins using LHLog() don't crash.
#undef LHLog
void LHLog(NSString *format, ...) {};

#endif
