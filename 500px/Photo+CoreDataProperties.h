//
//  Photo+CoreDataProperties.h
//  500px
//
//  Created by Polo Garcia on 11/11/15.
//  Copyright © 2015 Polo Garcia. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

#import "Photo.h"

NS_ASSUME_NONNULL_BEGIN

@interface Photo (CoreDataProperties)

@property (nullable, nonatomic, retain) NSString *photoName;
@property (nullable, nonatomic, retain) NSNumber *identifier;
@property (nullable, nonatomic, retain) NSString *photographerName;
@property (nullable, nonatomic, retain) NSNumber *rating;
@property (nullable, nonatomic, retain) NSData *thumbnailData;
@property (nullable, nonatomic, retain) NSData *fullsizedData;
@property (nullable, nonatomic, retain) NSString *thumbnailURL;
@property (nullable, nonatomic, retain) NSString *fullsizedURL;
@property (nullable, nonatomic, retain) PhotoCategory *categoryType;

@end

NS_ASSUME_NONNULL_END
