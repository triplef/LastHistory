// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to LHTag.m instead.

#import "_LHTag.h"

@implementation LHTagID
@end

@implementation _LHTag

+ (id)insertInManagedObjectContext:(NSManagedObjectContext*)moc_ {
	NSParameterAssert(moc_);
	return [NSEntityDescription insertNewObjectForEntityForName:@"Tag" inManagedObjectContext:moc_];
}

- (LHTagID*)objectID {
	return (LHTagID*)[super objectID];
}




@dynamic name;






@dynamic trackTags;

	
- (NSMutableSet*)trackTagsSet {
	[self willAccessValueForKey:@"trackTags"];
	NSMutableSet *result = [self mutableSetValueForKey:@"trackTags"];
	[self didAccessValueForKey:@"trackTags"];
	return result;
}
	




+ (NSArray*)fetchTagsWithName:(NSManagedObjectContext*)moc_ name:(NSString*)name_ {
	NSError *error = nil;
	NSArray *result = [self fetchTagsWithName:moc_ name:name_ error:&error];
	if (error) {
#if TARGET_OS_IPHONE
		NSLog(@"error: %@", error);
#else
		[NSApp presentError:error];
#endif
	}
	return result;
}
+ (NSArray*)fetchTagsWithName:(NSManagedObjectContext*)moc_ name:(NSString*)name_ error:(NSError**)error_ {
	NSError *error = nil;
	
	NSManagedObjectModel *model = [[moc_ persistentStoreCoordinator] managedObjectModel];
	NSFetchRequest *fetchRequest = [model fetchRequestFromTemplateWithName:@"tagsWithName"
													 substitutionVariables:[NSDictionary dictionaryWithObjectsAndKeys:
														
														name_, @"name",
														
														nil]
													 ];
	NSAssert(fetchRequest, @"Can't find fetch request named \"tagsWithName\".");
	
	NSArray *result = [moc_ executeFetchRequest:fetchRequest error:&error];
	if (error_) *error_ = error;
	return result;
}


@end
