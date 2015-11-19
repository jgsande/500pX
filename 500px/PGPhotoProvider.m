//
//  FRPPhotoImporter.m
//  FunctionalReactivePixels
//
//  Created by Polo Garcia on 25/09/15.
//  Copyright © 2015 Polo Garcia. All rights reserved.
//

#import "PGPhotoProvider.h"
#import "PGPhotoModel.h"
#import "PGNetwork.h"
#import "PGPhotoModel.h"

#import "PGPersistence.h"

@interface PGPhotoProvider ()

@property (strong, nonatomic) PGPersistence *persistenceManager;
@property (strong, nonatomic) PGNetwork *networkManager;
@property (strong, nonatomic) NSDictionary *kCategoryTagDict;

@end

@implementation PGPhotoProvider

-(instancetype)init{
    
    if (!(self = [super init])) {
        return nil;
    }
    
    self.kCategoryTagDict = @{@"Urban exploration":@"urban",
                              @"Sport":@"sport",
                              @"Film":@"film",
                              @"City architecture":@"cityArchitecture",
                              @"Still life":@"stillLife",
                              @"Travel":@"travel",
                              @"People":@"people",
                              @"Under water":@"underwater",
                              @"Fashion":@"fashion",
                              @"B&W":@"blackAndWhite"};
    
    self.useData = NO;
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(){
        self.persistenceManager = [[PGPersistence alloc] init];
        self.networkManager = [[PGNetwork alloc] init];
        
        [[NSNotificationCenter defaultCenter] postNotificationName:@"PGPhotoProviderDidSucceedNotification"
                                                            object:self
                                                          userInfo:nil];
    });
    
    return self;
}

-(NSString*)categoryForName:(NSString*)name{
    return [self.kCategoryTagDict objectForKey:name];
}

-(NSString*)titleForCategory:(NSString*)name{
    return [[self.kCategoryTagDict allKeysForObject:name] firstObject];
//    NSString *title = nil;
//    [self.kCategoryTagDict keysOfEntriesPassingTest:^BOOL(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
//        NSString *string = [NSString stringWithFormat:@"%@", obj];
//        if ([string isEqualToString:name]) {
//            *stop = YES;
//            return YES;
//        }
//        return NO;
//    }];
//    return title;
}

#pragma mark - Request services

-(void)refreshCategory:(NSString*)categoryName
       withCompletion:(void (^)(NSArray *array, NSError *error))completionHandler{
    if(self.useData){
        [self downloadCategory:categoryName withCompletion:completionHandler];
    }
}

-(void)importCategory:(NSString*)categoryName
         withCompletion:(void (^)(NSArray *array, NSError *error))completionHandler{
    
    NSArray *persistedResults = [self.persistenceManager loadObjectsForCategory:categoryName];
    if (persistedResults) {
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            completionHandler(persistedResults, nil);
        }];
    }
    else if(self.useData){
        [self downloadCategory:categoryName withCompletion:completionHandler];
    } else {
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            completionHandler(nil, nil);
        }];
    }
}

-(void)getThumbnailInPhotoModel:(PGPhotoModel*)photoModel
                     completion:(void(^)(UIImage *thumbnail, NSError *error))completionHandler{
    //To be able to determine whether the thumbnail was persisted or not
    //we need this call to be sync! Since this is not the main thread, we're all set!
    NSData *savedThumbnail = [self.persistenceManager loadThumbnailForPhotoModel:photoModel];
    
    if (savedThumbnail) {
        UIImage *saved = [UIImage imageWithData:savedThumbnail];
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            completionHandler(saved, nil);
        }];
    }
    else{
        //substite this call with fetchFile and show progress
        [self.networkManager fetchContentsOfURL:[NSURL URLWithString:photoModel.thumbnailURL]
                              completion:^(NSData *data, NSError *error) {
                                  if (data) {
                                      [self.persistenceManager saveThumbnail:data forPhotoModel:photoModel];
                                      UIImage *retrieved = [UIImage imageWithData:data];
                                      [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                                          completionHandler(retrieved, nil);
                                      }];
                                  }
                                  else{
                                      [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                                          completionHandler(nil, error);
                                      }];
                                  }
                              }];
    }
}

#pragma mark - Request data translation

/*
 We are going to use this method:
 1. To download data when it is not found on the persistent store
 2. To REFRESH an already existing category.
 This is the reason why this method needs to be async.
 
 There might be various different network requests to be done, so we
 1. Iterate on the list to make async requests
 2. Wait for all requests to be done
 3. Return
    a. An NSArray of PGPhotoModel objects for the specified category
    or
    b. nil and an NSError spec
 */
-(void)downloadCategory:(NSString*)categoryName
         withCompletion:(void (^)(NSArray *array, NSError *error))completionHandler{
    
    NSArray *requestArray = [self.networkManager requestsForCategory:categoryName];
    
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
    dispatch_queue_t isolationQueue = dispatch_queue_create("request queue", DISPATCH_QUEUE_CONCURRENT);
    __block NSUInteger reqCount = requestArray.count;
    
    NSMutableArray *result = [NSMutableArray new];
    
    for (NSURLRequest *req in requestArray) {
        [self.networkManager fetchContentsOfURL:[req URL]
                                     completion:^(NSData *data, NSError *error) {
                                         if (data) {
                                             NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
                                             for (id photoDictionary in json[@"photos"]) {
                                                 PGPhotoModel *model = [PGPhotoModel new];
                                                 [self configurePhotoModel:model withDictionary:photoDictionary];
                                                 [result addObject:model];
                                             }
                                             
                                             dispatch_barrier_async(isolationQueue, ^(){
                                                 reqCount--;
                                                 if (reqCount == 0) {
                                                     [self.persistenceManager saveObjects:result forCategory:categoryName];
                                                     dispatch_semaphore_signal(semaphore);
                                                 }
                                             });
                                         }
                                         else{
                                             NSLog(@"Network error:%@", [error localizedDescription]);
                                             completionHandler(nil, error);
                                         }
                                     }];
    }

    dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
    
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        completionHandler(result, nil);
    }];
}

-(void)configurePhotoModel:(PGPhotoModel*)photoModel withDictionary:(NSDictionary*)dictionary{
    photoModel.photoName = dictionary[@"name"];
    photoModel.identifier = dictionary[@"id"];
    photoModel.photographerName = dictionary[@"user"][@"username"];
    photoModel.rating = dictionary[@"rating"];
    
    photoModel.thumbnailURL = [self urlForImageSize:3 inArray:dictionary[@"images"]];
    
    if (dictionary[@"comments_count"]) {
        photoModel.fullsizedURL = [self urlForImageSize:4 inArray:dictionary[@"images"]];
    }
}

-(NSString*)urlForImageSize:(NSInteger)size inArray:(NSArray*)array{
    if (size == [[array firstObject][@"size"] integerValue]) {
        return [array firstObject][@"url"];
    }
    return nil;
}

@end
