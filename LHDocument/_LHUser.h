// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to LHUser.h instead.

#import <CoreData/CoreData.h>


@class LHHistoryEntry;

@interface LHUserID : NSManagedObjectID {}
@end

@interface _LHUser : NSManagedObject {}
+ (id)insertInManagedObjectContext:(NSManagedObjectContext*)moc_;
- (LHUserID*)objectID;



@property (nonatomic, retain) NSString *name;

//- (BOOL)validateName:(id*)value_ error:(NSError**)error_;




@property (nonatomic, retain) NSSet* historyEntries;
- (NSMutableSet*)historyEntriesSet;




+ (NSArray*)fetchUsersWithName:(NSManagedObjectContext*)moc_ name:(NSString*)name_ ;
+ (NSArray*)fetchUsersWithName:(NSManagedObjectContext*)moc_ name:(NSString*)name_ error:(NSError**)error_;


@end

@interface _LHUser (CoreDataGeneratedAccessors)

- (void)addHistoryEntries:(NSSet*)value_;
- (void)removeHistoryEntries:(NSSet*)value_;
- (void)addHistoryEntriesObject:(LHHistoryEntry*)value_;
- (void)removeHistoryEntriesObject:(LHHistoryEntry*)value_;

@end
