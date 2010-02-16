// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to LHTrackTag.m instead.

#import "_LHTrackTag.h"

@implementation LHTrackTagID
@end

@implementation _LHTrackTag

+ (id)insertInManagedObjectContext:(NSManagedObjectContext*)moc_ {
	NSParameterAssert(moc_);
	return [NSEntityDescription insertNewObjectForEntityForName:@"TrackTag" inManagedObjectContext:moc_];
}

- (LHTrackTagID*)objectID {
	return (LHTrackTagID*)[super objectID];
}




@dynamic count;



- (short)countValue {
	NSNumber *result = [self count];
	return result ? [result shortValue] : 0;
}

- (void)setCountValue:(short)value_ {
	[self setCount:[NSNumber numberWithShort:value_]];
}






@dynamic track;

	

@dynamic tag;

	



@end
