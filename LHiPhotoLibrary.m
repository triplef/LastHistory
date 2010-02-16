//
//  LHiPhotoLibrary.m
//  LastHistory
//
//  Created by Frederik Seiffert on 08.11.09.
//  Copyright 2009 Frederik Seiffert. All rights reserved.
//

#import "LHiPhotoLibrary.h"


@implementation LHiPhotoLibrary

@synthesize libraryURL=_libraryURL;
@synthesize rolls=_rolls;

+ (LHiPhotoLibrary *)defaultLibrary
{
	static id defaultLibrary = nil;
	if (!defaultLibrary) {
		[[NSUserDefaults standardUserDefaults] synchronize];
		NSArray *dbs = [[[NSUserDefaults standardUserDefaults] persistentDomainForName:@"com.apple.iApps"] objectForKey:@"iPhotoRecentDatabases"];
		if ([dbs count] > 0) {
			NSURL *url = [NSURL URLWithString:[dbs objectAtIndex:0]];
			if ([url isFileURL])
				defaultLibrary = [[self alloc] initWithURL:url];
		}
	}
	return defaultLibrary;
}

- (id)initWithURL:(NSURL *)libraryURL
{
	self = [super init];
	if (self != nil) {
		_libraryURL = libraryURL;
		
#if USE_IMAGE_CACHE
		_imageCache = [NSMapTable mapTableWithStrongToWeakObjects];
#endif
		
		[self loadLibrary];
	}
	return self;
}

- (LHiPhotoPhoto *)imageForKey:(NSString *)key inRoll:(LHiPhotoRoll *)roll
{
#if USE_IMAGE_CACHE
	LHiPhotoPhoto *result = [_imageCache objectForKey:key];
#else
	LHiPhotoPhoto *result = nil;
#endif
	
	if (!result)
	{
		NSDictionary *imageDict = [_imageDictsByKey objectForKey:key];
		if (imageDict) {
			result = [[LHiPhotoPhoto alloc] initWithDictionary:imageDict inRoll:roll];
#if USE_IMAGE_CACHE
			[_imageCache setObject:result forKey:key];
#endif
		}
	}
	
	return result;
}

- (BOOL)loadLibrary
{
	if (_rolls && _imageDictsByKey)
		return YES;
	
	NSURL *libraryURL = self.libraryURL;
	if (!libraryURL)
		return NO;
	
	NSLog(@"Reading iPhoto library: %@", libraryURL);
	NSDictionary *library = [NSDictionary dictionaryWithContentsOfURL:libraryURL];
	if (!library) {
		NSLog(@"Error: unable to read iPhoto library from '%@'.", libraryURL);
		return NO;
	}
	
	NSArray *rollsDicts = [library objectForKey:@"List of Rolls"];
	if (!rollsDicts) {
		NSLog(@"Error: No rolls found in iPhoto library.");
	} else {
		NSMutableArray *rolls = [NSMutableArray arrayWithCapacity:rollsDicts.count];
		for (NSDictionary *rollDict in rollsDicts)
		{
			LHiPhotoRoll *roll = [[LHiPhotoRoll alloc] initWithDictionary:rollDict forLibrary:self];
			[rolls addObject:roll];
		}
		NSLog(@"Read %d rolls from iPhoto.", rolls.count);
		_rolls = [rolls copy];
	}
	
	NSDictionary *images = [library objectForKey:@"Master Image List"];
	if (!images) {
		NSLog(@"Error: No images found in iPhoto library.");
	} else {
		NSLog(@"Read %d images from iPhoto.", images.count);
		_imageDictsByKey = [images copy];
	}
	
	return _rolls && _imageDictsByKey;
}

@end
