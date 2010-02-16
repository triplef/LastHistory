// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to LHTag.h instead.

#import <CoreData/CoreData.h>


@class LHTrackTag;

@interface LHTagID : NSManagedObjectID {}
@end

@interface _LHTag : NSManagedObject {}
+ (id)insertInManagedObjectContext:(NSManagedObjectContext*)moc_;
- (LHTagID*)objectID;



@property (nonatomic, retain) NSString *name;

//- (BOOL)validateName:(id*)value_ error:(NSError**)error_;




@property (nonatomic, retain) NSSet* trackTags;
- (NSMutableSet*)trackTagsSet;




+ (NSArray*)fetchTagsWithName:(NSManagedObjectContext*)moc_ name:(NSString*)name_ ;
+ (NSArray*)fetchTagsWithName:(NSManagedObjectContext*)moc_ name:(NSString*)name_ error:(NSError**)error_;


@end

@interface _LHTag (CoreDataGeneratedAccessors)

- (void)addTrackTags:(NSSet*)value_;
- (void)removeTrackTags:(NSSet*)value_;
- (void)addTrackTagsObject:(LHTrackTag*)value_;
- (void)removeTrackTagsObject:(LHTrackTag*)value_;

@end
