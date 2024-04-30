//
//  MMMShowCache.m
//  Video Name Cleanup
//
//  Created by Markus Fritze on 7/13/10.
//  Copyright 2010 Sarnau.com. All rights reserved.
//

#import "MMMShowCache.h"
#import "NSFileManager_Extensions.h"
#import "Video_Name_Cleanup_AppDelegate.h"

@implementation MMMShowCache

@dynamic show,source,orderIndex,name,showID;

/***
 *
 ***/
+ (void)lookupShow:(NSString*)theShowName
{
	// Check if we already have the show in the database, if so: do nothing!
	NSError		*error;
	NSManagedObjectContext	*context = [(Video_Name_Cleanup_AppDelegate*)[NSApp delegate] managedObjectContext];
	NSEntityDescription			*showEntity = [NSEntityDescription entityForName:@"ShowCache" inManagedObjectContext:context];

	NSFetchRequest *request = [[NSFetchRequest alloc] init];
	[request setEntity:showEntity];
	NSPredicate *predicate = [NSPredicate predicateWithFormat:@"(show like[c] %@)", theShowName];
	[request setPredicate:predicate];
	NSUInteger		count = [context countForFetchRequest:request error:&error];
	if(0 != count)
		return;

	NSString	*serverName = [[NSUserDefaults standardUserDefaults] stringForKey:@"TVServerName"];
	if([serverName isEqualToString:@"TheTVDB"])
	{
		/*NSXMLDocument	*languagesDocument =*/ [[NSFileManager defaultManager] xmlDocumentForShow:@"languages" URL:@"http://www.thetvdb.com/api/5670633F68C717F7/languages.xml" cacheFolder:@"init"];
		NSXMLDocument	*mirrorsDocument = [[NSFileManager defaultManager] xmlDocumentForShow:@"mirrors" URL:@"http://www.thetvdb.com/api/5670633F68C717F7/mirrors.xml" cacheFolder:@"init"];
		NSXMLElement	*root = [mirrorsDocument rootElement];
		NSArray				*array = [root nodesForXPath:@"..//Mirrors/*" error:&error];
		if([array count] == 0)
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
		[[NSFileManager defaultManager] xmlDocumentForShow:@"lastTime" URL:@"http://www.thetvdb.com/api/Updates.php?type=none" cacheFolder:@"init"];
		{
			NSXMLDocument	*xmlDocument = [[NSFileManager defaultManager] xmlDocumentForShow:theShowName URL:[NSString stringWithFormat:@"http://www.thetvdb.com/api/GetSeries.php?seriesname=%@", [theShowName stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]] cacheFolder:@"show"];
			NSXMLElement	*root = [xmlDocument rootElement];
			NSArray				*array = [root nodesForXPath:@"..//Data/*" error:&error];
			if(error)
			{
				NSLog(@"NodesForXPath:%@", error);
				return;
			}

			NSInteger			orderIndex = 0;
			for(NSXMLElement *showXML in array)
			{
				MMMShowCache	*theShow = [[MMMShowCache alloc] initWithEntity:showEntity insertIntoManagedObjectContext:context];
				theShow.source = @(MMMShowSourceTheTVDB);
				theShow.show = theShowName;
				theShow.orderIndex = @(orderIndex++);
				theShow.name = [[showXML elementsForName:@"SeriesName"][0] stringValue];
				theShow.showID = [[showXML elementsForName:@"seriesid"][0] stringValue];
			}
		}
	} else if([serverName isEqualToString:@"TVMaze"]) {
        NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"http://api.tvmaze.com/search/shows?q=%@", [theShowName stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]]];
        NSError *error;
        NSData	*data = [NSURLConnection sendSynchronousRequest:[NSURLRequest requestWithURL:url] returningResponse:nil error:&error];
        if(error)
            NSLog(@"%@", error);
        NSArray *json = [NSJSONSerialization JSONObjectWithData:data options:(NSJSONReadingOptions)0 error:&error];
        if(error)
            NSLog(@"%@", error);
//         NSLog(@"%@", json);
        NSInteger   orderIndex = 0;
        for(NSDictionary *showDict in json) {
            MMMShowCache	*theShow = [[MMMShowCache alloc] initWithEntity:showEntity insertIntoManagedObjectContext:context];
            theShow.source = @(MMMShowSourceTVMaze);
            theShow.show = theShowName;
            theShow.orderIndex = @(orderIndex++);
            theShow.name = showDict[@"show"][@"name"];
            theShow.showID = [NSString stringWithFormat:@"%@", showDict[@"show"][@"id"]];
        }
	}
}

@end
