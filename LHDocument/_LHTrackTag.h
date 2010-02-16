// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to LHTrackTag.h instead.

#import <CoreData/CoreData.h>


@class LHTrack;
@class LHTag;

@interface LHTrackTagID : NSManagedObjectID {}
@end

@interface _LHTrackTag : NSManagedObject {}
+ (id)insertInManagedObjectContext:(NSManagedObjectContext*)moc_;
- (LHTrackTagID*)objectID;



@property (nonatomic, retain) NSNumber *count;

@property short countValue;
- (short)countValue;
- (void)setCountValue:(short)value_;

//- (BOOL)validateCount:(id*)value_ error:(NSError**)error_;




@property (nonatomic, retain) LHTrack* track;
//- (BOOL)validateTrack:(id*)value_ error:(NSError**)error_;



@property (nonatomic, retain) LHTag* tag;
//- (BOOL)validateTag:(id*)value_ error:(NSError**)error_;



@end

@interface _LHTrackTag (CoreDataGeneratedAccessors)

@end
