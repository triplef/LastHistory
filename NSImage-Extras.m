//
//  NSImage-Extras.m
//
//  Created by Scott Stevenson on 9/28/07.
//  Source may be reused with virtually no restriction. See License.txt

#import "NSImage-Extras.h"
#import <QuartzCore/QuartzCore.h>


@implementation NSImage (Extras)

- (CGImageRef)cgImage
{
	CGImageRef image = CreateCGImageFromData([self TIFFRepresentation]);
	if (image)
		CFMakeCollectable(image);
	
	return image;
}

@end

// from http://developer.apple.com/technotes/tn2005/tn2143.html

CGImageRef CreateCGImageFromData(NSData* data)
{
    CGImageRef        imageRef = NULL;
    CGImageSourceRef  sourceRef;

    sourceRef = CGImageSourceCreateWithData((CFDataRef)data, NULL);
    if(sourceRef) {
		NSDictionary *options = [NSDictionary dictionaryWithObject:[NSNumber numberWithBool:NO]
															forKey:(NSString *)kCGImageSourceShouldCache];
        imageRef = CGImageSourceCreateImageAtIndex(sourceRef, 0, (CFDictionaryRef)options);
        CFRelease(sourceRef);
    }

    return imageRef;
}
