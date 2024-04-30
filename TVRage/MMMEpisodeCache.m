//
//  MMMEpisodeCache.m
//  Video Name Cleanup
//
//  Created by Markus Fritze on 7/13/10.
//  Copyright 2010 Sarnau.com. All rights reserved.
//

#import "MMMEpisodeCache.h"
#import "MMMShowCache.h"
#import "NSFileManager_Extensions.h"
#import "ZipArchive.h"
#import "Video_Name_Cleanup_AppDelegate.h"

@implementation MMMEpisodeCache

@dynamic source,season,seasonnum,show,title;

/***
 *
 ***/
+ (void)lookupEpisodesforShow:(MMMShowCache*)theShow
{
	NSString	*selectedLanguage = [[NSUserDefaults standardUserDefaults] objectForKey:@"DBLanguage"];
	if(!selectedLanguage)
		selectedLanguage = @"en";

	NSString	*episodesFolder = @"episodes";
	if(![selectedLanguage isEqualToString:@"en"])
		episodesFolder = [episodesFolder stringByAppendingString:selectedLanguage];

	// Check if we already have the show in the database, if so: do nothing!
	NSError		*error;
	NSManagedObjectContext	*context = [(Video_Name_Cleanup_AppDelegate*)[NSApp delegate] managedObjectContext];
	NSEntityDescription			*showEntity = [NSEntityDescription entityForName:@"EpisodeCache" inManagedObjectContext:context];

	NSFetchRequest *request = [[NSFetchRequest alloc] init];
	request.entity = showEntity;
	NSPredicate *predicate = [NSPredicate predicateWithFormat:@"(show like[c] %@)", theShow.show];
	request.predicate = predicate;
//	NSUInteger		count = [context countForFetchRequest:request error:&error];
//	if(0 != count)
//		return;

	NSString	*serverName = [[NSUserDefaults standardUserDefaults] stringForKey:@"TVServerName"];
	if([serverName isEqualToString:@"TheTVDB"])
	{
		NSXMLDocument	*mirrorsDocument = [[NSFileManager defaultManager] xmlDocumentForShow:@"mirrors" URL:@"http://www.thetvdb.com/api/5670633F68C717F7/mirrors.xml" cacheFolder:@"init"];
		NSXMLElement	*root = mirrorsDocument.rootElement;
		NSArray				*array = [root nodesForXPath:@"..//Mirrors/*" error:&error];
		if(array.count == 0)
			return;
		NSString			*mirrorpath_xml = nil;
		NSString			*mirrorpath_banners = nil;
		NSString			*mirrorpath_zip = nil;
		// we should pick a random mirror, but for now we pick the last one (right now there is only one anyway)
		for(NSXMLElement *showXML in array)
		{
			NSInteger		typemask = [[[showXML elementsForName:@"typemask"][0] objectValue] integerValue];
			NSString		*mirrorpath = [[showXML elementsForName:@"mirrorpath"][0] stringValue];
			if(typemask & 1)
				mirrorpath_xml = mirrorpath;
			if(typemask & 2)
				mirrorpath_banners = mirrorpath;
			if(typemask & 4)
				mirrorpath_zip = mirrorpath;
		}
//		NSLog(@"mirrorpath_xml: %@", mirrorpath_xml);
//		NSLog(@"mirrorpath_banners: %@", mirrorpath_banners);
//		NSLog(@"mirrorpath_zip: %@", mirrorpath_zip);

		NSString	*showCacheDirectory = [[[NSFileManager defaultManager] cachedFilePath:episodesFolder] stringByAppendingPathComponent:theShow.show];
		BOOL			isDirectory;
		if(!([[NSFileManager defaultManager] fileExistsAtPath:showCacheDirectory isDirectory:&isDirectory] && isDirectory))
		{
			NSString	*showCachePath = [showCacheDirectory stringByAppendingPathExtension:@"zip"];
			NSData		*theDocument = [[NSFileManager defaultManager] documentForShow:theShow.show extension:@"zip" URL:[NSString stringWithFormat:@"%@/api/5670633F68C717F7/series/%@/all/%@.zip",mirrorpath_zip,[theShow.showID stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding],selectedLanguage] cacheFolder:episodesFolder];
			if(theDocument)
			{
				ZipArchive *za = [[ZipArchive alloc] init];
				if ([za UnzipOpenFile:showCachePath]) {
						[za UnzipFileTo:showCacheDirectory overWrite:YES];
						[za UnzipCloseFile];
				}
			}
		}
		// initialize XML Document
		NSError		*error;
		NSURL			*url = [[NSURL alloc] initFileURLWithPath:[showCacheDirectory stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.xml",selectedLanguage]] isDirectory:NO];
		NSXMLDocument	*xmlDocument = [[NSXMLDocument alloc] initWithContentsOfURL:url options:0 error:&error];
		if(!xmlDocument)
		{
			NSLog(@"NSXMLDocument initWithData:%@ == %@", theShow, error);
			return;
		}
		root = xmlDocument.rootElement;
		NSString	*showName = nil;
		for(NSXMLElement *episode in [root nodesForXPath:@"..//Data/*" error:&error])
		{
			NSArray		*seriesTag = [episode elementsForName:@"SeriesName"];
			if(seriesTag.count > 0)
			{
				NSString	*seriesName = [[episode elementsForName:@"SeriesName"][0] stringValue];
				if(seriesName) showName = seriesName;
				continue;
			}
			if(!showName)
				continue;
			MMMEpisodeCache	*ep = [[MMMEpisodeCache alloc] initWithEntity:showEntity insertIntoManagedObjectContext:context];
			ep.show = showName;
			ep.season = @([[[episode elementsForName:@"SeasonNumber"][0] stringValue] integerValue]);
			ep.seasonnum = @([[[episode elementsForName:@"EpisodeNumber"][0] stringValue] integerValue]);
			ep.title = [[[episode elementsForName:@"EpisodeName"][0] stringValue] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
		}

	} else if([serverName isEqualToString:@"TVMaze"]) {
        NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"http:api.tvmaze.com/shows/%@/episodes", theShow.showID]];
        NSError *error;
        NSData	*data = [NSURLConnection sendSynchronousRequest:[NSURLRequest requestWithURL:url] returningResponse:nil error:&error];
        if(error)
            NSLog(@"%@", error);
        NSArray *json = [NSJSONSerialization JSONObjectWithData:data options:(NSJSONReadingOptions)0 error:&error];
        if(error)
            NSLog(@"%@", error);
//        NSLog(@"%@", json);
        for(NSDictionary *showDict in json) {
            MMMEpisodeCache	*ep = [[MMMEpisodeCache alloc] initWithEntity:showEntity insertIntoManagedObjectContext:context];
            ep.show = theShow.show;
            ep.season = showDict[@"season"];
            ep.seasonnum = showDict[@"number"];
            ep.title = showDict[@"name"];
        }
	}
}

+ (NSString*)stringForShow:(NSString*)theShow season:(NSNumber*)theSeason episode:(NSNumber*)theEpisode
{
	NSManagedObjectContext	*context = [(Video_Name_Cleanup_AppDelegate*)[NSApp delegate] managedObjectContext];
	NSEntityDescription			*showEntity = [NSEntityDescription entityForName:@"EpisodeCache" inManagedObjectContext:context];

	NSFetchRequest *request = [[NSFetchRequest alloc] init];
	request.entity = showEntity;
	NSPredicate *predicate = [NSPredicate predicateWithFormat:@"(show like[c] %@) and (season == %@) and (seasonnum == %@)", theShow, theSeason, theEpisode];
	request.predicate = predicate;
	NSError			*error;
	NSArray			*episodes = [context executeFetchRequest:request error:&error];
	if(episodes.count != 0)
		return [episodes[0] valueForKey:@"title"];
	return nil;
}
@end
