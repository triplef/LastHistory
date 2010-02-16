//
//  LHiPhotoImage.m
//  LastHistory
//
//  Created by Frederik Seiffert on 10.11.09.
//  Copyright 2009 Frederik Seiffert. All rights reserved.
//

#import "LHiPhotoPhoto.h"


// Example Image:
/*
 <key>6153</key>
 <dict>
	 <key>MediaType</key>
	 <string>Image</string>
	 <key>Caption</key>
	 <string>CIMG0818.JPG</string>
	 <key>Comment</key>
	 <string>My Comment</string>
	 <key>GUID</key>
	 <string>A9CD2B1A-4CA2-4E58-8A0F-DECD422E7B47</string>
	 <key>Aspect Ratio</key>
	 <real>0.750000</real>
	 <key>Rating</key>
	 <integer>0</integer>
	 <key>Roll</key>
	 <integer>6116</integer>
	 <key>DateAsTimerInterval</key>
	 <real>175905124.000000</real>
	 <key>ModDateAsTimerInterval</key>
	 <real>175937524.000000</real>
	 <key>MetaModDateAsTimerInterval</key>
	 <real>176009326.578772</real>
	 <key>ImagePath</key>
	 <string>/Users/frederik/Pictures/iPhoto Library/Originals/2006/USA Treffen in München &amp; Erkundungstour/CIMG0818.JPG</string>
	 <key>ThumbPath</key>
	 <string>/Users/frederik/Pictures/iPhoto Library/Data/2006/USA Treffen in München &amp; Erkundungstour/CIMG0818.jpg</string>
	 <key>ImageType</key><string>JPEG</string>
 </dict>
*/

@implementation LHiPhotoPhoto

@synthesize roll=_roll;
@synthesize caption=_caption;
@synthesize timestamp=_timestamp;

- (id)initWithDictionary:(NSDictionary *)imageDict inRoll:(LHiPhotoRoll *)roll
{
	self = [super init];
	if (self != nil) {
		_roll = roll;
		
		_caption = [imageDict objectForKey:@"Caption"];
		_timestamp = [NSDate dateWithTimeIntervalSinceReferenceDate:[[imageDict objectForKey:@"DateAsTimerInterval"] floatValue]];
		
		_imagePath = [imageDict objectForKey:@"ImagePath"];
		_thumbPath = [imageDict objectForKey:@"ThumbPath"];
	}
	return self;
}

- (NSImage *)image
{
	return [[NSImage alloc] initByReferencingFile:_imagePath];
}

- (NSImage *)thumb
{
	return [[NSImage alloc] initByReferencingFile:_thumbPath];
}

@end
