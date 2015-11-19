//
//  GalleryControllerCollectionViewController.m
//  Take2FRP
//
//  Created by Polo Garcia on 09/11/15.
//  Copyright © 2015 Polo Garcia. All rights reserved.
//

#import "PGGalleryCollectionViewController.h"
#import "PGGalleryFlowLayout.h"
#import "PGPhotoModel.h"
#import "PGNormalCell.h"
#import "PGPhotoProvider.h"

#import "UIImage+ImageEffects.h"

@interface PGGalleryCollectionViewController ()

/**
 Array of PGPhotoModel objects
 */
@property (nonatomic, strong) PGPhotoProvider *photoProvider;

@property (nonatomic, strong) NSArray *photosArray;

@property (nonatomic, strong) NSOperationQueue *imageQueue;
/**
 Dictionary that relates one cell to its image request.
 */
@property (nonatomic, strong) NSMutableDictionary *cellOperation;

@property (nonatomic, strong) NSMutableDictionary *original;
@property (nonatomic, strong) NSMutableDictionary *blurred;

@property (nonatomic, strong) NSString *categoryName;

@end

static NSString * reuseIdentifier = @"NormalCell";

@implementation PGGalleryCollectionViewController

-(instancetype)init{
    [NSException raise:@"GalleryControllerInitException"
                 format:@"Use initWithPhotoProvider:forCategory:, not init"];
    
    return nil;
}

-(instancetype)initWithPhotoProvider:(PGPhotoProvider*)photoProv
                         forCategory:(NSString*)categoryName{
    
    PGGalleryFlowLayout *layout = [[PGGalleryFlowLayout alloc] init];

    self = [self initWithCollectionViewLayout:layout];
    if (!self) {
        return nil;
    }
    
    if (!photoProv) {
        [NSException raise:@"GalleryControllerPhotoProviderException"
                    format:@"The PGPhotoProvider object must not be nil"];
    }
    if (!categoryName) {
        [NSException raise:@"GalleryControllerCategoryNotSpecifiedException"
                    format:@"The PGPhotoProvider object must not be nil"];
    }
    
    self.imageQueue = [[NSOperationQueue alloc] init];
    [self.imageQueue setName:@"Gallery image download queue"];
    
    self.cellOperation = [NSMutableDictionary new];
    
    self.photoProvider = photoProv;
    
    self.original = [NSMutableDictionary new];
    self.blurred = [NSMutableDictionary new];
    
    [self loadGalleryforCategory:categoryName];
    
    
    UITapGestureRecognizer *doubleTapFolderGesture =
    [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(processDoubleTap:)];
    
    [doubleTapFolderGesture setNumberOfTapsRequired:2];
    [doubleTapFolderGesture setDelaysTouchesBegan:YES];
    [self.view addGestureRecognizer:doubleTapFolderGesture];
    
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = [self.photoProvider titleForCategory:self.categoryName];
    
    if (self.photoProvider.useData) {
        UIBarButtonItem *anotherButton = [[UIBarButtonItem alloc] initWithTitle:@"Refresh"
                                                                          style:UIBarButtonItemStylePlain
                                                                         target:self
                                                                         action:@selector(refreshGallery)];
        self.navigationItem.rightBarButtonItem = anotherButton;
    }

    [self.collectionView registerClass:[PGNormalCell class] forCellWithReuseIdentifier:reuseIdentifier];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

#pragma mark - Data retrieval methods

-(void) refreshGallery{
    [self.imageQueue addOperationWithBlock:^{
        [self.photoProvider refreshCategory:self.categoryName
                             withCompletion:^(NSArray *array, NSError *error) {
                                 if (array) {
                                     [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                                         self.photosArray = array;
                                         [self.original removeAllObjects];
                                         [self.blurred removeAllObjects];
                                         [self.collectionView reloadData];
                                     }];
                                 }
                                 else{
                                     //nothing
                                 }
                             }];
    }];
}

-(void) loadGalleryforCategory:(NSString*)categoryN{
    self.categoryName = categoryN;
    [self.imageQueue addOperationWithBlock:^{
        [self.photoProvider importCategory:self.categoryName
                            withCompletion:^(NSArray *array, NSError *error) {
                                if (array) {
                                    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                                        self.photosArray = array;
                                        [self.collectionView reloadData];
                                    }];
                                }
                                else{
                                    //PGTODO show "no content to show" screen
                                    NSLog(@"No data to show");
                                }
                            }];
    }];
}

#pragma mark - Tap recognition

- (void) processDoubleTap:(UITapGestureRecognizer *)sender
{
    if (sender.state == UIGestureRecognizerStateEnded)
    {
        CGPoint point = [sender locationInView:self.collectionView];
        NSIndexPath *indexPath = [self.collectionView indexPathForItemAtPoint:point];
        if (indexPath){
            PGNormalCell *cell = (PGNormalCell*)[self.collectionView cellForItemAtIndexPath:indexPath];
            if (![self.blurred objectForKey:indexPath]) {
                [self.original setObject:cell.imageView.image forKey:indexPath];
                
                UIImage *blur = [cell.imageView.image applyBlurWithRadius:10.0
                                                        tintColor:[UIColor clearColor]
                                            saturationDeltaFactor:1.0
                                                        maskImage:nil];
                
                [self.blurred setObject:blur forKey:indexPath];
                
                [UIView transitionWithView:cell.imageView
                                  duration:0.5
                                   options:UIViewAnimationOptionTransitionCrossDissolve
                                animations:^{
                                    cell.imageView.image = [self.blurred objectForKey:indexPath];
                                } completion:nil];
                
            }
            else{
                [UIView transitionWithView:cell.imageView
                                  duration:0.5
                                   options:UIViewAnimationOptionTransitionCrossDissolve
                                animations:^{
                                    cell.imageView.image = [self.original objectForKey:indexPath];
                                } completion:^(BOOL finished) {
                                    [self.original removeObjectForKey:indexPath];
                                    [self.blurred removeObjectForKey:indexPath];
                                }];
            }
        }
    }
}


#pragma mark - UICollectionViewDataSource

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1;
}


- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.photosArray.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView
                  cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    
    PGNormalCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:reuseIdentifier
                                                              forIndexPath:indexPath];
    
    NSBlockOperation *operation = [NSBlockOperation blockOperationWithBlock:^{
        [self.photoProvider getThumbnailInPhotoModel:self.photosArray[indexPath.row]
                            completion:^(UIImage *thumbnail, NSError *error) {
                                PGNormalCell *myCell = (PGNormalCell *)[self.collectionView cellForItemAtIndexPath:indexPath];
                                myCell.imageView.image = thumbnail;
                                myCell.backgroundColor = [UIColor blackColor];
                            }];
    }];
    
    [self.cellOperation setObject:operation forKey:[self.photosArray[indexPath.row] thumbnailURL]];
    [self.imageQueue addOperation:operation];

    return cell;
}

#pragma mark - UICollectionViewDelegate


-(void)collectionView:(UICollectionView *)collectionView
 didEndDisplayingCell:(UICollectionViewCell *)cell
   forItemAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *url = [self.photosArray[indexPath.row] thumbnailURL];
    
    NSOperation *operation = [self.cellOperation objectForKey:url];
    if (operation) {
        [operation cancel];
        [self.cellOperation removeObjectForKey:url];
    }
    PGNormalCell *realCell = (PGNormalCell*)cell;
    realCell.backgroundColor = [UIColor darkGrayColor];
    [self.original removeObjectForKey:indexPath];
    [self.blurred removeObjectForKey:indexPath];
}

@end
