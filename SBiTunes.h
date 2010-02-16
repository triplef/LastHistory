/*
 * SBiTunes.h
 */

#import <AppKit/AppKit.h>
#import <ScriptingBridge/ScriptingBridge.h>


@class SBiTunesPrintSettings, SBiTunesApplication, SBiTunesItem, SBiTunesArtwork, SBiTunesEncoder, SBiTunesEQPreset, SBiTunesPlaylist, SBiTunesAudioCDPlaylist, SBiTunesDevicePlaylist, SBiTunesLibraryPlaylist, SBiTunesRadioTunerPlaylist, SBiTunesSource, SBiTunesTrack, SBiTunesAudioCDTrack, SBiTunesDeviceTrack, SBiTunesFileTrack, SBiTunesSharedTrack, SBiTunesURLTrack, SBiTunesUserPlaylist, SBiTunesFolderPlaylist, SBiTunesVisual, SBiTunesWindow, SBiTunesBrowserWindow, SBiTunesEQWindow, SBiTunesPlaylistWindow;

enum SBiTunesEKnd {
	SBiTunesEKndTrackListing = 'kTrk' /* a basic listing of tracks within a playlist */,
	SBiTunesEKndAlbumListing = 'kAlb' /* a listing of a playlist grouped by album */,
	SBiTunesEKndCdInsert = 'kCDi' /* a printout of the playlist for jewel case inserts */
};
typedef enum SBiTunesEKnd SBiTunesEKnd;

enum SBiTunesEnum {
	SBiTunesEnumStandard = 'lwst' /* Standard PostScript error handling */,
	SBiTunesEnumDetailed = 'lwdt' /* print a detailed report of PostScript errors */
};
typedef enum SBiTunesEnum SBiTunesEnum;

enum SBiTunesEPlS {
	SBiTunesEPlSStopped = 'kPSS',
	SBiTunesEPlSPlaying = 'kPSP',
	SBiTunesEPlSPaused = 'kPSp',
	SBiTunesEPlSFastForwarding = 'kPSF',
	SBiTunesEPlSRewinding = 'kPSR'
};
typedef enum SBiTunesEPlS SBiTunesEPlS;

enum SBiTunesERpt {
	SBiTunesERptOff = 'kRpO',
	SBiTunesERptOne = 'kRp1',
	SBiTunesERptAll = 'kAll'
};
typedef enum SBiTunesERpt SBiTunesERpt;

enum SBiTunesEVSz {
	SBiTunesEVSzSmall = 'kVSS',
	SBiTunesEVSzMedium = 'kVSM',
	SBiTunesEVSzLarge = 'kVSL'
};
typedef enum SBiTunesEVSz SBiTunesEVSz;

enum SBiTunesESrc {
	SBiTunesESrcLibrary = 'kLib',
	SBiTunesESrcIPod = 'kPod',
	SBiTunesESrcAudioCD = 'kACD',
	SBiTunesESrcMP3CD = 'kMCD',
	SBiTunesESrcDevice = 'kDev',
	SBiTunesESrcRadioTuner = 'kTun',
	SBiTunesESrcSharedLibrary = 'kShd',
	SBiTunesESrcUnknown = 'kUnk'
};
typedef enum SBiTunesESrc SBiTunesESrc;

enum SBiTunesESrA {
	SBiTunesESrAAlbums = 'kSrL' /* albums only */,
	SBiTunesESrAAll = 'kAll' /* all text fields */,
	SBiTunesESrAArtists = 'kSrR' /* artists only */,
	SBiTunesESrAComposers = 'kSrC' /* composers only */,
	SBiTunesESrADisplayed = 'kSrV' /* visible text fields */,
	SBiTunesESrASongs = 'kSrS' /* song names only */
};
typedef enum SBiTunesESrA SBiTunesESrA;

enum SBiTunesESpK {
	SBiTunesESpKNone = 'kNon',
	SBiTunesESpKAudiobooks = 'kSpA',
	SBiTunesESpKFolder = 'kSpF',
	SBiTunesESpKMovies = 'kSpI',
	SBiTunesESpKMusic = 'kSpZ',
	SBiTunesESpKPartyShuffle = 'kSpS',
	SBiTunesESpKPodcasts = 'kSpP',
	SBiTunesESpKPurchasedMusic = 'kSpM',
	SBiTunesESpKTVShows = 'kSpT',
	SBiTunesESpKVideos = 'kSpV'
};
typedef enum SBiTunesESpK SBiTunesESpK;

enum SBiTunesEVdK {
	SBiTunesEVdKNone = 'kNon' /* not a video or unknown video kind */,
	SBiTunesEVdKMovie = 'kVdM' /* movie track */,
	SBiTunesEVdKMusicVideo = 'kVdV' /* music video track */,
	SBiTunesEVdKTVShow = 'kVdT' /* TV show track */
};
typedef enum SBiTunesEVdK SBiTunesEVdK;

enum SBiTunesERtK {
	SBiTunesERtKUser = 'kRtU' /* user-specified rating */,
	SBiTunesERtKComputed = 'kRtC' /* iTunes-computed rating */
};
typedef enum SBiTunesERtK SBiTunesERtK;



/*
 * Standard Suite
 */

@interface SBiTunesPrintSettings : SBObject

@property (readonly) NSInteger copies;  // the number of copies of a document to be printed
@property (readonly) BOOL collating;  // Should printed copies be collated?
@property (readonly) NSInteger startingPage;  // the first page of the document to be printed
@property (readonly) NSInteger endingPage;  // the last page of the document to be printed
@property (readonly) NSInteger pagesAcross;  // number of logical pages laid across a physical page
@property (readonly) NSInteger pagesDown;  // number of logical pages laid out down a physical page
@property (readonly) SBiTunesEnum errorHandling;  // how errors are handled
@property (copy, readonly) NSDate *requestedPrintTime;  // the time at which the desktop printer should print the document
@property (copy, readonly) NSArray *printerFeatures;  // printer specific options
@property (copy, readonly) NSString *faxNumber;  // for fax number
@property (copy, readonly) NSString *targetPrinter;  // for target printer

- (void) printPrintDialog:(BOOL)printDialog withProperties:(SBiTunesPrintSettings *)withProperties kind:(SBiTunesEKnd)kind theme:(NSString *)theme;  // Print the specified object(s)
- (void) close;  // Close an object
- (void) delete;  // Delete an element from an object
- (SBObject *) duplicateTo:(SBObject *)to;  // Duplicate one or more object(s)
- (BOOL) exists;  // Verify if an object exists
- (void) open;  // open the specified object(s)
- (void) playOnce:(BOOL)once;  // play the current track or the specified track or file.

@end



/*
 * iTunes Suite
 */

// The application program
@interface SBiTunesApplication : SBApplication

- (SBElementArray *) browserWindows;
- (SBElementArray *) encoders;
- (SBElementArray *) EQPresets;
- (SBElementArray *) EQWindows;
- (SBElementArray *) playlistWindows;
- (SBElementArray *) sources;
- (SBElementArray *) visuals;
- (SBElementArray *) windows;

@property (copy) SBiTunesEncoder *currentEncoder;  // the currently selected encoder (MP3, AIFF, WAV, etc.)
@property (copy) SBiTunesEQPreset *currentEQPreset;  // the currently selected equalizer preset
@property (copy, readonly) SBiTunesPlaylist *currentPlaylist;  // the playlist containing the currently targeted track
@property (copy, readonly) NSString *currentStreamTitle;  // the name of the current song in the playing stream (provided by streaming server)
@property (copy, readonly) NSString *currentStreamURL;  // the URL of the playing stream or streaming web site (provided by streaming server)
@property (copy, readonly) SBiTunesTrack *currentTrack;  // the current targeted track
@property (copy) SBiTunesVisual *currentVisual;  //  the currently selected visual plug-in
@property BOOL EQEnabled;  // is the equalizer enabled?
@property BOOL fixedIndexing;  // true if all AppleScript track indices should be independent of the play order of the owning playlist.
@property BOOL frontmost;  // is iTunes the frontmost application?
@property BOOL fullScreen;  // are visuals displayed using the entire screen?
@property (copy, readonly) NSString *name;  // the name of the application
@property BOOL mute;  // has the sound output been muted?
@property NSInteger playerPosition;  // the player’s position within the currently playing track in seconds.
@property (readonly) SBiTunesEPlS playerState;  // is iTunes stopped, paused, or playing?
@property (copy, readonly) SBObject *selection;  // the selection visible to the user
@property NSInteger soundVolume;  // the sound output volume (0 = minimum, 100 = maximum)
@property (copy, readonly) NSString *version;  // the version of iTunes
@property BOOL visualsEnabled;  // are visuals currently being displayed?
@property SBiTunesEVSz visualSize;  // the size of the displayed visual

- (void) printPrintDialog:(BOOL)printDialog withProperties:(SBiTunesPrintSettings *)withProperties kind:(SBiTunesEKnd)kind theme:(NSString *)theme;  // Print the specified object(s)
- (void) run;  // run iTunes
- (void) quit;  // quit iTunes
- (SBiTunesTrack *) add:(NSArray *)x to:(SBObject *)to;  // add one or more files to a playlist
- (void) backTrack;  // reposition to beginning of current track or go to previous track if already at start of current track
- (SBiTunesTrack *) convert:(NSArray *)x;  // convert one or more files or tracks
- (void) fastForward;  // skip forward in a playing track
- (void) nextTrack;  // advance to the next track in the current playlist
- (void) pause;  // pause playback
- (void) playOnce:(BOOL)once;  // play the current track or the specified track or file.
- (void) playpause;  // toggle the playing/paused state of the current track
- (void) previousTrack;  // return to the previous track in the current playlist
- (void) resume;  // disable fast forward/rewind and resume playback, if playing.
- (void) rewind;  // skip backwards in a playing track
- (void) stop;  // stop playback
- (void) update;  // update the specified iPod
- (void) eject;  // eject the specified iPod
- (void) subscribe:(NSString *)x;  // subscribe to a podcast feed
- (void) updateAllPodcasts;  // update all subscribed podcast feeds
- (void) updatePodcast;  // update podcast feed
- (void) openLocation:(NSString *)x;  // Opens a Music Store or audio stream URL

@end

// an item
@interface SBiTunesItem : SBObject

@property (copy, readonly) SBObject *container;  // the container of the item
- (NSInteger) id;  // the id of the item
@property (readonly) NSInteger index;  // The index of the item in internal application order.
@property (copy) NSString *name;  // the name of the item
@property (copy, readonly) NSString *persistentID;  // the id of the item as a hexidecimal string. This id does not change over time.

- (void) printPrintDialog:(BOOL)printDialog withProperties:(SBiTunesPrintSettings *)withProperties kind:(SBiTunesEKnd)kind theme:(NSString *)theme;  // Print the specified object(s)
- (void) close;  // Close an object
- (void) delete;  // Delete an element from an object
- (SBObject *) duplicateTo:(SBObject *)to;  // Duplicate one or more object(s)
- (BOOL) exists;  // Verify if an object exists
- (void) open;  // open the specified object(s)
- (void) playOnce:(BOOL)once;  // play the current track or the specified track or file.
- (void) reveal;  // reveal and select a track or playlist

@end

// a piece of art within a track
@interface SBiTunesArtwork : SBiTunesItem

@property (copy) NSImage *data;  // data for this artwork, in the form of a picture
@property (copy) NSString *objectDescription;  // description of artwork as a string
@property (readonly) BOOL downloaded;  // was this artwork downloaded by iTunes?
@property (copy, readonly) NSNumber *format;  // the data format for this piece of artwork
@property NSInteger kind;  // kind or purpose of this piece of artwork
@property (copy) NSData *rawData;  // data for this artwork, in original format


@end

// converts a track to a specific file format
@interface SBiTunesEncoder : SBiTunesItem

@property (copy, readonly) NSString *format;  // the data format created by the encoder


@end

// equalizer preset configuration
@interface SBiTunesEQPreset : SBiTunesItem

@property double band1;  // the equalizer 32 Hz band level (-12.0 dB to +12.0 dB)
@property double band2;  // the equalizer 64 Hz band level (-12.0 dB to +12.0 dB)
@property double band3;  // the equalizer 125 Hz band level (-12.0 dB to +12.0 dB)
@property double band4;  // the equalizer 250 Hz band level (-12.0 dB to +12.0 dB)
@property double band5;  // the equalizer 500 Hz band level (-12.0 dB to +12.0 dB)
@property double band6;  // the equalizer 1 kHz band level (-12.0 dB to +12.0 dB)
@property double band7;  // the equalizer 2 kHz band level (-12.0 dB to +12.0 dB)
@property double band8;  // the equalizer 4 kHz band level (-12.0 dB to +12.0 dB)
@property double band9;  // the equalizer 8 kHz band level (-12.0 dB to +12.0 dB)
@property double band10;  // the equalizer 16 kHz band level (-12.0 dB to +12.0 dB)
@property (readonly) BOOL modifiable;  // can this preset be modified?
@property double preamp;  // the equalizer preamp level (-12.0 dB to +12.0 dB)
@property BOOL updateTracks;  // should tracks which refer to this preset be updated when the preset is renamed or deleted?


@end

// a list of songs/streams
@interface SBiTunesPlaylist : SBiTunesItem

- (SBElementArray *) tracks;

@property (readonly) NSInteger duration;  // the total length of all songs (in seconds)
@property (copy) NSString *name;  // the name of the playlist
@property (copy, readonly) SBiTunesPlaylist *parent;  // folder which contains this playlist (if any)
@property BOOL shuffle;  // play the songs in this playlist in random order?
@property (readonly) long long size;  // the total size of all songs (in bytes)
@property SBiTunesERpt songRepeat;  // playback repeat mode
@property (readonly) SBiTunesESpK specialKind;  // special playlist kind
@property (copy, readonly) NSString *time;  // the length of all songs in MM:SS format
@property (readonly) BOOL visible;  // is this playlist visible in the Source list?

- (void) moveTo:(SBObject *)to;  // Move playlist(s) to a new location
- (SBiTunesTrack *) searchFor:(NSString *)for_ only:(SBiTunesESrA)only;  // search a playlist for tracks matching the search string. Identical to entering search text in the Search field in iTunes.

@end

// a playlist representing an audio CD
@interface SBiTunesAudioCDPlaylist : SBiTunesPlaylist

- (SBElementArray *) audioCDTracks;

@property (copy) NSString *artist;  // the artist of the CD
@property BOOL compilation;  // is this CD a compilation album?
@property (copy) NSString *composer;  // the composer of the CD
@property NSInteger discCount;  // the total number of discs in this CD’s album
@property NSInteger discNumber;  // the index of this CD disc in the source album
@property (copy) NSString *genre;  // the genre of the CD
@property NSInteger year;  // the year the album was recorded/released


@end

// a playlist representing the contents of a portable device
@interface SBiTunesDevicePlaylist : SBiTunesPlaylist

- (SBElementArray *) deviceTracks;


@end

// the master music library playlist
@interface SBiTunesLibraryPlaylist : SBiTunesPlaylist

- (SBElementArray *) fileTracks;
- (SBElementArray *) URLTracks;
- (SBElementArray *) sharedTracks;


@end

// the radio tuner playlist
@interface SBiTunesRadioTunerPlaylist : SBiTunesPlaylist

- (SBElementArray *) URLTracks;


@end

// a music source (music library, CD, device, etc.)
@interface SBiTunesSource : SBiTunesItem

- (SBElementArray *) audioCDPlaylists;
- (SBElementArray *) devicePlaylists;
- (SBElementArray *) libraryPlaylists;
- (SBElementArray *) playlists;
- (SBElementArray *) radioTunerPlaylists;
- (SBElementArray *) userPlaylists;

@property (readonly) long long capacity;  // the total size of the source if it has a fixed size
@property (readonly) long long freeSpace;  // the free space on the source if it has a fixed size
@property (readonly) SBiTunesESrc kind;

- (void) update;  // update the specified iPod
- (void) eject;  // eject the specified iPod

@end

// playable audio source
@interface SBiTunesTrack : SBiTunesItem

- (SBElementArray *) artworks;

@property (copy) NSString *album;  // the album name of the track
@property (copy) NSString *albumArtist;  // the album artist of the track
@property NSInteger albumRating;  // the rating of the album for this track (0 to 100)
@property (readonly) SBiTunesERtK albumRatingKind;  // the rating kind of the album rating for this track
@property (copy) NSString *artist;  // the artist/source of the track
@property (readonly) NSInteger bitRate;  // the bit rate of the track (in kbps)
@property double bookmark;  // the bookmark time of the track in seconds
@property BOOL bookmarkable;  // is the playback position for this track remembered?
@property NSInteger bpm;  // the tempo of this track in beats per minute
@property (copy) NSString *category;  // the category of the track
@property (copy) NSString *comment;  // freeform notes about the track
@property BOOL compilation;  // is this track from a compilation album?
@property (copy) NSString *composer;  // the composer of the track
@property (readonly) NSInteger databaseID;  // the common, unique ID for this track. If two tracks in different playlists have the same database ID, they are sharing the same data.
@property (copy, readonly) NSDate *dateAdded;  // the date the track was added to the playlist
@property (copy) NSString *objectDescription;  // the description of the track
@property NSInteger discCount;  // the total number of discs in the source album
@property NSInteger discNumber;  // the index of the disc containing this track on the source album
@property (readonly) double duration;  // the length of the track in seconds
@property BOOL enabled;  // is this track checked for playback?
@property (copy) NSString *episodeID;  // the episode ID of the track
@property NSInteger episodeNumber;  // the episode number of the track
@property (copy) NSString *EQ;  // the name of the EQ preset of the track
@property double finish;  // the stop time of the track in seconds
@property BOOL gapless;  // is this track from a gapless album?
@property (copy) NSString *genre;  // the music/audio genre (category) of the track
@property (copy) NSString *grouping;  // the grouping (piece) of the track. Generally used to denote movements within a classical work.
@property (copy, readonly) NSString *kind;  // a text description of the track
@property (copy) NSString *longDescription;
@property (copy) NSString *lyrics;  // the lyrics of the track
@property (copy, readonly) NSDate *modificationDate;  // the modification date of the content of this track
@property NSInteger playedCount;  // number of times this track has been played
@property (copy) NSDate *playedDate;  // the date and time this track was last played
@property (readonly) BOOL podcast;  // is this track a podcast episode?
@property NSInteger rating;  // the rating of this track (0 to 100)
@property (readonly) SBiTunesERtK ratingKind;  // the rating kind of this track
@property (copy, readonly) NSDate *releaseDate;  // the release date of this track
@property (readonly) NSInteger sampleRate;  // the sample rate of the track (in Hz)
@property NSInteger seasonNumber;  // the season number of the track
@property BOOL shufflable;  // is this track included when shuffling?
@property NSInteger skippedCount;  // number of times this track has been skipped
@property (copy) NSDate *skippedDate;  // the date and time this track was last skipped
@property (copy) NSString *show;  // the show name of the track
@property (copy) NSString *sortAlbum;  // override string to use for the track when sorting by album
@property (copy) NSString *sortArtist;  // override string to use for the track when sorting by artist
@property (copy) NSString *sortAlbumArtist;  // override string to use for the track when sorting by album artist
@property (copy) NSString *sortName;  // override string to use for the track when sorting by name
@property (copy) NSString *sortComposer;  // override string to use for the track when sorting by composer
@property (copy) NSString *sortShow;  // override string to use for the track when sorting by show name
@property (readonly) NSInteger size;  // the size of the track (in bytes)
@property double start;  // the start time of the track in seconds
@property (copy, readonly) NSString *time;  // the length of the track in MM:SS format
@property NSInteger trackCount;  // the total number of tracks on the source album
@property NSInteger trackNumber;  // the index of the track on the source album
@property BOOL unplayed;  // is this track unplayed?
@property SBiTunesEVdK videoKind;  // kind of video track
@property NSInteger volumeAdjustment;  // relative volume adjustment of the track (-100% to 100%)
@property NSInteger year;  // the year the track was recorded/released


@end

// a track on an audio CD
@interface SBiTunesAudioCDTrack : SBiTunesTrack

@property (copy, readonly) NSURL *location;  // the location of the file represented by this track


@end

// a track residing on a portable music player
@interface SBiTunesDeviceTrack : SBiTunesTrack


@end

// a track representing an audio file (MP3, AIFF, etc.)
@interface SBiTunesFileTrack : SBiTunesTrack

@property (copy) NSURL *location;  // the location of the file represented by this track

- (void) refresh;  // update file track information from the current information in the track’s file

@end

// a track residing in a shared library
@interface SBiTunesSharedTrack : SBiTunesTrack


@end

// a track representing a network stream
@interface SBiTunesURLTrack : SBiTunesTrack

@property (copy) NSString *address;  // the URL for this track

- (void) download;  // download podcast episode

@end

// custom playlists created by the user
@interface SBiTunesUserPlaylist : SBiTunesPlaylist

- (SBElementArray *) fileTracks;
- (SBElementArray *) URLTracks;
- (SBElementArray *) sharedTracks;

@property BOOL shared;  // is this playlist shared?
@property (readonly) BOOL smart;  // is this a Smart Playlist?


@end

// a folder that contains other playlists
@interface SBiTunesFolderPlaylist : SBiTunesUserPlaylist


@end

// a visual plug-in
@interface SBiTunesVisual : SBiTunesItem


@end

// any window
@interface SBiTunesWindow : SBiTunesItem

@property NSRect bounds;  // the boundary rectangle for the window
@property (readonly) BOOL closeable;  // does the window have a close box?
@property (readonly) BOOL collapseable;  // does the window have a collapse (windowshade) box?
@property BOOL collapsed;  // is the window collapsed?
@property NSPoint position;  // the upper left position of the window
@property (readonly) BOOL resizable;  // is the window resizable?
@property BOOL visible;  // is the window visible?
@property (readonly) BOOL zoomable;  // is the window zoomable?
@property BOOL zoomed;  // is the window zoomed?


@end

// the main iTunes window
@interface SBiTunesBrowserWindow : SBiTunesWindow

@property BOOL minimized;  // is the small player visible?
@property (copy, readonly) SBObject *selection;  // the selected songs
@property (copy) SBiTunesPlaylist *view;  // the playlist currently displayed in the window


@end

// the iTunes equalizer window
@interface SBiTunesEQWindow : SBiTunesWindow

@property BOOL minimized;  // is the small EQ window visible?


@end

// a sub-window showing a single playlist
@interface SBiTunesPlaylistWindow : SBiTunesWindow

@property (copy, readonly) SBObject *selection;  // the selected songs
@property (copy, readonly) SBiTunesPlaylist *view;  // the playlist displayed in the window


@end

