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

/**
 Object responsible for interacting with the persistent store
 */
@property (strong, nonatomic) PGPersistence *persistenceManager;

/**
 Object responsible for interacting with the network and the API
 */
@property (strong, nonatomic) PGNetwork *networkManager;

/**
 Location manager
 */
@property (nonatomic , strong) CLLocationManager *locationManager;

/**
 Dictionary that matches category titles with their tag in the persistent store
 */
@property (strong, nonatomic) NSMutableDictionary *kCategoryTagDict;


@end

@implementation PGPhotoProvider

#pragma mark - Creation Methods for PGPhotoProvider

-(instancetype)init{
    [NSException raise:@"PGPhotoProviderInitException"
                format:@"Use createPhotoProviderWithCompletionHandler:, not init"];
    
    return nil;
}

/**
 http://stackoverflow.com/questions/17633827/asynchronous-initialization-in-objective-c
 The return value of this call will be ignored, since the created object will be forwarded
 throught the specified completion handler. This is necessary due to the asynchronicity of the
 initialization process of this class.
 */

+(void)createPhotoProviderWithCompletionHandler:(void(^)(PGPhotoProvider *ph, NSError *error))completion{
    __unused PGPhotoProvider *photoP = [[PGPhotoProvider alloc] initWithCompletionHandler:completion];
}

/**
 Designated initializer
 */
-(instancetype)initWithCompletionHandler:(void(^)(PGPhotoProvider *ph, NSError *error))completion{
    
    if (!(self = [super init])) {
        return nil;
    }
    
    //CLLocationManager code MUST be execute on the Main Thread
    if ([CLLocationManager locationServicesEnabled]) {
        self.locationManager = [[CLLocationManager alloc] init];
        self.locationManager.delegate = self;
        self.locationManager.desiredAccuracy = kCLLocationAccuracyThreeKilometers;
        
        if ([self.locationManager respondsToSelector:@selector(requestAlwaysAuthorization)]) {
            [self.locationManager requestAlwaysAuthorization];
        }
        [self.locationManager startUpdatingLocation];
    }
    
    self.kCategoryTagDict = [[NSMutableDictionary alloc] init];
    
    [self.kCategoryTagDict setObject:@"Urban exploration" forKey:@"urban"];
    [self.kCategoryTagDict setObject:@"Sport" forKey:@"sport"];
    [self.kCategoryTagDict setObject:@"Film" forKey:@"film"];
    [self.kCategoryTagDict setObject:@"City architecture" forKey:@"cityArchitecture"];
    [self.kCategoryTagDict setObject:@"Still life" forKey:@"stillLife"];
    [self.kCategoryTagDict setObject:@"Travel" forKey:@"travel"];
    [self.kCategoryTagDict setObject:@"People" forKey:@"people"];
    [self.kCategoryTagDict setObject:@"Under water" forKey:@"underwater"];
    [self.kCategoryTagDict setObject:@"Fashion" forKey:@"fashion"];
    [self.kCategoryTagDict setObject:@"B&W" forKey:@"blackAndWhite"];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(){
        self.useData = YES;
        self.persistenceManager = [[PGPersistence alloc] init];
        self.networkManager = [[PGNetwork alloc] init];

        completion(self,nil);
    });
    
    return self;
}

-(NSString*)categoryForTitle:(NSString*)title{
    return [[self.kCategoryTagDict allKeysForObject:title] firstObject];
}

-(NSString*)titleForCategory:(NSString*)name{
    return [self.kCategoryTagDict objectForKey:name];
}

#pragma mark - Request services

-(void)refreshCategory:(NSString*)categoryName
       withCompletion:(void (^)(NSArray *array, NSError *error))completionHandler{
    if(self.isWiFiAvailable || self.useData){
        [self downloadCategory:categoryName withCompletion:completionHandler];
    }
}

-(void)importCategory:(NSString*)categoryName
         withCompletion:(void (^)(NSArray *array, NSError *error))completionHandler{
    if([categoryName isEqualToString:@"myLocation"]){
        [self refreshCategory:categoryName withCompletion:completionHandler];
    }
    else{
        NSArray *persistedResults = [self.persistenceManager loadObjectsForCategory:categoryName];
        if (persistedResults) {
            [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                completionHandler(persistedResults, nil);
            }];
        }
        else if(self.isWiFiAvailable || self.useData){
            [self downloadCategory:categoryName withCompletion:completionHandler];
        } else {
            [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                completionHandler(nil, nil);
            }];
        }
    }
}

-(void)getFullPhotoInPhotoModel:(PGPhotoModel*)photoModel
                     completion:(void(^)(UIImage *fullphoto, NSError *error))completionHandler{
    [self.networkManager fetchContentsOfURL:[NSURL URLWithString:photoModel.fullsizedURL]
                                 completion:^(NSData *data, NSError *error) {
                                     if (data) {
                                         UIImage *retrieved = [UIImage imageWithData:data];
                                         completionHandler(retrieved, nil);
                                     }
                                     else{
                                         completionHandler(nil, error);
                                     }
                                 }];
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
        NSURL *downloadURL = [NSURL URLWithString:photoModel.thumbnailURL];
        [self.networkManager fetchContentsOfURL:downloadURL
                              completion:^(NSData *data, NSError *error) {
                                  if (data) {
                                      [self.persistenceManager saveThumbnail:data forPhotoModel:photoModel];
                                      UIImage *retrieved = [UIImage imageWithData:data];
                                      
                                      completionHandler(retrieved, nil);
                                  }
                                  else{
                                      completionHandler(nil, error);
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
//    static BOOL hola = NO;
//    if (!hola) {
//        hola = YES;
//        [dictionary keysOfEntriesPassingTest:^BOOL(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
//            NSLog(@"%@:%@", key, obj);
//            return YES;
//        }];
//    }
    photoModel.photoName = dictionary[@"name"];
    photoModel.identifier = dictionary[@"id"];
    photoModel.photographerName = dictionary[@"user"][@"username"];
    photoModel.rating = dictionary[@"rating"];
    
    
    photoModel.thumbnailURL = [self urlForImageSize:3 inArray:dictionary[@"images"]];
    photoModel.fullsizedURL = [self urlForImageSize:5 inArray:dictionary[@"images"]];
    
    
    if(dictionary[@"longitude"]){
        photoModel.latitude = dictionary[@"longitude"];
    }
    
    if(dictionary[@"latitude"]){
        photoModel.latitude = dictionary[@"latitude"];
    }
}

-(NSString*)urlForImageSize:(NSInteger)size inArray:(NSArray*)array{
    for (id sizeDescription in array) {
        NSInteger foundSize = [sizeDescription[@"size"] integerValue];
        if (size == foundSize) {
            return sizeDescription[@"url"];
        }
    }
    return nil;
}

#pragma mark - CLLocationDelegate

/**
 We use the location manager to identify the city where the user currently is
 to achieve a more compelling UX. Once we get name of the city, it is included
 in the "categories" dictionary, and the service is deactivated.
 */
-(void)locationManager:(CLLocationManager *)manager
    didUpdateLocations:(NSArray *)locations{
    
    CLLocation *newLocation = [locations lastObject];
    
    CLGeocoder *geocoder = [[CLGeocoder alloc] init];
    [geocoder reverseGeocodeLocation:newLocation
                   completionHandler:^(NSArray *placemarks, NSError *error){
                       if (error) {
                           NSLog(@"%@", [error localizedDescription]);
                       }
                       else if(placemarks && placemarks.count > 0){
                           CLPlacemark *place = [placemarks lastObject];
                           NSString *locality = place.locality;
                           
                           NSDictionary *userInfo = @{@"newLocation":locality};
                           
                           [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                               //Set it on the two important places
                               [self.kCategoryTagDict setObject:place.locality forKey:@"myLocation"];
                               [self.networkManager setNewUserLocation:locality];
                               
                               [[NSNotificationCenter defaultCenter] postNotificationName:@"PGGeoLocalizerNewLocationNotification"
                                                                                   object:nil
                                                                                 userInfo:userInfo];
                           }];

                       }
                   }];
    [manager stopUpdatingLocation];
}

-(void)locationManager:(CLLocationManager *)manager
      didFailWithError:(NSError *)error{
    
    if(error){
        NSLog(@"%@", [error localizedDescription]);
        return;
    }
}

@end
