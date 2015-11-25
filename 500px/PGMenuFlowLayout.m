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
    self.sectionInset = UIEdgeInsetsMake(5, 5, 5, 5);
    self.minimumInteritemSpacing = 5;
    self.minimumLineSpacing = 5;
    
    return self;
}

//- (NSArray *) layoutAttributesForElementsInRect:(CGRect)rect {
//    
//    NSMutableArray *answer = [[super layoutAttributesForElementsInRect:rect] mutableCopy];
//    UICollectionView * const cv = self.collectionView;
//    CGPoint const contentOffset = cv.contentOffset;
//    
//    NSMutableIndexSet *missingSections = [NSMutableIndexSet indexSet];
//    for (UICollectionViewLayoutAttributes *layoutAttributes in answer) {
//        if (layoutAttributes.representedElementCategory == UICollectionElementCategoryCell) {
//            [missingSections addIndex:layoutAttributes.indexPath.section];
//        }
//    }
//    for (UICollectionViewLayoutAttributes *layoutAttributes in answer) {
//        if ([layoutAttributes.representedElementKind isEqualToString:UICollectionElementKindSectionHeader]) {
//            [missingSections removeIndex:layoutAttributes.indexPath.section];
//        }
//    }
//    
//    [missingSections enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
//        
//        NSIndexPath *indexPath = [NSIndexPath indexPathForItem:0 inSection:idx];
//        
//        UICollectionViewLayoutAttributes *layoutAttributes = [self layoutAttributesForSupplementaryViewOfKind:UICollectionElementKindSectionHeader atIndexPath:indexPath];
//        
//        [answer addObject:layoutAttributes];
//        
//    }];
//    
//    for (UICollectionViewLayoutAttributes *layoutAttributes in answer) {
//        
//        if ([layoutAttributes.representedElementKind isEqualToString:UICollectionElementKindSectionHeader]) {
//            
//            NSInteger section = layoutAttributes.indexPath.section;
//            NSInteger numberOfItemsInSection = [cv numberOfItemsInSection:section];
//            
//            NSIndexPath *firstCellIndexPath = [NSIndexPath indexPathForItem:0 inSection:section];
//            NSIndexPath *lastCellIndexPath = [NSIndexPath indexPathForItem:MAX(0, (numberOfItemsInSection - 1)) inSection:section];
//            
//            UICollectionViewLayoutAttributes *firstCellAttrs = [self layoutAttributesForItemAtIndexPath:firstCellIndexPath];
//            UICollectionViewLayoutAttributes *lastCellAttrs = [self layoutAttributesForItemAtIndexPath:lastCellIndexPath];
//            
//            CGFloat headerHeight = CGRectGetHeight(layoutAttributes.frame);
//            CGPoint origin = layoutAttributes.frame.origin;
//            origin.y = MIN(
//                           MAX(
//                               contentOffset.y,
//                               (CGRectGetMinY(firstCellAttrs.frame) - headerHeight)
//                               ),
//                           (CGRectGetMaxY(lastCellAttrs.frame) - headerHeight)
//                           );
//            
//            layoutAttributes.zIndex = 1024;
//            layoutAttributes.frame = (CGRect){
//                .origin = origin,
//                .size = layoutAttributes.frame.size
//            };
//            
//        }
//        
//    }
//    
//    return answer;
//    
//}

@end
