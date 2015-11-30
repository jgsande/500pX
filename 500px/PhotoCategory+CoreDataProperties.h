//
//  Category+CoreDataProperties.h
//  500px
//
//  Created by Polo Garcia on 11/11/15.
//  Copyright © 2015 Polo Garcia. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

#import "PhotoCategory.h"

NS_ASSUME_NONNULL_BEGIN

@interface PhotoCategory (CoreDataProperties)

@property (nullable, nonatomic, retain) NSString *name;
@property (nullable, nonatomic, retain) NSSet *photos;

@end

@interface PhotoCategory (CoreDataGeneratedAccessors)

- (void)addPhotosObject:(Photo *)value;
- (void)removePhotosObject:(Photo *)value;
- (void)addPhotos:(NSSet *)values;
- (void)removePhotos:(NSSet *)values;

@end

NS_ASSUME_NONNULL_END
