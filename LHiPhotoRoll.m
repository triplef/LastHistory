//
//  LHiPhotoRoll.m
//  LastHistory
//
//  Created by Frederik Seiffert on 10.11.09.
//  Copyright 2009 Frederik Seiffert. All rights reserved.
//

#import "LHiPhotoRoll.h"

#import "LHiPhotoLibrary.h"


// Example Roll:
/*
 <dict>
	 <key>RollID</key>
	 <integer>11</integer>
	 <key>RollName</key>
	 <string>My Roll</string>
	 <key>RollDateAsTimerInterval</key>
	 <real>-86024549.000000</real>
	 <key>KeyPhotoKey</key>
	 <string>2</string>
	 <key>KeyList</key>
	 <array>
		 <string>4</string>
		 <string>7</string>
		 <string>8</string>
		 <string>9</string>
		 <string>123</string>
		 <string>122</string>
		 <string>12</string>
		 <string>13</string>
		 <string>14</string>
		 <string>15</string>
		 <string>16</string>
		 <string>17</string>
		 <string>18</string>
		 <string>19</string>
		 <string>20</string>
		 <string>2</string>
	 </array>
	 <key>PhotoCount</key>
	 <integer>16</integer>
 </dict>
*/

@implementation LHiPhotoRoll

@synthesize library=_library;

@synthesize name=_name;
@synthesize timestamp=_timestamp;

- (id)initWithDictionary:(NSDictionary *)rollDict forLibrary:(LHiPhotoLibrary *)library
{
	self = [super init];
	if (self != nil) {
		_library = library;
		
		_name = [rollDict objectForKey:@"RollName"];
		_timestamp = [NSDate dateWithTimeIntervalSinceReferenceDate:[[rollDict objectForKey:@"RollDateAsTimerInterval"] floatValue]];
		
		_keyPhotoKey = [rollDict objectForKey:@"KeyPhotoKey"];
		_photoKeys = [rollDict objectForKey:@"KeyList"];
	}
	return self;
}

- (LHiPhotoPhoto *)keyPhoto
{
	return [self.library imageForKey:_keyPhotoKey inRoll:self];
}

- (NSArray *)photos
{
	if (!_photos)
	{
		NSMutableArray *photos = [NSMutableArray arrayWithCapacity:_photoKeys.count];
		for (NSString *key in _photoKeys)
		{
			LHiPhotoPhoto *photo = [self.library imageForKey:key inRoll:self];
			if (photo)
				[photos addObject:photo];
		}
		
		_photos = [photos copy];
	}
	
	return _photos;
}

- (NSDate *)eventStart
{
	if (_photoKeys.count == 0)
		return nil;
		
	LHiPhotoPhoto *firstPhoto = [self.library imageForKey:[_photoKeys objectAtIndex:0] inRoll:self];
	return firstPhoto.timestamp;
}

- (NSDate *)eventEnd
{
	if (_photoKeys.count == 0)
		return nil;
	
	LHiPhotoPhoto *lastPhoto = [self.library imageForKey:[_photoKeys lastObject] inRoll:self];
	return lastPhoto.timestamp;
}

- (NSInteger)eventStartTime {return LH_EVENT_TIME_UNDEFINED;}
- (NSInteger)eventEndTime {return LH_EVENT_TIME_UNDEFINED;}

@end
