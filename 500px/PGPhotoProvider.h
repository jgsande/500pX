//
//  FRPPhotoImporter.h
//  FunctionalReactivePixels
//
//  Created by Polo Garcia on 25/09/15.
//  Copyright © 2015 Polo Garcia. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
@import CoreLocation;

@class PGPhotoModel;

@interface PGPhotoProvider : NSObject<CLLocationManagerDelegate>

/**
 Factory Method for instanciating the class and retrieving its returned object asynchronously.
 @warning The object that implements the completion handler is responsible for keeping a copy of the
 returned PGPhotoProvider
 */
+(void)createPhotoProviderWithCompletionHandler:(void(^)(PGPhotoProvider *ph, NSError *error))completion;
    
/**
 This method tries to retrieve PGPhotModel objects from the persistent store for the specified category name.
 If there are none, then it will make a service request to the network and download 50 of them.
 */
-(void)importCategory:(NSString*)categoryName
       withCompletion:(void (^)(NSArray *array, NSError *error))completionHandler;

/**
 This method directly requests a new set of images for the specified category and smartly substitutes
 the persisted ones with the new ones (that is, it checks which of the new results had already been
 downloaded, and leaves them untouched)
 */
-(void)refreshCategory:(NSString*)categoryName
        withCompletion:(void (^)(NSArray *array, NSError *error))completionHandler;

/**
 This method tries to find the UIImage associated with the specified PGPhotoModel in the persistent store.
 If there is no match, then it makes a request to the server and forwards the result both to the persistent store
 (in a background thread) and the completion handler.
 */
-(void)getThumbnailInPhotoModel:(PGPhotoModel*)photoModel
                     completion:(void(^)(UIImage *fullphoto, NSError *error))completionHandler;

/**
 This method makes a request to the server and forwards the result to the completion handler.
 */
-(void)getFullPhotoInPhotoModel:(PGPhotoModel*)photoMode
                     completion:(void(^)(UIImage *thumbnail, NSError *error))completionHandler;

/**
 Method that returns the persistence-name of a given title that appears on the category menu
 */
-(NSString*)categoryForTitle:(NSString*)title;

/**
 Method that returns the UI-title of a given category in the persistence store
 */
-(NSString*)titleForCategory:(NSString*)name;

/**
 To avoid using the phone's data plan, we detect whether or not the user is connected to the internet
 through WiFi. If not, we will prompt the user with an alert and he/ she will decide whether he/ she
 wants to download content anyway. This setting is asked for once during the life of the app and
 will be stored in this variable.
 */
@property(nonatomic, assign) BOOL useData;

/**
 This value may change over the life cycle of the app and will let photo provider know when the user is
 connecte to the internet through a WiFi connection.
 */
@property(nonatomic, assign) BOOL isWiFiAvailable;

@end
