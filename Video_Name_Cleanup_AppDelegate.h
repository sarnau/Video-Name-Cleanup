//
//  Video_Name_Cleanup_AppDelegate.h
//  Video Name Cleanup
//
//  Created by Markus Fritze on 7/13/10.
//  Copyright 2010 Sarnau.com. All rights reserved.
//

@interface Video_Name_Cleanup_AppDelegate : NSObject <NSTableViewDataSource, NSTableViewDelegate>

@property (nonatomic, strong) IBOutlet NSWindow *window;
@property (nonatomic, strong) IBOutlet NSTableView *tableView;
@property (nonatomic, strong) IBOutlet NSArrayController *showController;
@property (nonatomic, strong) IBOutlet NSArrayController *TVShowCacheController;

@property (nonatomic, strong, readonly) NSPersistentStoreCoordinator *persistentStoreCoordinator;
@property (nonatomic, strong, readonly) NSManagedObjectModel *managedObjectModel;
@property (nonatomic, strong, readonly) NSManagedObjectContext *managedObjectContext;

- (IBAction)saveAction:sender;
- (IBAction)addMovies:(id)sender;
- (IBAction)showSelected:(id)sender;
- (IBAction)rename:(id)sender;
- (IBAction)selectDestinationFolder:(id)sender;

@end
