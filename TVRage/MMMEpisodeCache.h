//
//  MMMEpisodeCache.h
//  Video Name Cleanup
//
//  Created by Markus Fritze on 7/13/10.
//  Copyright 2010 Sarnau.com. All rights reserved.
//

#import "MMMShowCache.h"

@interface MMMEpisodeCache : NSManagedObject

@property NSNumber	*source;
@property NSNumber	*season;
@property NSNumber	*seasonnum;
@property NSString	*show;
@property NSString	*title;

+ (void)lookupEpisodesforShow:(MMMShowCache*)theShow;
+ (NSString*)stringForShow:(NSString*)theShow season:(NSNumber*)theSeason episode:(NSNumber*)theEpisode;

@end
