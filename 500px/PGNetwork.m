//
//  PGANetworker.m
//  500px
//
//  Created by Polo Garcia on 10/11/15.
//  Copyright © 2015 Polo Garcia. All rights reserved.
//

#import "PGNetwork.h"
#import <500px-iOS-api/PXAPI.h>

#import "PGPhotoProvider.h"

@interface PGNetwork ()

@property(nonatomic, strong) NSURLSession *session;
@property (strong, nonatomic) PXAPIHelper *apiHelper;
@property (strong, nonatomic) NSString *currentLocation;

@end

NSString *kCustomConsumerKey = @"qL3lmvHCbRG3eR9eXABfw9313jhkHotfuWR1J9pA";
NSString *kCustomSecretKey = @"nPQ1LV1tXhdmnuUJ1CzrXFufI1BHUIOIMcFkMEry";

NSString *kDefaultConsumerKey = @"DC2To2BS0ic1ChKDK15d44M42YHf9gbUJgdFoF0m";
NSString *kDefaultSecretKey = @"i8WL4chWoZ4kw9fh3jzHK7XzTer1y5tUNvsTFNnB";

@implementation PGNetwork

-(void)setNewUserLocation:(NSString*)newLocation{
    self.currentLocation = newLocation;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        NSURLSessionConfiguration *config = [NSURLSessionConfiguration defaultSessionConfiguration];
        config.HTTPMaximumConnectionsPerHost = 10;
        self.session = [NSURLSession sessionWithConfiguration:config];
        
        self.apiHelper = [[PXAPIHelper alloc] initWithHost:nil
                                               consumerKey:kCustomConsumerKey
                                            consumerSecret:kCustomSecretKey];
    }
    return self;
}

#pragma mark - Network helper methods

-(void)fetchContentsOfURL:(NSURL *)url
                completion:(void (^)(NSData *data, NSError *error)) completionHandler {
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        
        NSURLSessionDataTask *dataTask =
        [[self session] dataTaskWithURL:url
                          completionHandler:
         
         ^(NSData *data, NSURLResponse *response, NSError *error) {

             if (completionHandler == nil) return;
             
             if (error) {
                 completionHandler(nil, error);
                 return;
             }
             completionHandler(data, nil);
         }];
        [dataTask resume];
    });
}

-(void)downloadFileAtURL:(NSURL *)url
               toLocation:(NSURL *)destinationURL
               completion:(void (^)(NSError *error)) completionHandler {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        
        NSURLSessionDownloadTask *fileDownloadTask =
        [[self session] downloadTaskWithRequest:[NSURLRequest requestWithURL:url]
                                  completionHandler:
         
         ^(NSURL *location, NSURLResponse *response, NSError *error) {
             
             if (completionHandler == nil) return;
             
             if (error) {
                 completionHandler(error);
                 return;
             }
             
             NSError *fileError = nil;
             [[NSFileManager defaultManager] removeItemAtURL:destinationURL error:NULL];
             [[NSFileManager defaultManager] moveItemAtURL:location toURL:destinationURL error:&fileError];
             completionHandler(fileError);
         }];
        [fileDownloadTask resume];
    });
}

#pragma mark - API Requests composition

-(NSURLRequest*)requestCity:(NSString*)cityName
                  numImages:(NSUInteger)numImages{
    
    return [self.apiHelper urlRequestForSearchTag:cityName page:0 resultsPerPage:numImages
                                photoSizes:PXPhotoModelSizeThumbnail|PXPhotoModelSizeExtraLarge
                                    except:PXPhotoModelCategoryNude];
}

-(NSURLRequest*)requestAmount:(NSUInteger)numImages
                  forCategory:(PXPhotoModelCategory)PXPhotoCategory{
    
    return [self.apiHelper urlRequestForPhotoFeature:PXAPIHelperPhotoFeaturePopular
                                      resultsPerPage:numImages
                                                page:0
                                          photoSizes:PXPhotoModelSizeThumbnail|PXPhotoModelSizeExtraLarge
                                           sortOrder:PXAPIHelperSortOrderRating
                                              except:PXPhotoModelCategoryNude
                                                only:PXPhotoCategory];
}

-(NSArray*)requestsForCategory:(NSString*)categoryName{
    if([categoryName isEqualToString:@"menu"]){
        
        return  @[[self requestAmount:1 forCategory:PXPhotoModelCategorySport],
                  [self requestAmount:1 forCategory:PXPhotoModelCategoryFilm],
                  [self requestAmount:1 forCategory:PXPhotoModelCategoryCityAndArchitecture],
                  [self requestAmount:1 forCategory:PXPhotoModelCategoryPeople],
                  [self requestAmount:1 forCategory:PXPhotoModelCategoryStillLife],
                  [self requestAmount:1 forCategory:PXPhotoModelCategoryUrbanExploration],
                  [self requestAmount:1 forCategory:PXPhotoModelCategoryTravel],
                  [self requestAmount:1 forCategory:PXPhotoModelCategoryUnderwater],
                  [self requestAmount:1 forCategory:PXPhotoModelCategoryFashion],
                  [self requestAmount:1 forCategory:PXPhotoModelCategoryBlackAndWhite],
                  ];
    }
    if ([categoryName isEqualToString:@"urban"]) {
        return @[[self requestAmount:50 forCategory:PXPhotoModelCategoryUrbanExploration]];
    }
    if ([categoryName isEqualToString:@"sport"]) {
        return @[[self requestAmount:50 forCategory:PXPhotoModelCategorySport]];
    }
    if ([categoryName isEqualToString:@"film"]) {
        return @[[self requestAmount:50 forCategory:PXPhotoModelCategoryFilm]];
    }
    if ([categoryName isEqualToString:@"cityArchitecture"]) {
        return @[[self requestAmount:50 forCategory:PXPhotoModelCategoryCityAndArchitecture]];
    }
    if ([categoryName isEqualToString:@"stillLife"]) {
        return @[[self requestAmount:50 forCategory:PXPhotoModelCategoryStillLife]];
    }
    if ([categoryName isEqualToString:@"travel"]) {
        return @[[self requestAmount:50 forCategory:PXPhotoModelCategoryTravel]];
    }
    if ([categoryName isEqualToString:@"people"]) {
        return @[[self requestAmount:50 forCategory:PXPhotoModelCategoryPeople]];
    }
    if ([categoryName isEqualToString:@"underwater"]) {
        return @[[self requestAmount:50 forCategory:PXPhotoModelCategoryUnderwater]];
    }
    if ([categoryName isEqualToString:@"fashion"]) {
        return @[[self requestAmount:50 forCategory:PXPhotoModelCategoryFashion]];
    }
    if ([categoryName isEqualToString:@"blackAndWhite"]) {
        return @[[self requestAmount:50 forCategory:PXPhotoModelCategoryBlackAndWhite]];
    }
    if ([categoryName isEqualToString:@"location"]) {
        return @[[self requestCity:self.currentLocation numImages:50]];
    }

    NSAssert(NO, @"You must request a valid category (%@) does not exist", categoryName);
    return nil;
}

@end