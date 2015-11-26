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

#import "PGMenuCollectionViewController.h"

#import "UIImage+ImageEffects.h"
#import "Reachability.h"

#import "PGImageDetailViewController.h"


@interface PGGalleryCollectionViewController ()

/**
 Array of PGPhotoModel objects
 */
@property (nonatomic, strong) NSArray *photosArray;

/**
 Private queue for the ViewController. Heavy or I/O operations should
 be put in this queue, freeing up the main thread.
 */
@property (nonatomic, strong) NSOperationQueue *imageQueue;

/**
 Dictionary that relates one cell to its image request.
 */
@property (nonatomic, strong) NSMutableDictionary *cellOperation;

/**
 When the user double-taps on a cell, the orignal image is associated with its indexPath in originalDict
 */
@property (nonatomic, strong) NSMutableDictionary *originalDict;

/**
 When the user double-taps on a cell, the blurred image is associated with its indexPath in blurredDict
 */
@property (nonatomic, strong) NSMutableDictionary *blurredDict;

/**
 Variable that holds the name of the category that is being shown
 */
@property (nonatomic, strong) NSString *categoryName;

/**
 ViewController for the category selection popup
 */
@property (nonatomic, strong) UIViewController *menuController;

///**
// Holds the name of the category being shown at the moment
// */
//@property (nonatomic, strong) UIButton *categoriesButton;

@end

static NSString * reuseIdentifier = @"NormalCell";

@implementation PGGalleryCollectionViewController

-(instancetype)init{
    PGGalleryFlowLayout *layout = [[PGGalleryFlowLayout alloc] init];

    self = [self initWithCollectionViewLayout:layout];
    if (!self) {
        return nil;
    }
    self.collectionView.backgroundColor = [UIColor whiteColor];
    
    //Notification for Photo Provider initialization success
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(providerDidInitializeSuccessfully:)
                                                 name:@"PGPhotoProviderDidSucceedNotification"
                                               object:nil];
    
    //Notification for Photo Provider initialization failure
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(providerDidFail:)
                                                 name:@"PGPhotoProviderDidFailNotification"
                                               object:nil];
    
    //Notification for new category selection
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(newCategorySelected:)
                                                 name:@"PGMenuControllerDidSelectNewCategory"
                                               object:nil];
    
    //Notification for user location retrieval
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(newLocationFound:)
                                                 name:@"PGGeoLocalizerNewLocationNotification"
                                               object:nil];
    
    //Notification for internet access medium change
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(reachabilityDidChange:)
                                                 name:@"kReachabilityChangedNotification"
                                               object:nil];
    
    self.imageQueue = [[NSOperationQueue alloc] init];
    [self.imageQueue setName:@"Gallery image download queue"];
    
    self.cellOperation = [NSMutableDictionary new];
    
    self.originalDict = [NSMutableDictionary new];
    self.blurredDict = [NSMutableDictionary new];
    
    UITapGestureRecognizer *doubleTapGesture =
    [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(processDoubleTap:)];
    
    [doubleTapGesture setNumberOfTapsRequired:2];
    [doubleTapGesture setDelaysTouchesBegan:YES];
    [self.view addGestureRecognizer:doubleTapGesture];
    
    return self;
}

-(void)dealloc{
    [[NSNotificationCenter defaultCenter]removeObserver:self];
}


-(void)loadView{
    [super loadView];
    
//        UISearchBar *searchBar = [[UISearchBar alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width,44)];
//        searchBar.delegate = self;
//        searchBar.placeholder = @"Search for info";
//    searchBar.showsCancelButton = YES;
//    
//        [self.collectionView addSubview: searchBar];
//    
//    NSDictionary* viewDict = @{@"mySearchBar": searchBar, @"myCollView": self.collectionView};
//    
//    NSArray* sHorizontal = [NSLayoutConstraint constraintsWithVisualFormat:@"H:|[mySearchBar(==myCollView)]|"
//                                                                   options:0
//                                                                   metrics:nil
//                                                                     views:viewDict];
//    
//    
//    NSArray* sVertical = [NSLayoutConstraint constraintsWithVisualFormat:@"V:|[mySearchBar(==44)]"
//                                                                 options:0
//                                                                 metrics:nil
//                                                                   views:viewDict];
//    
//    [self.collectionView addConstraints:sHorizontal];
//    [self.collectionView addConstraints:sVertical];

    
    UIBarButtonItem *categoriesButton = [[UIBarButtonItem alloc] initWithTitle:@"Categories"
                                                                         style:UIBarButtonItemStylePlain
                                                                        target:self
                                                                        action:@selector(willSelectNewCategory:)];
    
    self.navigationItem.leftBarButtonItem = categoriesButton;
    
    UIBarButtonItem *refreshButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh
                                                                                   target:self
                                                                                   action:@selector(refreshGallery)];
    self.navigationItem.rightBarButtonItem = refreshButton;
    self.navigationItem.rightBarButtonItem.enabled = NO;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self.collectionView registerClass:[PGNormalCell class] forCellWithReuseIdentifier:reuseIdentifier];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    [self.originalDict removeAllObjects];
    [self.blurredDict removeAllObjects];
    self.menuController = nil;
}

#pragma mark - Category change Notification Handlers

-(void)willSelectNewCategory:(UIButton*)sender{
    if (!self.menuController) {
        self.menuController = [[UINavigationController alloc] initWithRootViewController:[[PGMenuCollectionViewController alloc] init]];
    }
    [self presentViewController:self.menuController animated:YES completion:^{
        //nothing
    }];
}



/**
 Method that will be triggered every time the user selects a new category from the Category Menu.
 
 We extract the payload of the notification and check if the new selected category is the same
 as the one that is currently showing.
 */
-(void)newCategorySelected:(NSNotification*)notification{
    NSDictionary *info = notification.userInfo;
    NSString *term = info[@"newCategory"];
    
    NSString *newCategory = [self.photoProvider categoryForTitle:term];
    
    if (!newCategory) {
        self.categoryName = term;
    }
    else{
        if ([newCategory isEqualToString:self.categoryName]) {
            return;
        }
        self.categoryName = newCategory;
    }
    
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        self.photosArray = nil;
        [self.collectionView reloadData];
        [self loadGallery];
    }];
}

/**
 Method that will be triggered when the user's location is found.
 We need to be notified only once, so we will unsubscribe the first time it arrives.
 */
-(void)newLocationFound:(NSNotification*)notification{
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:@"PGGeoLocalizerNewLocationNotification"
                                                  object:nil];
    
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        self.categoryName = @"myLocation";
        [self refreshGallery];
    }];
}

#pragma mark - Photo Provider Notification Handlers

/**
 Method that will be triggered when the app's PhotoProvider is correctly initialized.
 We then unsubscribe from:
    a. The success notification
    b. The failure notification
 */
-(void)providerDidInitializeSuccessfully:(NSNotification*)notification{
    
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:@"PGPhotoProviderDidSucceedNotification"
                                                  object:nil];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:@"PGPhotoProviderDidFailNotification"
                                                  object:nil];
    
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        self.categoryName = @"underwater";
        [self loadGallery];
    }];
}

/**
 Method that will be triggered if the app's PhotoProvider fails initializing.
 */
-(void)providerDidFail:(NSNotification*)notification{
    UIAlertController *alert = [UIAlertController
                                alertControllerWithTitle:@"Major failure"
                                message:@"The app could not launch properly."
                                preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *ok = [UIAlertAction actionWithTitle:@"Ok"
                                                 style:UIAlertActionStyleDefault
                                               handler:^(UIAlertAction * _Nonnull action) {
                                                   abort();
                                               }];
    [alert addAction:ok];
    
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        [self presentViewController:alert animated:YES completion:nil];
    }];
}

#pragma mark - Internet Access Medium change Notification Handlers

-(void)reachabilityDidChange:(NSNotification*)notification{
    static BOOL alreadySet = NO;
    Reachability *reachability = (Reachability *)[notification object];
    
    if ([reachability isReachableViaWWAN]) {
        if (!alreadySet) {
            __weak typeof(self) weakSelf = self;
            [self alertWithResponse:^(BOOL didAccept) {
                
                alreadySet = YES;
                
                weakSelf.photoProvider.useData = didAccept;
                
                [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                    weakSelf.navigationItem.rightBarButtonItem.enabled = weakSelf.photoProvider.useData;
                }];
                
            }];
        }
        else{
            [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                self.navigationItem.rightBarButtonItem.enabled = self.photoProvider.useData;
            }];
        }
    }
    
    if (![reachability isReachable]) {
        [self alertForNoSignal];
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            self.navigationItem.rightBarButtonItem.enabled = NO;
        }];
    }
    if ([reachability isReachableViaWiFi]) {
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            self.navigationItem.rightBarButtonItem.enabled = YES;
        }];
        self.photoProvider.isWiFiAvailable = YES;
    }
}

#pragma mark - Data retrieval methods

-(void) loadGallery{
    self.navigationItem.rightBarButtonItem.enabled = NO;
    
    [self.imageQueue addOperationWithBlock:^{
        [self.photoProvider importCategory:self.categoryName
                            withCompletion:^(NSArray *array, NSError *error) {
                                if (array) {
                                    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                                        self.photosArray = array;
                                        [self.originalDict removeAllObjects];
                                        [self.blurredDict removeAllObjects];
                                        [self.collectionView setContentOffset:CGPointMake(0, -64) animated:NO];
                                        [self.collectionView reloadData];
                                        NSString *title =[self.photoProvider titleForCategory:self.categoryName];
                                        if (!title) {
                                            title = self.categoryName;
                                        }
                                        [self.navigationItem setTitle:title];
                                        self.navigationItem.rightBarButtonItem.enabled = YES;
                                    }];
                                }
                                else{
                                    //PGTODO show "no content to show" screen
                                    NSLog(@"No data to show");
                                }
                            }];
    }];
}

-(void) refreshGallery{
    self.navigationItem.rightBarButtonItem.enabled = NO;
    
    [self.imageQueue addOperationWithBlock:^{
        [self.photoProvider refreshCategory:self.categoryName
                             withCompletion:^(NSArray *array, NSError *error) {
                                 if (array) {
                                     [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                                         self.photosArray = array;
                                         [self.originalDict removeAllObjects];
                                         [self.blurredDict removeAllObjects];
                                         [self.collectionView setContentOffset:CGPointMake(0, -64) animated:NO];
                                         [self.collectionView reloadData];
                                         NSString *title =[self.photoProvider titleForCategory:self.categoryName];
                                         if (!title) {
                                             title = self.categoryName;
                                         }
                                         [self.navigationItem setTitle:title];
                                         self.navigationItem.rightBarButtonItem.enabled = YES;
                                     }];
                                 }
                                 else{
                                     //nothing
                                 }
                             }];
    }];
}

#pragma mark - Tap recognition

/**
 When the user double-taps on a cell, the blurred version of its image is calculated (on a background thread)
 and set as the content of the UIImageView. When the user double-taps for a second time on the same cell,
 the original image is restored.
 */
-(void)processDoubleTap:(UITapGestureRecognizer *)sender
{
    if (sender.state == UIGestureRecognizerStateEnded)
    {
        //Check if the image that was double-tapped is still on the screen
        CGPoint point = [sender locationInView:self.collectionView];
        NSIndexPath *indexPath = [self.collectionView indexPathForItemAtPoint:point];
        if (indexPath){
            
            PGNormalCell *cell = (PGNormalCell*)[self.collectionView cellForItemAtIndexPath:indexPath];
            
            //Check if the image is already blurred
            if (![self.blurredDict objectForKey:indexPath]) {
                
                // To prevent retain cycles call back by weak reference
                __weak typeof(self) weakSelf = self;
                
                // Heavy work dispatched to a separate thread
                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                    [weakSelf.originalDict setObject:cell.imageView.image forKey:indexPath];
                    UIImage *ret = [cell.imageView.image applyBlurWithRadius:10.0
                                                                   tintColor:[UIColor clearColor]
                                                       saturationDeltaFactor:1.0
                                                                   maskImage:nil];
                    
                    // Create strong reference to the weakSelf inside the block
                    //so that it´s not released while the block is running
                    typeof(weakSelf) strongSelf = weakSelf;
                    if (strongSelf) {
                        
                        //Update the UI calling the main thread
                        dispatch_async(dispatch_get_main_queue(), ^{
                            [strongSelf.blurredDict setObject:ret forKey:indexPath];
                            
                            [UIView transitionWithView:cell.imageView
                                              duration:0.5
                                               options:UIViewAnimationOptionTransitionCrossDissolve
                                            animations:^{
                                                cell.imageView.image = [strongSelf.blurredDict objectForKey:indexPath];
                                            } completion:nil];
                        });
                    }
                });
            }
            else {
                [UIView transitionWithView:cell.imageView
                                  duration:0.5
                                   options:UIViewAnimationOptionTransitionCrossDissolve
                                animations:^{
                                    cell.imageView.image = [self.originalDict objectForKey:indexPath];
                                } completion:^(BOOL finished) {
                                    [self.blurredDict removeObjectForKey:indexPath];
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

/**
 Each cell will ASYCHRONOUSLY request its image. Once it is processed, it is possible
 the latest indexPath will NOT be the one that corresponds to the returned image. If you don't check it,
 the image will appear, be substituted afterwards and so on. This yields a laggy, flickering, result.
 To avoid this, we need a way to keep track of what image request is related to what cell.
 
 @see (Safari) https://developer.apple.com/videos/play/wwdc2012-211/ (minute 38)
 
 To avoid this effect, whenever a new image is requested, we derive the operation to the ViewController's private queue.
 That way, if the cell that added the operation to the queue is removed from screen, the request will be cancelled.
 */
- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView
                  cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    
    PGNormalCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:reuseIdentifier
                                                              forIndexPath:indexPath];
    
    UIImage *cellImage = [self.originalDict objectForKey:indexPath];
    if (cellImage) {
        cell.imageView.image = cellImage;
    }
    else{
        NSBlockOperation *operation = [NSBlockOperation blockOperationWithBlock:^{
            [self.photoProvider getThumbnailInPhotoModel:self.photosArray[indexPath.row]
                                              completion:^(UIImage *thumbnail, NSError *error) {
                                                  [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                                                      if (thumbnail) {
                                                          PGNormalCell *myCell = (PGNormalCell *)[self.collectionView cellForItemAtIndexPath:indexPath];
                                                          
                                                          [UIView transitionWithView:cell.imageView
                                                                            duration:0.3
                                                                             options:UIViewAnimationOptionTransitionCrossDissolve
                                                                          animations:^{
                                                                              [self.originalDict setObject:thumbnail forKey:indexPath];
                                                                              myCell.imageView.image = thumbnail;
                                                                          } completion:^(BOOL finished) {
                                                                              myCell.backgroundColor = [UIColor clearColor];
                                                                          }];
                                                      }
                                                  }];
                                                  
                                              }];
        }];
        
        [self.cellOperation setObject:operation forKey:[self.photosArray[indexPath.row] thumbnailURL]];
        [self.imageQueue addOperation:operation];
    }
    return cell;
}

#pragma mark - UICollectionViewDelegate

-(void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath{
    PGPhotoModel *photoModel = self.photosArray[indexPath.row];
    photoModel.thumbnailImage = [self.originalDict objectForKey:indexPath];
    
    PGImageDetailViewController *imageViewController =
    [[PGImageDetailViewController alloc] initWithPhotoProvider:self.photoProvider forPhoto:photoModel];
    
    [self.navigationController presentViewController:imageViewController animated:YES completion:^{
        //nothing
    }];
}

/**
 If a cell is not on display anymore, we eliminate its footprint.
 */
-(void)collectionView:(UICollectionView *)collectionView didEndDisplayingCell:(UICollectionViewCell *)cell forItemAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *url = [self.photosArray[indexPath.row] thumbnailURL];
    
    NSOperation *operation = [self.cellOperation objectForKey:url];
    if (operation) {
        [operation cancel];
        [self.cellOperation removeObjectForKey:url];
    }
    
    PGNormalCell *realCell = (PGNormalCell*)cell;
    realCell.imageView.image = nil;
    realCell.backgroundColor = [UIColor darkGrayColor];
    [self.blurredDict removeObjectForKey:indexPath];
}

#pragma mark - Alert views for signal

-(void)alertWithResponse:(void (^)(BOOL didAccept))response {
    UIAlertController *alert = [UIAlertController
                                alertControllerWithTitle:@"Cellular Data Detected"
                                message:@"You are using Cellular data. Downloading large amount of data may effect your cellular internet package costs. To avoid such extra cost kindly use Wifi."
                                preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *ok = [UIAlertAction actionWithTitle:@"Download anyway"
                                                 style:UIAlertActionStyleDefault
                                               handler:^(UIAlertAction * _Nonnull action) {
                                                   response(YES);
                                               }];
    UIAlertAction *cancel = [UIAlertAction actionWithTitle:@"Not with cell data!"
                                                     style:UIAlertActionStyleCancel
                                                   handler:^(UIAlertAction * _Nonnull action) {
                                                       response(NO);
                                                   }];
    [alert addAction:ok];
    [alert addAction:cancel];
    
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        [self presentViewController:alert animated:YES completion:nil];
    }];
}

-(void)alertForNoSignal{
    UIAlertController *alert = [UIAlertController
                                alertControllerWithTitle:@"Network unavailable"
                                message:@"You are not connected to any network, images cannot be downloaded."
                                preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *ok = [UIAlertAction actionWithTitle:@"Ok"
                                                 style:UIAlertActionStyleDefault
                                               handler:^(UIAlertAction * _Nonnull action) {
                                                   //nothing
                                               }];
    [alert addAction:ok];
    
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        [self presentViewController:alert animated:YES completion:nil];
    }];
}

@end
