//
//  LHHistoryRetrievalOperation.h
//  LastHistory
//
//  Created by Frederik Seiffert on 13.12.09.
//  Copyright 2009 Frederik Seiffert. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "LHOperation.h"

@class LHUser;
@class LHHistoryEntry;


@interface LHHistoryRetrievalOperation : LHOperation {
	LHUser *_user;
	
	LHHistoryEntry *_firstHistoryEntry;
	LHHistoryEntry *_lastHistoryEntry;
	
	NSEntityDescription	*_historyEntryEntity;
	NSEntityDescription	*_trackEntity;
	NSEntityDescription	*_albumEntity;
	NSEntityDescription	*_artistEntity;
}

- (id)initWithDocument:(LHDocument *)document andUsername:(NSString *)username;

@end
