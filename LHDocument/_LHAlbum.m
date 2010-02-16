// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to LHAlbum.m instead.

#import "_LHAlbum.h"

@implementation LHAlbumID
@end

@implementation _LHAlbum

+ (id)insertInManagedObjectContext:(NSManagedObjectContext*)moc_ {
	NSParameterAssert(moc_);
	return [NSEntityDescription insertNewObjectForEntityForName:@"Album" inManagedObjectContext:moc_];
}

- (LHAlbumID*)objectID {
	return (LHAlbumID*)[super objectID];
}




@dynamic mbid;






@dynamic name;






@dynamic imagePath;






@dynamic artist;

	

@dynamic tracks;

	
- (NSMutableSet*)tracksSet {
	[self willAccessValueForKey:@"tracks"];
	NSMutableSet *result = [self mutableSetValueForKey:@"tracks"];
	[self didAccessValueForKey:@"tracks"];
	return result;
}
	




+ (NSArray*)fetchAlbumsWithNameAndArtist:(NSManagedObjectContext*)moc_ name:(NSString*)name_ artist:(LHArtist*)artist_ {
	NSError *error = nil;
	NSArray *result = [self fetchAlbumsWithNameAndArtist:moc_ name:name_ artist:artist_ error:&error];
	if (error) {
#if TARGET_OS_IPHONE
		NSLog(@"error: %@", error);
#else
		[NSApp presentError:error];
#endif
	}
	return result;
}
+ (NSArray*)fetchAlbumsWithNameAndArtist:(NSManagedObjectContext*)moc_ name:(NSString*)name_ artist:(LHArtist*)artist_ error:(NSError**)error_ {
	NSError *error = nil;
	
	NSManagedObjectModel *model = [[moc_ persistentStoreCoordinator] managedObjectModel];
	NSFetchRequest *fetchRequest = [model fetchRequestFromTemplateWithName:@"albumsWithNameAndArtist"
													 substitutionVariables:[NSDictionary dictionaryWithObjectsAndKeys:
														
														name_, @"name",
														
														artist_, @"artist",
														
														nil]
													 ];
	NSAssert(fetchRequest, @"Can't find fetch request named \"albumsWithNameAndArtist\".");
	
	NSArray *result = [moc_ executeFetchRequest:fetchRequest error:&error];
	if (error_) *error_ = error;
	return result;
}


@end
