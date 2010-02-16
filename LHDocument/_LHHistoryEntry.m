// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to LHHistoryEntry.m instead.

#import "_LHHistoryEntry.h"

@implementation LHHistoryEntryID
@end

@implementation _LHHistoryEntry

+ (id)insertInManagedObjectContext:(NSManagedObjectContext*)moc_ {
	NSParameterAssert(moc_);
	return [NSEntityDescription insertNewObjectForEntityForName:@"HistoryEntry" inManagedObjectContext:moc_];
}

- (LHHistoryEntryID*)objectID {
	return (LHHistoryEntryID*)[super objectID];
}




@dynamic time;



- (int)timeValue {
	NSNumber *result = [self time];
	return result ? [result intValue] : 0;
}

- (void)setTimeValue:(int)value_ {
	[self setTime:[NSNumber numberWithInt:value_]];
}






@dynamic timestamp;






@dynamic weight;



- (float)weightValue {
	NSNumber *result = [self weight];
	return result ? [result floatValue] : 0;
}

- (void)setWeightValue:(float)value_ {
	[self setWeight:[NSNumber numberWithFloat:value_]];
}






@dynamic track;

	

@dynamic user;

	



@end
