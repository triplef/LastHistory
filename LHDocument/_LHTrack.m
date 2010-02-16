// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to LHTrack.m instead.

#import "_LHTrack.h"

@implementation LHTrackID
@end

@implementation _LHTrack

+ (id)insertInManagedObjectContext:(NSManagedObjectContext*)moc_ {
	NSParameterAssert(moc_);
	return [NSEntityDescription insertNewObjectForEntityForName:@"Track" inManagedObjectContext:moc_];
}

- (LHTrackID*)objectID {
	return (LHTrackID*)[super objectID];
}




@dynamic name;






@dynamic mbid;






@dynamic trackTags;

	
- (NSMutableSet*)trackTagsSet {
	[self willAccessValueForKey:@"trackTags"];
	NSMutableSet *result = [self mutableSetValueForKey:@"trackTags"];
	[self didAccessValueForKey:@"trackTags"];
	return result;
}
	

@dynamic album;

	

@dynamic artist;

	

@dynamic historyEntries;

	
- (NSMutableSet*)historyEntriesSet {
	[self willAccessValueForKey:@"historyEntries"];
	NSMutableSet *result = [self mutableSetValueForKey:@"historyEntries"];
	[self didAccessValueForKey:@"historyEntries"];
	return result;
}
	




+ (NSArray*)fetchTracksWithNameAndArtist:(NSManagedObjectContext*)moc_ name:(NSString*)name_ artist:(LHArtist*)artist_ {
	NSError *error = nil;
	NSArray *result = [self fetchTracksWithNameAndArtist:moc_ name:name_ artist:artist_ error:&error];
	if (error) {
#if TARGET_OS_IPHONE
		NSLog(@"error: %@", error);
#else
		[NSApp presentError:error];
#endif
	}
	return result;
}
+ (NSArray*)fetchTracksWithNameAndArtist:(NSManagedObjectContext*)moc_ name:(NSString*)name_ artist:(LHArtist*)artist_ error:(NSError**)error_ {
	NSError *error = nil;
	
	NSManagedObjectModel *model = [[moc_ persistentStoreCoordinator] managedObjectModel];
	NSFetchRequest *fetchRequest = [model fetchRequestFromTemplateWithName:@"tracksWithNameAndArtist"
													 substitutionVariables:[NSDictionary dictionaryWithObjectsAndKeys:
														
														name_, @"name",
														
														artist_, @"artist",
														
														nil]
													 ];
	NSAssert(fetchRequest, @"Can't find fetch request named \"tracksWithNameAndArtist\".");
	
	NSArray *result = [moc_ executeFetchRequest:fetchRequest error:&error];
	if (error_) *error_ = error;
	return result;
}


@end
