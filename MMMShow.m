//
//  MMMShow.m
//  Video Name Cleanup
//
//  Created by Markus Fritze on 7/13/10.
//  Copyright 2010 Sarnau.com. All rights reserved.
//

#import "MMMShow.h"

@implementation MMMShow

@dynamic filePath,filename,episode,season,show,title,suffix,newFullPath,newFilename;

+ (NSSet *)keyPathsForValuesAffectingNewFilename
{
	return [NSSet setWithObjects:@"filename", @"show", @"season", @"episode", @"title", nil];
}

+ (NSSet *)keyPathsForValuesAffectingNewFullPath
{
	return [NSSet setWithObjects:@"newFilename", @"filename", @"show", @"season", @"episode", @"title", nil];
}

- (NSString*)description
{
	return self.filePath;
}

- (NSString*)newFilename
{
	NSString		*theFilename = [NSString stringWithFormat:@"%@ - S%@E%@", self.show, self.season, self.episode];
	if(self.title.length != 0)
	{
		if(![self.title isEqualToString:[NSString stringWithFormat:@"Series %@, Episode %@", self.season, self.episode]]
		 && ![self.title isEqualToString:[NSString stringWithFormat:@"Season %@, Episode %@", self.season, self.episode]]
		 && ![self.title isEqualToString:[NSString stringWithFormat:@"Episode %@", self.episode]]
		 )
			theFilename = [theFilename stringByAppendingFormat:@" - %@", self.title];
	}

	// append the extension, if any
	if(self.suffix.length != 0)
		theFilename = [theFilename stringByAppendingString:self.suffix];

	// append the extension, if any
	if(self.filename.pathExtension.length != 0)
		theFilename = [theFilename stringByAppendingFormat:@".%@", self.filename.pathExtension];

	// replace the path separator with ":", just as the Finder does
	theFilename = [theFilename stringByReplacingOccurrencesOfString:@"/" withString:@":"];

	return theFilename;
}

- (NSString*)newFullPath
{
	return [NSString stringWithFormat:@"/%@/Season %@/%@", self.show, self.season,self.newFilename];
}

@end
