//
//  GalleryControllerCollectionViewController.h
//  Take2FRP
//
//  Created by Polo Garcia on 09/11/15.
//  Copyright © 2015 Polo Garcia. All rights reserved.
//

#import <UIKit/UIKit.h>

@class PGPhotoProvider;

@interface PGGalleryCollectionViewController : UICollectionViewController<UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout>

/**
 Designated initializer. Creates and returns a UICollection View Controller for a certain photo category
 
 @param photoProv PGPhotoProvider created by the menu
 @param categoryName string from Constants.h that identifies the category that is going to be displayed
 
 @warning it is illegal to use init to instanciate this class. GalleryControllerInitException will be thrown.
 @warning photoProv MUST be a valid PGPhotoProvider. Exception will be thrown.
 @warning categoryName MUST be a valid category name. GalleryControllerCategoryNotSpecifiedException will be thrown.
 */
-(instancetype)initWithPhotoProvider:(PGPhotoProvider*)photoProv forCategory:(NSString*)categoryName;

@end
