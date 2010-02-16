//
//  LHTagRetrievalOperation.h
//  LastHistory
//
//  Created by Frederik Seiffert on 19.11.09.
//  Copyright 2009 Frederik Seiffert. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "LHOperation.h"


@interface LHTagRetrievalOperation : LHOperation {
	NSEntityDescription	*_tagEntity;
	NSEntityDescription	*_trackTagEntity;
}
@end
