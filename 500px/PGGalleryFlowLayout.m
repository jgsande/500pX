//
//  GalleryFlowLayout.m
//  Take2FRP
//
//  Created by Polo Garcia on 09/11/15.
//  Copyright © 2015 Polo Garcia. All rights reserved.
//

#import "PGGalleryFlowLayout.h"

@implementation PGGalleryFlowLayout

-(instancetype)init{
    self = [super init];
    if (!self) {
        return nil;
    }
    
    CGRect rect = [[UIScreen mainScreen] bounds];
    CGFloat sideLength = (rect.size.width);
    self.itemSize = CGSizeMake(sideLength, sideLength);
    self.minimumInteritemSpacing = 10;
    self.minimumLineSpacing = 10;
    self.sectionInset = UIEdgeInsetsMake(5, 0, 5, 0);
    
    return self;
}

@end
