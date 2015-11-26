//
//  GalleryControllerCollectionViewController.h
//  Take2FRP
//
//  Created by Polo Garcia on 09/11/15.
//  Copyright © 2015 Polo Garcia. All rights reserved.
//

#import <UIKit/UIKit.h>

@class PGPhotoProvider;

@interface PGGalleryCollectionViewController : UICollectionViewController<UICollectionViewDataSource, UICollectionViewDelegate>

/**
 Photo Provider for the ViewController
 */
@property (nonatomic, strong) PGPhotoProvider *photoProvider;

@end
