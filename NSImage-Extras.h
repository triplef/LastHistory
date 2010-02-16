//
//  NSImage-Extras.h
//
//  Created by Scott Stevenson on 9/28/07.
//  Source may be reused with virtually no restriction. See License.txt

#import <Cocoa/Cocoa.h>

CGImageRef CreateCGImageFromData(NSData* data);

@interface NSImage (Extras)

- (CGImageRef)cgImage;

@end
