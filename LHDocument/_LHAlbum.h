// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to LHAlbum.h instead.

#import <CoreData/CoreData.h>


@class LHArtist;
@class LHTrack;

@interface LHAlbumID : NSManagedObjectID {}
@end

@interface _LHAlbum : NSManagedObject {}
+ (id)insertInManagedObjectContext:(NSManagedObjectContext*)moc_;
- (LHAlbumID*)objectID;



@property (nonatomic, retain) NSString *mbid;

//- (BOOL)validateMbid:(id*)value_ error:(NSError**)error_;



@property (nonatomic, retain) NSString *name;

//- (BOOL)validateName:(id*)value_ error:(NSError**)error_;



@property (nonatomic, retain) NSString *imagePath;

//- (BOOL)validateImagePath:(id*)value_ error:(NSError**)error_;




@property (nonatomic, retain) LHArtist* artist;
//- (BOOL)validateArtist:(id*)value_ error:(NSError**)error_;



@property (nonatomic, retain) NSSet* tracks;
- (NSMutableSet*)tracksSet;




+ (NSArray*)fetchAlbumsWithNameAndArtist:(NSManagedObjectContext*)moc_ name:(NSString*)name_ artist:(LHArtist*)artist_ ;
+ (NSArray*)fetchAlbumsWithNameAndArtist:(NSManagedObjectContext*)moc_ name:(NSString*)name_ artist:(LHArtist*)artist_ error:(NSError**)error_;


@end

@interface _LHAlbum (CoreDataGeneratedAccessors)

- (void)addTracks:(NSSet*)value_;
- (void)removeTracks:(NSSet*)value_;
- (void)addTracksObject:(LHTrack*)value_;
- (void)removeTracksObject:(LHTrack*)value_;

@end
