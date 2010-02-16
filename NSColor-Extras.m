//
//  NSColor-Extras.m
//  LastHistory
//
//  Created by Frederik Seiffert on 05.01.10.
//  Copyright 2010 Frederik Seiffert. All rights reserved.
//

#import "NSColor-Extras.h"
#import <QuartzCore/QuartzCore.h>


@implementation NSColor (Extras)

- (CGColorRef)cgColor
{
	NSColor *deviceColor = [self colorUsingColorSpaceName:NSDeviceRGBColorSpace];
	
	CGFloat components[4];
	[deviceColor getRed:&components[0] green:&components[1] blue:&components[2] alpha:&components[3]];
	
	CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
	CGColorRef result = CGColorCreate(colorSpace, components);
	CGColorSpaceRelease(colorSpace);
	
	if (result)
		CFMakeCollectable(result);
	
	return result;
}

@end
