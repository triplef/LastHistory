// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to LHHistoryEntry.h instead.

#import <CoreData/CoreData.h>


@class LHTrack;
@class LHUser;

@interface LHHistoryEntryID : NSManagedObjectID {}
@end

@interface _LHHistoryEntry : NSManagedObject {}
+ (id)insertInManagedObjectContext:(NSManagedObjectContext*)moc_;
- (LHHistoryEntryID*)objectID;



@property (nonatomic, retain) NSNumber *time;

@property int timeValue;
- (int)timeValue;
- (void)setTimeValue:(int)value_;

//- (BOOL)validateTime:(id*)value_ error:(NSError**)error_;



@property (nonatomic, retain) NSDate *timestamp;

//- (BOOL)validateTimestamp:(id*)value_ error:(NSError**)error_;



@property (nonatomic, retain) NSNumber *weight;

@property float weightValue;
- (float)weightValue;
- (void)setWeightValue:(float)value_;

//- (BOOL)validateWeight:(id*)value_ error:(NSError**)error_;




@property (nonatomic, retain) LHTrack* track;
//- (BOOL)validateTrack:(id*)value_ error:(NSError**)error_;



@property (nonatomic, retain) LHUser* user;
//- (BOOL)validateUser:(id*)value_ error:(NSError**)error_;



@end

@interface _LHHistoryEntry (CoreDataGeneratedAccessors)

@end
