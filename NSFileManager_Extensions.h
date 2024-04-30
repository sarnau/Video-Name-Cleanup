//
//  NSFileManager_Extensions.h
//  Video Name Cleanup
//
//  Created by Markus Fritze on 7/21/10.
//  Copyright 2010 Sarnau.com. All rights reserved.
//

@interface NSFileManager (MMMExtension)

- (NSString *)pathForDirectory:(NSSearchPathDirectory)directoryType;
- (NSString *)cachedFilePath:(NSString*)group;
- (NSData*)documentForShow:(NSString*)theShow extension:(NSString*)theExtension URL:(NSString*)theURL cacheFolder:(NSString*)theCacheFolder;
- (NSXMLDocument*)xmlDocumentForShow:(NSString*)theShow URL:(NSString*)theURL cacheFolder:(NSString*)theCacheFolder;

@end
