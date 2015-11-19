//
//  PGNormalCell.m
//  500px
//
//  Created by Polo Garcia on 12/11/15.
//  Copyright © 2015 Polo Garcia. All rights reserved.
//

#import "PGNormalCell.h"

@implementation PGNormalCell

-(instancetype)initWithFrame:(CGRect)frame{
    if (!(self = [super initWithFrame:frame])) {
        return nil;
    }
    
    self.backgroundColor = [UIColor darkGrayColor];
    UIImageView *imageV = [[UIImageView alloc] initWithFrame:self.bounds];
    imageV.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    [self.contentView addSubview:imageV];
    self.imageView = imageV;
    
    return self;
}

@end
