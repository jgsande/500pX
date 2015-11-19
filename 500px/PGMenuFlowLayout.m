//
//  PGMenuFlowLayout.m
//  500px
//
//  Created by Polo Garcia on 12/11/15.
//  Copyright © 2015 Polo Garcia. All rights reserved.
//

#import "PGMenuFlowLayout.h"

@implementation PGMenuFlowLayout

-(instancetype)init{
    self = [super init];
    if (!self) {
        return nil;
    }
    
    CGRect rect = [[UIScreen mainScreen] bounds];
    CGFloat sideLength = (rect.size.width/2)-10;
    self.itemSize = CGSizeMake(sideLength, sideLength);
    self.minimumInteritemSpacing = 5;
    self.minimumLineSpacing = 5;
    self.sectionInset = UIEdgeInsetsMake(5, 5, 5, 5);
    
    return self;
}


@end
