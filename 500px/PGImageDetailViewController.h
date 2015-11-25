//
//  PGImageMapViewController.h
//  500px
//
//  Created by Polo Garcia on 20/11/15.
//  Copyright © 2015 Polo Garcia. All rights reserved.
//

#import <UIKit/UIKit.h>
@class PGPhotoModel;
@class PGPhotoProvider;

@interface PGImageDetailViewController : UIViewController<UIScrollViewDelegate, UIGestureRecognizerDelegate>

/**
 Designated initializer
 
 @param photo PGPhotoModel
 
 @warning photo MUST be a valid PGPhotoModel. ImageDetailViewNilPhotoException will be thrown.
 @warning photo MUST be a valid PGPhotoModel. ImageDetailViewNilPhotoException will be thrown.
 */
-(instancetype)initWithPhotoProvider:(PGPhotoProvider*)photoProv forPhoto:(PGPhotoModel*)photo;

@end
