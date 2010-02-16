#import "LHTrack.h"

#import "LHArtist.h"
#import "LHTrackTag.h"
#import "LHTag.h"

@implementation LHTrack

+ (NSArray *)genreTagsMappings
{
	static NSArray *genreTagsMappings = nil;
	if (!genreTagsMappings) {
		NSString *path = [[NSBundle mainBundle] pathForResource:@"GenreTagsMappings" ofType:@"plist"];
		genreTagsMappings = [[NSArray alloc] initWithContentsOfFile:path];
	}
	return genreTagsMappings;
}

+ (NSArray *)genres
{
	return [[self genreTagsMappings] valueForKey:@"genre"];
}

+ (NSUInteger)genreIndexForGenre:(NSString *)genre
{
	return [[self genres] indexOfObject:genre];
}


- (NSString *)displayName
{
	return [NSString stringWithFormat:@"%@ - %@", self.artist.name, self.name];
}

- (NSString *)trackID
{
	// artist & name, always lowercase
	return [self.displayName lowercaseString];
}

- (NSUInteger)trackCount
{
	return [[self valueForKeyPath:@"historyEntries.@count"] unsignedIntegerValue];
}

- (NSArray *)sortedTrackTags
{
	NSSortDescriptor *sortDescriptor = [[[NSSortDescriptor alloc] initWithKey:@"count" ascending:NO] autorelease];
	return [[self.trackTags allObjects] sortedArrayUsingDescriptors:[NSArray arrayWithObject:sortDescriptor]];
}

- (NSString *)tagsStringWrappedAt:(NSUInteger)numWrapChars
{
	NSMutableString *result = [NSMutableString string];
	NSUInteger numChars = 0;
	
	for (LHTrackTag *trackTag in self.sortedTrackTags)
	{
		NSString *string = [NSString stringWithFormat:@"%@ (%@) ", trackTag.tag.name, trackTag.count];
		[result appendString:string];
		numChars += [string length];
		
		if (numWrapChars > 0 && numChars > numWrapChars) {
			[result appendString:@"\n"];
			numChars = 0;
		}
	}
	
	return [result stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
}

- (NSString *)tagsString
{
	return [self tagsStringWrappedAt:0];
}

- (NSString *)genre
{
	if (!_genre)
	{
		NSArray *genreTagsMappings = [[self class] genreTagsMappings];
		
		// find best-matching genre for track tags
		for (LHTrackTag *trackTag in self.sortedTrackTags)
		{
			NSString *tagName = [trackTag.tag.name lowercaseString];
			
			for (NSUInteger i = 0; i < [genreTagsMappings count]; i++)
			{
				NSDictionary *mapping = [genreTagsMappings objectAtIndex:i];
				
				if ([[mapping objectForKey:@"tags"] containsObject:tagName]) {
					_genre = [mapping objectForKey:@"genre"];
					break;
				}
			}
			
			if (_genre)
				break;
		}
		
//		if (!_genre && self.trackTags.count > 0)
//			NSLog(@"Unknown tags: %@", [self tagsString]);
	}
	
	return _genre ? _genre : TRACK_GENRE_UNKNOWN;
}

@end
