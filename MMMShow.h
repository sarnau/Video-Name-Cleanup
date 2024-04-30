//
//  MMMShow.h
//  Video Name Cleanup
//
//  Created by Markus Fritze on 7/13/10.
//  Copyright 2010 Sarnau.com. All rights reserved.
//

@interface MMMShow : NSManagedObject

@property  NSString		*filePath;
@property  NSString		*filename;
@property  NSNumber		*episode;
@property  NSNumber		*season;
@property  NSString		*show;
@property  NSString		*title;
@property  NSString		*suffix;
@property (readonly) NSString	*newFilename;
@property (readonly) NSString	*newFullPath;

@end
