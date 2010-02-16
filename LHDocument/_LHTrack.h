// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to LHTrack.h instead.

#import <CoreData/CoreData.h>


@class LHTrackTag;
@class LHAlbum;
@class LHArtist;
@class LHHistoryEntry;

@interface LHTrackID : NSManagedObjectID {}
@end

@interface _LHTrack : NSManagedObject {}
+ (id)insertInManagedObjectContext:(NSManagedObjectContext*)moc_;
- (LHTrackID*)objectID;



@property (nonatomic, retain) NSString *name;

//- (BOOL)validateName:(id*)value_ error:(NSError**)error_;



@property (nonatomic, retain) NSString *mbid;

//- (BOOL)validateMbid:(id*)value_ error:(NSError**)error_;




@property (nonatomic, retain) NSSet* trackTags;
- (NSMutableSet*)trackTagsSet;



@property (nonatomic, retain) LHAlbum* album;
//- (BOOL)validateAlbum:(id*)value_ error:(NSError**)error_;



@property (nonatomic, retain) LHArtist* artist;
//- (BOOL)validateArtist:(id*)value_ error:(NSError**)error_;



@property (nonatomic, retain) NSSet* historyEntries;
- (NSMutableSet*)historyEntriesSet;




+ (NSArray*)fetchTracksWithNameAndArtist:(NSManagedObjectContext*)moc_ name:(NSString*)name_ artist:(LHArtist*)artist_ ;
+ (NSArray*)fetchTracksWithNameAndArtist:(NSManagedObjectContext*)moc_ name:(NSString*)name_ artist:(LHArtist*)artist_ error:(NSError**)error_;


@end

@interface _LHTrack (CoreDataGeneratedAccessors)

- (void)addTrackTags:(NSSet*)value_;
- (void)removeTrackTags:(NSSet*)value_;
- (void)addTrackTagsObject:(LHTrackTag*)value_;
- (void)removeTrackTagsObject:(LHTrackTag*)value_;

- (void)addHistoryEntries:(NSSet*)value_;
- (void)removeHistoryEntries:(NSSet*)value_;
- (void)addHistoryEntriesObject:(LHHistoryEntry*)value_;
- (void)removeHistoryEntriesObject:(LHHistoryEntry*)value_;

@end
