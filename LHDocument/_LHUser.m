// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to LHUser.m instead.

#import "_LHUser.h"

@implementation LHUserID
@end

@implementation _LHUser

+ (id)insertInManagedObjectContext:(NSManagedObjectContext*)moc_ {
	NSParameterAssert(moc_);
	return [NSEntityDescription insertNewObjectForEntityForName:@"User" inManagedObjectContext:moc_];
}

- (LHUserID*)objectID {
	return (LHUserID*)[super objectID];
}




@dynamic name;






@dynamic historyEntries;

	
- (NSMutableSet*)historyEntriesSet {
	[self willAccessValueForKey:@"historyEntries"];
	NSMutableSet *result = [self mutableSetValueForKey:@"historyEntries"];
	[self didAccessValueForKey:@"historyEntries"];
	return result;
}
	




+ (NSArray*)fetchUsersWithName:(NSManagedObjectContext*)moc_ name:(NSString*)name_ {
	NSError *error = nil;
	NSArray *result = [self fetchUsersWithName:moc_ name:name_ error:&error];
	if (error) {
#if TARGET_OS_IPHONE
		NSLog(@"error: %@", error);
#else
		[NSApp presentError:error];
#endif
	}
	return result;
}
+ (NSArray*)fetchUsersWithName:(NSManagedObjectContext*)moc_ name:(NSString*)name_ error:(NSError**)error_ {
	NSError *error = nil;
	
	NSManagedObjectModel *model = [[moc_ persistentStoreCoordinator] managedObjectModel];
	NSFetchRequest *fetchRequest = [model fetchRequestFromTemplateWithName:@"usersWithName"
													 substitutionVariables:[NSDictionary dictionaryWithObjectsAndKeys:
														
														name_, @"name",
														
														nil]
													 ];
	NSAssert(fetchRequest, @"Can't find fetch request named \"usersWithName\".");
	
	NSArray *result = [moc_ executeFetchRequest:fetchRequest error:&error];
	if (error_) *error_ = error;
	return result;
}


@end
