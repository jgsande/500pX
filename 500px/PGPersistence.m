//
//  Persistence.m
//  YTCoreData
//
//  Created by Polo Garcia on 16/10/15.
//  Copyright © 2015 PoloGarcia. All rights reserved.
//

#import "PGPersistence.h"

#import "Photo.h"
#import "PhotoCategory.h"
#import "PGPhotoModel.h"

@interface PGPersistence ()

@property (nonatomic, strong) NSManagedObjectContext *managedObjectContext;
@property (nonatomic, strong) NSManagedObjectModel *managedObjectModel;
@property (nonatomic, strong) NSPersistentStoreCoordinator *persistentStoreCoordinator;

@property (nonatomic, strong) NSManagedObjectContext *privateMOC;

@end

@implementation PGPersistence

#pragma mark - Core Data Stack initialization

-(instancetype)init{
    if((self = [super self])){
        //Init managedObjectModel
        NSURL *modelURL = [[NSBundle mainBundle] URLForResource:@"500pxModel" withExtension:@"momd"];
        self.managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
        
        //create persistent coordinator, associating it to the previously defined object model
        NSError *error = nil;
        NSURL *storeURL = [[self applicationDocumentsDirectory] URLByAppendingPathComponent:@"MySQLiteDB.sqlite"];

        self.persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:self.managedObjectModel];
        if (![self.persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType
                                                           configuration:nil
                                                                     URL:storeURL
                                                                 options:nil
                                                                   error:&error]) {
            NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
            
            
            [[NSNotificationCenter defaultCenter] postNotificationName:@"PGPhotoProviderDidFailNotification"
                                                                object:self
                                                              userInfo:nil];
        }
        //Finally, init our managed object context
        dispatch_sync(dispatch_get_main_queue(), ^(){
            self.managedObjectContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
            [self.managedObjectContext setPersistentStoreCoordinator:self.persistentStoreCoordinator];
        });
        self.privateMOC = [self createPrivateManagedObjectContext];
        
        [[NSNotificationCenter defaultCenter]
         addObserverForName:NSManagedObjectContextDidSaveNotification
         object:nil
         queue:nil
         usingBlock:^(NSNotification* note)
         {
             NSManagedObjectContext *moc = self.managedObjectContext;
             if (note.object != moc)
             {
                 [moc performBlockAndWait:^(){
                     [moc mergeChangesFromContextDidSaveNotification:note];
                     NSError *error = nil;
                     [moc save:&error];
                     if (error) {
                         NSLog(@"Error merging %@", error.localizedDescription);
                     }
                 }];
             }
         }];
    }
    return self;
}

#pragma mark - Persistence Class Services

-(NSArray*)loadObjectsForCategory:(NSString*)categoryName{
    __block NSMutableArray *resultsArray = nil;

    [self.privateMOC performBlockAndWait:^{
        PhotoCategory *category = [self retrieveCategory:categoryName withManagedObjectContext:self.privateMOC];
        if (category) {
            resultsArray = [NSMutableArray new];
            for (Photo *photo in [category photos]) {
                PGPhotoModel *p = [[PGPhotoModel alloc] init];
                [p setPhotoName:[photo photoName]];
                [p setPhotographerName:[photo photographerName]];
                [p setIdentifier:[photo identifier]];
                [p setRating:[photo rating]];
                [p setThumbnailURL:[photo thumbnailURL]];
                [p setFullsizedURL:[photo fullsizedURL]];
                [resultsArray addObject:p];
            }
        }
    }];
    
    return resultsArray;
}

-(void)saveObjects:(NSArray*)photoModelArray forCategory:(NSString*)categoryName{
    [self.privateMOC performBlockAndWait:^{
        
        NSMutableDictionary *identifierModelDict = [NSMutableDictionary new];
        for (PGPhotoModel *photoModel in photoModelArray) {
            [identifierModelDict setObject:photoModel forKey:[photoModel identifier]];
        }
        
        PhotoCategory *category = [self retrieveCategory:categoryName withManagedObjectContext:self.privateMOC];
        
        //If this particular category had already been persisted, then we must:
        //  1. Delete from the NEW list all the elements that already exist in our persistent store
        //  2. Delete from the PERSISTED list all the elements that are not included in the new batch
        if (category) {
            for (NSManagedObject *object in [category photos]) {
                if ([identifierModelDict objectForKey:[object valueForKey:@"identifier"]]) {
                    [identifierModelDict removeObjectForKey:[object valueForKey:@"identifier"]];
                }
                else{
                    [self.privateMOC deleteObject:object];
                }
            }
            [self saveContext:self.privateMOC];
        }
        else{
            NSEntityDescription *categoryEntityDescription = [NSEntityDescription entityForName:@"PhotoCategory"
                                                                         inManagedObjectContext:self.privateMOC];
            category = [[PhotoCategory alloc] initWithEntity:categoryEntityDescription
                              insertIntoManagedObjectContext:self.privateMOC];
            [category setValue:categoryName forKey:@"name"];
        }
        
        NSMutableArray *resultsArray = [NSMutableArray new];
        
        NSEntityDescription *photoEntityDescription = [NSEntityDescription entityForName:@"Photo"
                                                                  inManagedObjectContext:self.privateMOC];
        
        [identifierModelDict enumerateKeysAndObjectsUsingBlock: ^(id key, PGPhotoModel *photoModel, BOOL *stop) {
            Photo *p = [[Photo alloc] initWithEntity:photoEntityDescription
                      insertIntoManagedObjectContext:self.privateMOC];
            [p setValue:[photoModel photoName] forKey:@"photoName"];
            [p setValue:[photoModel identifier] forKey:@"identifier"];
            [p setValue:[photoModel rating] forKey:@"rating"];
            [p setValue:[photoModel thumbnailURL] forKey:@"thumbnailURL"];
            [p setValue:[photoModel fullsizedURL] forKey:@"fullsizedURL"];
            [p setValue:category forKey:@"categoryType"];
            [resultsArray addObject:p];
        }];
        
        [category addPhotos:[NSSet setWithArray:resultsArray]];
        [self saveContext:self.privateMOC];
    }];
}

-(NSData*)loadThumbnailForPhotoModel:(PGPhotoModel*)photoModel{
    __block Photo *photo = nil;
    [self.privateMOC performBlockAndWait:^{
        photo = [self retrievePhoto:[photoModel identifier]
                  withManagedObjectContext:self.privateMOC];
    }];
    if (photo) {
        return [photo valueForKey:@"thumbnailData"];
    }
    return nil;
}

-(void)saveThumbnail:(NSData*)thumbnailData forPhotoModel:(PGPhotoModel*)photoModel{
    [self.privateMOC performBlock:^{
        Photo *photo = [self retrievePhoto:[photoModel identifier] withManagedObjectContext:self.privateMOC];
        if (!photo) {
            return;
        }
        
        [photo setValue:thumbnailData forKey:@"thumbnailData"];
        
        [self saveContext:self.privateMOC];
    }];
}

#pragma mark - Persistence Class Helper Methods

-(Photo*)retrievePhoto:(NSNumber*)photoIdentifier withManagedObjectContext:(NSManagedObjectContext*)moc{
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"Photo"];

    // Specify criteria for filtering which objects to fetch
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"identifier = %d", [photoIdentifier integerValue]];
    [fetchRequest setPredicate:predicate];
    // Specify how the fetched objects should be sorted
    
    NSError *error = nil;
    NSArray *fetchedObjects = [moc executeFetchRequest:fetchRequest error:&error];
    if (fetchedObjects == nil) {
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        NSAssert(NO, @"CoreData should be accessible without error");
    }
    if (fetchedObjects.count == 0) {
        return nil;
    }
    return [fetchedObjects firstObject];
}

-(PhotoCategory*)retrieveCategory:(NSString*)categoryName withManagedObjectContext:(NSManagedObjectContext*)moc{
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"PhotoCategory"];
    
    [fetchRequest setFetchBatchSize:16];

    // Specify criteria for filtering which objects to fetch
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"name LIKE[c] %@", categoryName];
    [fetchRequest setPredicate:predicate];
    // Specify how the fetched objects should be sorted
    NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"name" ascending:YES];
    [fetchRequest setSortDescriptors:@[sortDescriptor]];
    
    NSError *error = nil;
    NSArray *fetchedObjects = [moc executeFetchRequest:fetchRequest error:&error];
    if (fetchedObjects == nil) {
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        NSAssert(NO, @"CoreData should be accessible without error");
    }
    if (fetchedObjects.count == 0) {
        return nil;
    }
    return [fetchedObjects firstObject];
}

-(void)removeCategory:(NSString *)categoryName{
    [self.privateMOC performBlockAndWait:^{
        PhotoCategory *category = [self retrieveCategory:categoryName withManagedObjectContext:self.privateMOC];
        if (category) {
            for (NSManagedObject *object in [category photos]) {
                [self.privateMOC deleteObject:object];
            }
            [self.privateMOC deleteObject:category];
        }
        [self saveContext:self.privateMOC];
        [self.privateMOC reset];
    }];
}

/*
 This method will return a PRIVATE-QUEUE'd Managed Object Context (NSPrivateQueueConcurrencyType)
 which means that it must be used through performBlock or performBlockAndWait
 For more info, check:
 https://blog.codecentric.de/en/2014/11/concurrency-coredata/
 
 */
-(NSManagedObjectContext *)createPrivateManagedObjectContext {
    NSManagedObjectContext *manObCont = [[NSManagedObjectContext alloc]
                                         initWithConcurrencyType:NSPrivateQueueConcurrencyType];
    [manObCont setParentContext:self.managedObjectContext];
    return manObCont;
}


- (BOOL)saveContext:(NSManagedObjectContext *)context {
    NSError *error;
    if ([context hasChanges] && ![context save:&error]) {
        NSLog(@"[%@::%@] Couldn't save managed object context due to errors. Rolling back. Error: %@\n\n",
              NSStringFromClass([self class]),
              NSStringFromSelector(_cmd), error);
        NSAssert(NO, @"saveContext should not fail");
        [context rollback];
        return NO;
    }
    return YES;
}

-(NSURL*)applicationDocumentsDirectory{
    return [[[NSFileManager defaultManager]
             URLsForDirectory:NSDocumentDirectory
             inDomains:NSUserDomainMask] lastObject];
}

@end
