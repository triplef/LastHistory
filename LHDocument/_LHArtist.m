// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to LHArtist.m instead.

#import "_LHArtist.h"

@implementation LHArtistID
@end

@implementation _LHArtist

+ (id)insertInManagedObjectContext:(NSManagedObjectContext*)moc_ {
	NSParameterAssert(moc_);
	return [NSEntityDescription insertNewObjectForEntityForName:@"Artist" inManagedObjectContext:moc_];
}

- (LHArtistID*)objectID {
	return (LHArtistID*)[super objectID];
}




@dynamic name;






@dynamic mbid;






@dynamic albums;

	
- (NSMutableSet*)albumsSet {
	[self willAccessValueForKey:@"albums"];
	NSMutableSet *result = [self mutableSetValueForKey:@"albums"];
	[self didAccessValueForKey:@"albums"];
	return result;
}
	

@dynamic tracks;

	
- (NSMutableSet*)tracksSet {
	[self willAccessValueForKey:@"tracks"];
	NSMutableSet *result = [self mutableSetValueForKey:@"tracks"];
	[self didAccessValueForKey:@"tracks"];
	return result;
}
	




+ (NSArray*)fetchArtistsWithName:(NSManagedObjectContext*)moc_ name:(NSString*)name_ {
	NSError *error = nil;
	NSArray *result = [self fetchArtistsWithName:moc_ name:name_ error:&error];
	if (error) {
#if TARGET_OS_IPHONE
		NSLog(@"error: %@", error);
#else
		[NSApp presentError:error];
#endif
	}
	return result;
}
+ (NSArray*)fetchArtistsWithName:(NSManagedObjectContext*)moc_ name:(NSString*)name_ error:(NSError**)error_ {
	NSError *error = nil;
	
	NSManagedObjectModel *model = [[moc_ persistentStoreCoordinator] managedObjectModel];
	NSFetchRequest *fetchRequest = [model fetchRequestFromTemplateWithName:@"artistsWithName"
													 substitutionVariables:[NSDictionary dictionaryWithObjectsAndKeys:
														
														name_, @"name",
														
														nil]
													 ];
	NSAssert(fetchRequest, @"Can't find fetch request named \"artistsWithName\".");
	
	NSArray *result = [moc_ executeFetchRequest:fetchRequest error:&error];
	if (error_) *error_ = error;
	return result;
}


@end
