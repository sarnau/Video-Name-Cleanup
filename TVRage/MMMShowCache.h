//
//  MMMShowCache.h
//  Video Name Cleanup
//
//  Created by Markus Fritze on 7/13/10.
//  Copyright 2010 Sarnau.com. All rights reserved.
//

typedef NS_ENUM(NSInteger, MMMShowSourceType) {
	MMMShowSourceTVMaze = 0,
	MMMShowSourceTheTVDB,
};

@interface MMMShowCache : NSManagedObject

@property NSNumber *source;
@property NSString *show;
@property NSNumber *orderIndex;
@property NSString *name;
@property NSString *showID;

+ (void)lookupShow:(NSString*)theShow;

@end
