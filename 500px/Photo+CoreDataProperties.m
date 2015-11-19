//
//  Photo+CoreDataProperties.m
//  500px
//
//  Created by Polo Garcia on 11/11/15.
//  Copyright © 2015 Polo Garcia. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

#import "Photo+CoreDataProperties.h"

@implementation Photo (CoreDataProperties)

@dynamic photoName;
@dynamic identifier;
@dynamic photographerName;
@dynamic rating;
@dynamic thumbnailData;
@dynamic fullsizedData;
@dynamic thumbnailURL;
@dynamic fullsizedURL;
@dynamic categoryType;

@end
