//
//  NSFileManager_Extensions.m
//  Video Name Cleanup
//
//  Created by Markus Fritze on 7/21/10.
//  Copyright 2010 Sarnau.com. All rights reserved.
//

#import "NSFileManager_Extensions.h"
//403936D0-0BB5-40F5-8D54-F5F1FE128F81

@implementation NSFileManager (MMMExtension)

- (NSString *)pathForDirectory:(NSSearchPathDirectory)directoryType
{
	NSArray			*paths = NSSearchPathForDirectoriesInDomains(directoryType, NSUserDomainMask, YES);
	return (paths.count > 0) ? paths.firstObject : NSTemporaryDirectory();
}

- (NSString *)cachedFilePath:(NSString*)theSubFolder
{        
	NSString		*applicationCachesDirectory = [self pathForDirectory:NSCachesDirectory];
	NSString		*filePath = [[applicationCachesDirectory stringByAppendingPathComponent:[[NSBundle mainBundle] bundleIdentifier]] stringByAppendingPathComponent:theSubFolder];
	[self createDirectoryAtPath:filePath withIntermediateDirectories:YES attributes:nil error:nil];
	return filePath;
}

- (NSData*)documentForShow:(NSString*)theShow extension:(NSString*)theExtension URL:(NSString*)theURL cacheFolder:(NSString*)theCacheFolder
{
	NSError		*error;

	// load xml for the show from the cache, if possible
	NSString	*showCachePath = [[[[NSFileManager defaultManager] cachedFilePath:theCacheFolder] stringByAppendingPathComponent:theShow] stringByAppendingPathExtension:theExtension];
	NSData		*fileData = nil;
	if([[NSFileManager defaultManager] isReadableFileAtPath:showCachePath])
	{
		fileData = [NSData dataWithContentsOfFile:showCachePath options:0 error:&error];
		if(!fileData)
		{
			NSLog(@"%@ = %@", theShow, error);
		}
	}
	if(!fileData)
	{
		NSURL		*xmlURL = [NSURL URLWithString:theURL];
		if(!xmlURL)
		{
			NSLog(@"URLWithString:%@", theShow);
			return nil;
		}
		// load URL as NSData
		fileData = [[NSData alloc] initWithContentsOfURL:xmlURL options:0 error:&error];
		if(!fileData)
		{
			NSLog(@"NSData initWithContentsOfURL:%@ == %@", theShow, error);
			return nil;
		}
		// write into cache
		BOOL	result = [fileData writeToFile:showCachePath options:NSDataWritingAtomic error:&error];
		if(!result)
		{
			NSLog(@"NSData writeToFile:%@ = %@", showCachePath, error);
		}
	}
	return fileData;
}

- (NSXMLDocument*)xmlDocumentForShow:(NSString*)theShow URL:(NSString*)theURL cacheFolder:(NSString*)theCacheFolder
{
	NSData		*xmlData = [self documentForShow:theShow extension:@"xml" URL:theURL cacheFolder:theCacheFolder];
	if(!xmlData)
		return nil;

	// initialize XML Document
	NSError		*error;
	NSXMLDocument	*xmlDocument = [[NSXMLDocument alloc] initWithData:xmlData options:0 error:&error];
	if(!xmlDocument)
	{
		NSLog(@"NSXMLDocument initWithData:%@ == %@", theShow, error);
			return nil;
	}
//	NSLog(@"%@", xmlDocument);
	return xmlDocument;
}

@end
