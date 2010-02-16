#import "_LHTrack.h"

#define TRACK_GENRE_UNKNOWN @"unknown"
#define TRACK_GENRE_UNKNOWN_INDEX -1

@interface LHTrack : _LHTrack {
	NSString *_genre;
}

+ (NSArray *)genreTagsMappings;
+ (NSArray *)genres;
+ (NSUInteger)genreIndexForGenre:(NSString *)genre;

@property (readonly) NSString *displayName;
@property (readonly) NSString *trackID;

@property (readonly) NSUInteger trackCount;

@property (readonly) NSArray *sortedTrackTags;

- (NSString *)tagsStringWrappedAt:(NSUInteger)numWrapChars;
@property (readonly) NSString *tagsString;

@property (readonly) NSString *genre;

@end
