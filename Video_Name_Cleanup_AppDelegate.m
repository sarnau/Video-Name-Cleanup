//
//  Video_Name_Cleanup_AppDelegate.m
//  Video Name Cleanup
//
//  Created by Markus Fritze on 7/13/10.
//  Copyright 2010 Sarnau.com. All rights reserved.
//

#import "Video_Name_Cleanup_AppDelegate.h"
#import "MMMShow.h"
#import "MMMEpisodeCache.h"
#import "NSFileManager_Extensions.h"

@implementation Video_Name_Cleanup_AppDelegate
{
    NSPersistentStoreCoordinator *_persistentStoreCoordinator;
    NSManagedObjectModel *_managedObjectModel;
    NSManagedObjectContext *_managedObjectContext;
    NSString *_token;
}

- (void)sendRequest:(id)sender
{
    /* Configure session, choose between:
       * defaultSessionConfiguration
       * ephemeralSessionConfiguration
       * backgroundSessionConfigurationWithIdentifier:
     And set session-wide properties, such as: HTTPAdditionalHeaders,
     HTTPCookieAcceptPolicy, requestCachePolicy or timeoutIntervalForRequest.
     */
    NSURLSessionConfiguration* sessionConfig = [NSURLSessionConfiguration defaultSessionConfiguration];
 
    /* Create session, and optionally set a NSURLSessionDelegate. */
    NSURLSession* session = [NSURLSession sessionWithConfiguration:sessionConfig delegate:nil delegateQueue:nil];

    /* Create the Request:
       Series (GET https://api.thetvdb.com/search/series)
     */

    NSURL* URL = [NSURL URLWithString:@"https://api.thetvdb.com/search/series"];
    NSDictionary* URLParams = @{
        @"name": @"terra",
    };
    URL = NSURLByAppendingQueryParameters(URL, URLParams);
    NSMutableURLRequest* request = [NSMutableURLRequest requestWithURL:URL];
    request.HTTPMethod = @"GET";

    // Headers
    [request addValue:[@"Bearer " stringByAppendingString:_token] forHTTPHeaderField:@"Authorization"];
    [request addValue:@"de,en" forHTTPHeaderField:@"Accept"];
    [request addValue:@"application/json; charset=utf-8" forHTTPHeaderField:@"Content-Type"];

    NSURLSessionDataTask* task = [session dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        if (error == nil) {
            // Success
            id json = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
            NSLog(@"URL Session Task Succeeded: HTTP %ld %@", ((NSHTTPURLResponse*)response).statusCode, json);
        }
        else {
            // Failure
            NSLog(@"URL Session Task Failed: %@", [error localizedDescription]);
        }
    }];
    [task resume];
    [session finishTasksAndInvalidate];
}

/*
 * Utils: Add this section before your class implementation
 */

/**
 This creates a new query parameters string from the given NSDictionary. For
 example, if the input is @{@"day":@"Tuesday", @"month":@"January"}, the output
 string will be @"day=Tuesday&month=January".
 @param queryParameters The input dictionary.
 @return The created parameters string.
*/
static NSString* NSStringFromQueryParameters(NSDictionary* queryParameters)
{
    NSMutableArray* parts = [NSMutableArray array];
    [queryParameters enumerateKeysAndObjectsUsingBlock:^(id key, id value, BOOL *stop) {
        NSString *part = [NSString stringWithFormat: @"%@=%@",
            [key stringByAddingPercentEscapesUsingEncoding: NSUTF8StringEncoding],
            [value stringByAddingPercentEscapesUsingEncoding: NSUTF8StringEncoding]
        ];
        [parts addObject:part];
    }];
    return [parts componentsJoinedByString: @"&"];
}

/**
 Creates a new URL by adding the given query parameters.
 @param URL The input URL.
 @param queryParameters The query parameter dictionary to add.
 @return A new NSURL.
*/
static NSURL* NSURLByAppendingQueryParameters(NSURL* URL, NSDictionary* queryParameters)
{
    NSString* URLString = [NSString stringWithFormat:@"%@?%@",
        [URL absoluteString],
        NSStringFromQueryParameters(queryParameters)
    ];
    return [NSURL URLWithString:URLString];
}

- (void)loginRequest:(id)sender
{
    /* Configure session, choose between:
       * defaultSessionConfiguration
       * ephemeralSessionConfiguration
       * backgroundSessionConfigurationWithIdentifier:
     And set session-wide properties, such as: HTTPAdditionalHeaders,
     HTTPCookieAcceptPolicy, requestCachePolicy or timeoutIntervalForRequest.
     */
    NSURLSessionConfiguration* sessionConfig = [NSURLSessionConfiguration defaultSessionConfiguration];
 
    /* Create session, and optionally set a NSURLSessionDelegate. */
    NSURLSession* session = [NSURLSession sessionWithConfiguration:sessionConfig delegate:nil delegateQueue:nil];

    /* Create the Request:
       Login (POST https://api.thetvdb.com/login)
     */

    NSURL* URL = [NSURL URLWithString:@"https://api.thetvdb.com/login"];
    NSMutableURLRequest* request = [NSMutableURLRequest requestWithURL:URL];
    request.HTTPMethod = @"POST";

    // Headers
    [request addValue:@"application/json; charset=utf-8" forHTTPHeaderField:@"Content-Type"];

    // JSON Body
    NSDictionary* bodyObject = @{
        @"userkey": @"OF6PPUDVB072N6LE",
        @"username": @"tvdbwlh",
        @"apikey": @"53XAPBFP7RFG9YVO"
    };
    request.HTTPBody = [NSJSONSerialization dataWithJSONObject:bodyObject options:kNilOptions error:NULL];

    NSURLSessionDataTask* task = [session dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        if (error == nil) {
            // Success
            id json = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
            _token = json[@"token"];
            NSLog(@"URL Session Task Succeeded: HTTP %ld %@", ((NSHTTPURLResponse*)response).statusCode, json);
            [self sendRequest:self];
        } else {
            // Failure
            NSLog(@"URL Session Task Failed: %@", [error localizedDescription]);
        }
    }];
    [task resume];
    [session finishTasksAndInvalidate];
}


/***
 *	
 ***/
- (void)awakeFromNib
{
	[_tableView registerForDraggedTypes:@[(NSString*)kUTTypeFileURL]];

	[_window makeFirstResponder:_tableView];

	NSString	*destinationFolder = [[NSUserDefaults standardUserDefaults] valueForKey:@"destinationFolder"];
	if(!destinationFolder)
	{
		[[NSUserDefaults standardUserDefaults] setObject:[[NSFileManager defaultManager] pathForDirectory:NSMoviesDirectory] forKey:@"destinationFolder"];
	}
 
//    [self loginRequest:self];
}

/**
    Creates, retains, and returns the managed object model for the application 
    by merging all of the models found in the application bundle.
 */
- (NSManagedObjectModel *)managedObjectModel
{
	if (_managedObjectModel) return _managedObjectModel;

	_managedObjectModel = [NSManagedObjectModel mergedModelFromBundles:nil];    
	return _managedObjectModel;
}

/**
    Returns the persistent store coordinator for the application.  This 
    implementation will create and return a coordinator, having added the 
    store for the application to it.  (The directory for the store is created, 
    if necessary.)
 */
- (NSPersistentStoreCoordinator *) persistentStoreCoordinator
{
	if (_persistentStoreCoordinator) return _persistentStoreCoordinator;

	NSManagedObjectModel *mom = self.managedObjectModel;
	if (!mom)
	{
		NSAssert(NO, @"Managed object model is nil");
		return nil;
	}

	NSFileManager *fileManager = [NSFileManager defaultManager];
	NSString *applicationSupportDirectory = [[fileManager pathForDirectory:NSApplicationSupportDirectory] stringByAppendingPathComponent:NSBundle.mainBundle.infoDictionary[@"CFBundleName"]];
	NSError *error = nil;
	if (![fileManager fileExistsAtPath:applicationSupportDirectory isDirectory:NULL] )
	{
		if (![fileManager createDirectoryAtPath:applicationSupportDirectory withIntermediateDirectories:NO attributes:nil error:&error])
		{
			NSAssert(NO, ([NSString stringWithFormat:@"Failed to create App Support directory %@ : %@", applicationSupportDirectory,error]));
			return nil;
		}
	}

	NSURL *url = [NSURL fileURLWithPath:[applicationSupportDirectory stringByAppendingPathComponent:@"storedata"]];
	_persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:mom];
	if (![_persistentStoreCoordinator addPersistentStoreWithType:NSXMLStoreType configuration:nil URL:url options:nil error:&error])
	{
		[[NSApplication sharedApplication] presentError:error];
		_persistentStoreCoordinator = nil;
		return nil;
	}    
	return _persistentStoreCoordinator;
}

/**
    Returns the managed object context for the application (which is already
    bound to the persistent store coordinator for the application.) 
 */
- (NSManagedObjectContext *) managedObjectContext
{
	if (_managedObjectContext) return _managedObjectContext;

	NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
	if (!coordinator)
	{
		NSDictionary *dict = @{NSLocalizedDescriptionKey: @"Failed to initialize the store",
																				NSLocalizedFailureReasonErrorKey: @"There was an error building up the data file."};
		NSError *error = [NSError errorWithDomain:@"sarnau.com" code:9999 userInfo:dict];
		[[NSApplication sharedApplication] presentError:error];
		return nil;
	}
	_managedObjectContext = [[NSManagedObjectContext alloc] init];
	[_managedObjectContext setPersistentStoreCoordinator:coordinator];
	return _managedObjectContext;
}

/**
    Returns the NSUndoManager for the application.  In this case, the manager
    returned is that of the managed object context for the application.
 */
- (NSUndoManager *)windowWillReturnUndoManager:(NSWindow *)window
{
	return [self.managedObjectContext undoManager];
}

/**
    Performs the save action for the application, which is to send the save:
    message to the application's managed object context.  Any encountered errors
    are presented to the user.
 */
- (IBAction) saveAction:(id)sender
{
	if (![self.managedObjectContext commitEditing]) {
		NSLog(@"%@ unable to commit editing before saving", [self class]);
	}

	NSError *error = nil;
	if (![self.managedObjectContext save:&error]) {
		[[NSApplication sharedApplication] presentError:error];
	}
}


/**
    Implementation of the applicationShouldTerminate: method, used here to
    handle the saving of changes in the application managed object context
    before the application terminates.
 */
- (NSApplicationTerminateReply)applicationShouldTerminate:(NSApplication *)sender
{
	if (!self.managedObjectContext) return NSTerminateNow;

	if (![self.managedObjectContext commitEditing]) {
		NSLog(@"%@ unable to commit editing to terminate", [self class]);
		return NSTerminateCancel;
	}

	if (![self.managedObjectContext hasChanges]) return NSTerminateNow;

	NSError *error = nil;
	if (![self.managedObjectContext save:&error])
	{
		// This error handling simply presents error information in a panel with an 
		// "Ok" button, which does not include any attempt at error recovery (meaning, 
		// attempting to fix the error.)  As a result, this implementation will 
		// present the information to the user and then follow up with a panel asking 
		// if the user wishes to "Quit Anyway", without saving the changes.

		// Typically, this process should be altered to include application-specific 
		// recovery steps.  
						
		BOOL result = [sender presentError:error];
		if (result) return NSTerminateCancel;

		NSAlert *alert = [NSAlert alertWithMessageText:NSLocalizedString(@"Could not save changes while quitting.  Quit anyway?", @"Quit without saves error question message")
															defaultButton:NSLocalizedString(@"Quit anyway", @"Quit anyway button title")
															alternateButton:NSLocalizedString(@"Cancel", @"Cancel button title")
															otherButton:nil
															informativeTextWithFormat:NSLocalizedString(@"Quitting now will lose any changes you have made since the last successful save", @"Quit without saves error question info")];
		if(NSAlertAlternateReturn == [alert runModal])
			return NSTerminateCancel;
	}
	return NSTerminateNow;
}


/***
 *  Find a regular expression with named capture groups
 ***/
- (NSDictionary *)findRegex:(NSString *)regexStr inStr:(NSString *)str
{
    // filter out the unsupported named capture groups and store them in an array
    NSMutableArray *namedCaptureGroups = [NSMutableArray array];
    {
        NSError     *error;
        NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"\\(\\?P\\<(.*?)\\>" options:0 error:&error];
        if(error)
        {
            NSLog(@"%@", error);
        }
        for(NSTextCheckingResult *result in [regex matchesInString:regexStr options:0 range:NSMakeRange(0, regexStr.length)])
        {
            for(NSUInteger idx = 1; idx < result.numberOfRanges; ++idx)
            {
                NSRange     match = [result rangeAtIndex:idx];
                [namedCaptureGroups addObject:[regexStr substringWithRange:match]];
            }
        }
        regexStr = [regex stringByReplacingMatchesInString:regexStr options:0 range:NSMakeRange(0, regexStr.length) withTemplate:@"("];
//        NSLog(@"%@", namedCaptureGroups);
    }

    NSMutableDictionary *regexResult = [NSMutableDictionary dictionary];
    {
        NSError     *error;
        NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:regexStr options:0 error:&error];
        if(error)
        {
            NSLog(@"%@", error);
        }
        for(NSTextCheckingResult *result in [regex matchesInString:str options:0 range:NSMakeRange(0, str.length)])
        {
            for(NSUInteger idx = 1; idx < result.numberOfRanges; ++idx)
            {
                NSRange     match = [result rangeAtIndex:idx];
                regexResult[namedCaptureGroups[idx - 1]] = [str substringWithRange:match];
            }
        }
    }
    return regexResult;
}

/***
 *	Add a movie file to the table
 ***/
- (void)addMovieFile:(NSString*)theFilePath
{
	NSManagedObjectContext	*context = self.managedObjectContext;
	NSEntityDescription *showEntity = [NSEntityDescription entityForName:@"Show" inManagedObjectContext:context];

	// don't add the same file twice
	NSFetchRequest *request = [[NSFetchRequest alloc] init];
	request.entity = showEntity;
	request.predicate = [NSPredicate predicateWithFormat:@"(filePath == %@)", [theFilePath stringByAbbreviatingWithTildeInPath]];
	NSError			*error;
	NSArray			*episodes = [context executeFetchRequest:request error:&error];
	if([episodes count] != 0)
		return;

	MMMShow				*show = [[MMMShow alloc] initWithEntity:showEntity insertIntoManagedObjectContext:context];
	show.filePath = [theFilePath stringByAbbreviatingWithTildeInPath];
	show.filename = [theFilePath lastPathComponent];
	NSString			*nameWithoutExtension = [show.filename stringByDeletingPathExtension];
	if([nameWithoutExtension hasSuffix:@" (HD)"])
	{
		show.suffix = @" (HD)";
		nameWithoutExtension = [nameWithoutExtension substringToIndex:nameWithoutExtension.length - show.suffix.length];
	}

	// check if the file comes from iTunes, if so, we apply an additional filter for foldernames
	NSString			*iTunesPathAndFile = nil;
	NSString			*iTunesPath = @"~/Music/iTunes/iTunes Media/TV Shows/";
	if([show.filePath rangeOfString:iTunesPath].length > 0)
		iTunesPathAndFile = [show.filePath substringFromIndex:iTunesPath.length];
	iTunesPath = @"~/Music/iTunes/iTunes Music/TV Shows/";
	if([show.filePath rangeOfString:iTunesPath].length > 0)
		iTunesPathAndFile = [show.filePath substringFromIndex:iTunesPath.length];

	NSDictionary	*matches = nil;
	if(iTunesPathAndFile)
	{
		iTunesPathAndFile = iTunesPathAndFile.stringByDeletingPathExtension;
		for(NSString *filter in [NSArray arrayWithContentsOfURL:[NSBundle.mainBundle URLForResource:@"Filters_iTunes" withExtension:@"plist"]])
		{
            matches = [self findRegex:filter inStr:iTunesPathAndFile];
			if(matches.count)
				break;
		}
	}
	if(!matches)
	{
		NSMutableCharacterSet	*filterCharacterSet = [NSMutableCharacterSet whitespaceAndNewlineCharacterSet];
		[filterCharacterSet formUnionWithCharacterSet:[NSCharacterSet illegalCharacterSet]];
		[filterCharacterSet formUnionWithCharacterSet:[NSCharacterSet symbolCharacterSet]];
		[filterCharacterSet formUnionWithCharacterSet:[NSCharacterSet characterSetWithCharactersInString:@"."]];
		NSMutableArray *words = [NSMutableArray array];
		for(NSString *comp in [nameWithoutExtension componentsSeparatedByCharactersInSet:filterCharacterSet])
		{
			if(comp.length > 0)
				[words addObject:comp];
		}
		nameWithoutExtension = [[words componentsJoinedByString:@" "] stringByTrimmingCharactersInSet:filterCharacterSet];
		for(NSString *filter in [NSArray arrayWithContentsOfURL:[NSBundle.mainBundle URLForResource:@"Filters" withExtension:@"plist"]])
		{
            matches = [self findRegex:filter inStr:nameWithoutExtension];
			if(matches.count)
				break;
		}
	}

	@try {
		show.show = matches[@"name"];
	}
	@catch (NSException * e) {
	}
	if(show.show.length == 0)
		show.show = nameWithoutExtension;
	NSMutableCharacterSet	*filterCharacterSet = [NSMutableCharacterSet whitespaceAndNewlineCharacterSet];
	[filterCharacterSet formUnionWithCharacterSet:[NSCharacterSet illegalCharacterSet]];
	[filterCharacterSet formUnionWithCharacterSet:[NSCharacterSet symbolCharacterSet]];
	show.show = [show.show stringByTrimmingCharactersInSet:filterCharacterSet];
	[MMMShowCache lookupShow:show.show];

	@try {
		show.title = matches[@"title"];
	}
	@catch (NSException * e) {
	}

	@try {
		show.season = @([matches[@"season"] integerValue]);
	}
	@catch (NSException * e) {
	}

	@try {
		show.episode = @([matches[@"episode"] integerValue]);
	}
	@catch (NSException * e) {
	}
}

/* Optional - Drag and Drop support
    This method is called after it has been determined that a drag should begin, but before the drag has been started.  To refuse the drag, return NO.  To start a drag, return YES and place the drag data onto the pasteboard (data, owner, etc...).  The drag image and other drag related information will be set up and provided by the table view once this call returns with YES.  'rowIndexes' contains the row indexes that will be participating in the drag.

   Compatability Note: This method replaces tableView:writeRows:toPasteboard:.  If present, this is used instead of the deprecated method.
*/
- (BOOL)tableView:(NSTableView *)tableView writeRowsWithIndexes:(NSIndexSet *)rowIndexes toPasteboard:(NSPasteboard *)pboard
{
	return NO;
}

/* This method is used by NSTableView to determine a valid drop target. Based on the mouse position, the table view will suggest a proposed drop 'row' and 'dropOperation'. This method must return a value that indicates which NSDragOperation the data source will perform. The data source may "re-target" a drop, if desired, by calling setDropRow:dropOperation: and returning something other than NSDragOperationNone. One may choose to re-target for various reasons (eg. for better visual feedback when inserting into a sorted position).
*/
- (NSDragOperation)tableView:(NSTableView *)theTableView validateDrop:(id <NSDraggingInfo>)info proposedRow:(NSInteger)row proposedDropOperation:(NSTableViewDropOperation)dropOperation
{
	if(_tableView.numberOfRows <= row)
		return NSDragOperationCopy;
	return NSDragOperationNone;
}

/* This method is called when the mouse is released over an outline view that previously decided to allow a drop via the validateDrop method.  The data source should incorporate the data from the dragging pasteboard at this time. 'row' and 'dropOperation' contain the values previously set in the validateDrop: method.
*/
- (BOOL)tableView:(NSTableView *)tableView acceptDrop:(id <NSDraggingInfo>)info row:(NSInteger)row dropOperation:(NSTableViewDropOperation)dropOperation
{
	// add all files and search all added folders for files
	NSMutableArray	*itemList = [NSMutableArray array];
	for(NSPasteboardItem *item in info.draggingPasteboard.pasteboardItems)
	{
		NSString	*fileURLString = [item stringForType:@"public.file-url"];
		if(!fileURLString)
			continue;

		NSString	*fileItemPath = [[NSURL URLWithString:fileURLString] path];
		BOOL			isDirectory = NO;
		if([[NSFileManager defaultManager] fileExistsAtPath:fileItemPath isDirectory:&isDirectory])
		{
			if(isDirectory)
			{
				NSError		*error;
				for(NSString *file in [[NSFileManager defaultManager] subpathsOfDirectoryAtPath:fileItemPath error:&error])
				{
					if([file hasPrefix:@"."])
						continue;
					if([[file lastPathComponent] hasPrefix:@"."])
						continue;
					NSString	*fullPath = [fileItemPath stringByAppendingPathComponent:file];
					if(![[NSFileManager defaultManager] fileExistsAtPath:fullPath isDirectory:&isDirectory] || isDirectory)
						continue;
					[itemList addObject:fullPath];
				}
			} else {
				[itemList addObject:fileItemPath];
			}
		}
	}

	// add all movie files
	BOOL		didAddMovie = NO;
	NSArray	*validExtensions = @[@"vob", @"mkv"];
	for(NSString *theFilePath in itemList)
	{
		// ignore all non-movie files
		NSError		*error;
		NSString	*uti = [[NSWorkspace sharedWorkspace] typeOfFile:theFilePath error:&error];
		if(![[NSWorkspace sharedWorkspace] type:uti conformsToType:@"public.movie"] && ![validExtensions containsObject:theFilePath.pathExtension])
			continue;
		[self addMovieFile:theFilePath];
		didAddMovie = YES;
	}

	// drag was accepted if at least one file was added
	return didAddMovie;
}

/***
 *	BINDING
 *
 *	Return a sort descriptor for respecting the order
 ***/
- (NSArray*)sortByOrderIndex
{
	return @[[NSSortDescriptor sortDescriptorWithKey:@"orderIndex" ascending:YES]];
}

/***
 *	Popup selected => copy the show name from the popup selection
 ***/
- (IBAction)showSelected:(id)sender
{
	NSString	*selectedShow = [[sender selectedItem] title];
	for(MMMShowCache *theShow in [_TVShowCacheController arrangedObjects])
	{
		if([theShow.name isEqualToString:selectedShow])
		{
			[MMMEpisodeCache lookupEpisodesforShow:theShow];
		}
	}
	for(MMMShow *theShow in _showController.selectedObjects)
	{
		theShow.show = selectedShow;
		theShow.title = [[MMMEpisodeCache stringForShow:theShow.show season:theShow.season episode:theShow.episode] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
	}
}

/***
 *	Filter the popup content via the selection in the table
 ***/
- (void)tableViewSelectionDidChange:(NSNotification *)notification
{
	NSInteger	row = _tableView.selectedRow;
	if(row < 0)
		return;

	MMMShow *theShow = _showController.arrangedObjects[row];
	if(theShow.show == nil)
		return;
	[MMMShowCache lookupShow:theShow.show];
	[_TVShowCacheController setFilterPredicate:[NSPredicate predicateWithFormat:@"(show like[c] %@)", theShow.show]];
}

/***
 *	Add movies via open panel
 ***/
- (IBAction)addMovies:(id)sender
{
	NSOpenPanel	*panel = [NSOpenPanel openPanel];
	panel.resolvesAliases = YES;
	panel.canChooseFiles = YES;
	panel.canChooseDirectories = YES;
	panel.allowsMultipleSelection = YES;
	panel.title = NSLocalizedString(@"Select Movie Files",@"");
	panel.prompt = NSLocalizedString(@"Add",@"");
	panel.allowedFileTypes = @[@"public.movie"];
	if(NSFileHandlingPanelCancelButton == [panel runModal])
		return;

	for(NSURL *url in panel.URLs)
		[self addMovieFile:url.path];
}

/***
 *	Add a destination folder for the processed movies
 ***/
- (IBAction)selectDestinationFolder:(id)sender
{
	NSOpenPanel	*panel = [NSOpenPanel openPanel];
	panel.resolvesAliases = YES;
	panel.canChooseFiles = NO;
	panel.canChooseDirectories = YES;
	panel.allowsMultipleSelection = NO;
	panel.title = NSLocalizedString(@"Select Root Folder",@"");
	panel.prompt = NSLocalizedString(@"Select",@"");
	if(NSFileHandlingPanelCancelButton == [panel runModal])
		return;

	[[NSUserDefaults standardUserDefaults] setObject:[panel.URLs[0] path] forKey:@"destinationFolder"];
}

/***
 *	Rename and move the files to the new destination and then remove them from the list
 ***/
- (IBAction)rename:(id)sender
{
	NSString	*destinationFolder = [[NSUserDefaults standardUserDefaults] objectForKey:@"destinationFolder"];
	if(!destinationFolder)
		return;
	NSMutableSet	*set = [NSMutableSet set];
	for(MMMShow *show in _showController.arrangedObjects)
	{
//		NSLog(@"%@ => %@", show.filePath, [basePath stringByAppendingFormat:@"/%@/Season %@/%@", show.show, show.season, show.newFilename]);
		if(show.show == nil)
			continue;
		NSError	*error;
		BOOL		result;
		NSString	*mainFolder = [destinationFolder stringByAppendingPathComponent:[show.newFullPath stringByDeletingLastPathComponent]];
		result = [[NSFileManager defaultManager] createDirectoryAtPath:mainFolder withIntermediateDirectories:YES attributes:nil error:&error];
		NSString	*fullShowPath = [show.filePath stringByExpandingTildeInPath];
		if(![fullShowPath isEqualToString:[mainFolder stringByAppendingPathComponent:show.newFilename]])
			result = [[NSFileManager defaultManager] moveItemAtPath:fullShowPath toPath:[mainFolder stringByAppendingPathComponent:show.newFilename] error:&error];
		if(!result)
			continue;

		[set addObject:show.filePath];
	}
	for(NSString *filePath in set)
	{
		NSFetchRequest *request = [[NSFetchRequest alloc] init];
		NSManagedObjectContext	*context = self.managedObjectContext;
		request.entity = [NSEntityDescription entityForName:@"Show" inManagedObjectContext:context];
		request.predicate = [NSPredicate predicateWithFormat:@"(filePath == %@)", filePath];
		NSError			*error;
		NSArray			*episodes = [context executeFetchRequest:request error:&error];
		if(episodes.count != 0)
		{
			[context deleteObject:episodes.firstObject];
		}
	}
}

@end
