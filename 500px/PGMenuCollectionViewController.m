//
//  MenuCollectionViewController.m
//  500px
//
//  Created by Polo Garcia on 13/11/15.
//  Copyright © 2015 Polo Garcia. All rights reserved.
//

#import "PGMenuCollectionViewController.h"
#import "PGMenuFlowLayout.h"
#import "PGMenuCell.h"

#import "PGPhotoProvider.h"

#import "PGGalleryCollectionViewController.h"

#import "Reachability.h"

@interface PGMenuCollectionViewController ()

@property (nonatomic, strong) NSDictionary *menuDictionary;
@property (nonatomic, strong) NSArray *titlesArray;

/**
 Private queue for deriving class-specific operations to a background thread
 */
@property (nonatomic, strong) NSOperationQueue *imageQueue;

/**
 Dictionary that relates one cell to its image request.
 
 Each cell will ASYCHRONOUSLY request its image. Once it is processed, it is possible
 the latest indexPath will NOT be the one that corresponds to the returned image. If you don't check it,
 the image will appear, be substituted afterwards and so on. This yields a laggy, flickering, result.
 To avoid this, we need a way to keep track of what image request is related to what cell.
 
 @see (Safari) https://developer.apple.com/videos/play/wwdc2012-211/ (minute 38)
 
 */
@property (nonatomic, strong) NSMutableDictionary *cellOperation;

/**
 Object that handles data business. We will mostly make ASYNCHRONOUS requests to it.
 
 @warning It must be initialized in the background, so we subscribe to the notification it will post
 when it is done initializing, and only then can we start making service requests to it.
 */
@property (nonatomic, strong) PGPhotoProvider *photoProvider;

/**
 Object that allows us to know what kind of internet connection (if any) the user has,
 so we can make a more responsible use of data exchange.
 */
@property (nonatomic, strong) Reachability *reach;

@end

@implementation PGMenuCollectionViewController

-(instancetype)init{
    PGMenuFlowLayout *layout = [[PGMenuFlowLayout alloc] init];
    self = [super initWithCollectionViewLayout:layout];
    if (!self) {
        return nil;
    }
    
    //we subscribe to the initialization success notification
    //of the PhotoProvider BEFORE it is allocated.
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(providerDidInitializeSuccessfully:)
                                                 name:@"PGPhotoProviderDidSucceedNotification"
                                               object:nil];
    
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(providerDidFail:)
                                                     name:@"PGPhotoProviderDidFailNotification"
                                                   object:nil];
    
    self.photoProvider = [[PGPhotoProvider alloc] init];
    
    self.imageQueue = [[NSOperationQueue alloc] init];
    [self.imageQueue setName:@"Menu Image download queue"];
    
    self.reach = [Reachability reachabilityForLocalWiFi];
    
    return self;
}

#pragma mark - View loading methods

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = @"Menu";
    
    self.titlesArray = [self.titlesArray sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)];
    
    [self.collectionView registerClass:[PGMenuCell class] forCellWithReuseIdentifier:@"MenuCell"];
}

-(void) loadMenu{
    self.menuDictionary = @{@"B&W":[UIImage imageNamed:@"black_white"],
                            @"Under water":[UIImage imageNamed:@"under_water"],
                            @"Sport":[UIImage imageNamed:@"sport"],
                            @"People":[UIImage imageNamed:@"people"],
                            @"Film":[UIImage imageNamed:@"film"],
                            @"Still life":[UIImage imageNamed:@"still_life"],
                            @"Fashion":[UIImage imageNamed:@"fashion"],
                            @"Travel":[UIImage imageNamed:@"travel"],
                            @"Urban exploration":[UIImage imageNamed:@"urban_exploration"],
                            @"City architecture":[UIImage imageNamed:@"city_architecture"],
                            };
    
    self.titlesArray = @[@"Under water",
                         @"B&W",
                         @"People",
                         @"Urban exploration",
                         @"Sport",
                         @"City architecture",
                         @"Film",
                         @"Still life",
                         @"Travel",
                         @"Fashion"];
    
    [self.collectionView reloadData];
}

#pragma mark - Data Provider Notification Handlers

-(void)providerDidInitializeSuccessfully:(NSNotification*)notification{
    
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:@"PGPhotoProviderDidSucceedNotification"
                                                  object:nil];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:@"PGPhotoProviderDidFailNotification"
                                                  object:nil];
    [self alertWithResponse:^(BOOL didAccept) {
        [[self photoProvider] setUseData:didAccept];
    }];
    
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        [self loadMenu];
    }];
}

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

#pragma mark <UICollectionViewDataSource>

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1;
}


- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.titlesArray.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView
                  cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    PGMenuCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"MenuCell"
                                                                   forIndexPath:indexPath];
    NSString *imageName = self.titlesArray[indexPath.row];
    
    cell.backgroundColor = [UIColor clearColor];
    cell.label.text = imageName;
    cell.imageView.image = [self.menuDictionary objectForKey:imageName];
    
    return cell;
}

#pragma mark <UICollectionViewDelegate>

-(void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *categoryName = [self.photoProvider categoryForName:[self titlesArray][indexPath.row]];
    PGGalleryCollectionViewController *newGallery =
    [[PGGalleryCollectionViewController alloc] initWithPhotoProvider:self.photoProvider forCategory:categoryName];
    
    [self.navigationController pushViewController:newGallery animated:YES];

}

#pragma mark - Host Reachability check

-(NetworkStatus)checkConnection
{
    NetworkStatus wifiStatus = [[Reachability reachabilityForLocalWiFi] currentReachabilityStatus];
    NetworkStatus internetStatus = [[Reachability reachabilityForInternetConnection] currentReachabilityStatus];
    
    if (wifiStatus == ReachableViaWiFi) {
        return ReachableViaWiFi;
    }
    else if (wifiStatus != ReachableViaWiFi && internetStatus == ReachableViaWWAN) {
        return ReachableViaWWAN;
    }
    else {
        return NotReachable;
    }
}

-(void)alertWithResponse:(void (^)(BOOL didAccept))response {
    NetworkStatus netStatus = [self checkConnection];
    switch (netStatus)
    {
        case NotReachable:
        {
            UIAlertController *alert = [UIAlertController
                                        alertControllerWithTitle:@"Network unavailable"
                                        message:@"You are not connected to any network, images cannot be downloaded."
                                        preferredStyle:UIAlertControllerStyleAlert];
            UIAlertAction *ok = [UIAlertAction actionWithTitle:@"Ok"
                                                         style:UIAlertActionStyleDefault
                                                       handler:^(UIAlertAction * _Nonnull action) {
                                                           //response(NO);
                                                       }];
            [alert addAction:ok];
            
            [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                [self presentViewController:alert animated:YES completion:nil];
            }];
            
            break;
        }
            
        case ReachableViaWWAN:
        {
            UIAlertController *alert = [UIAlertController
                                        alertControllerWithTitle:@"Cellular Data Detected"
                                        message:@"You are using Cellular data. Downloading large amount of data may effect your cellular internet package costs. To avoid such extra cost kindly use Wifi."
                                        preferredStyle:UIAlertControllerStyleAlert];
            UIAlertAction *ok = [UIAlertAction actionWithTitle:@"Download anyway"
                                                         style:UIAlertActionStyleDefault
                                                       handler:^(UIAlertAction * _Nonnull action) {
                                                           response(YES);
                                                       }];
            UIAlertAction *cancel = [UIAlertAction actionWithTitle:@"Cancel"
                                                             style:UIAlertActionStyleCancel
                                                           handler:^(UIAlertAction * _Nonnull action) {
                                                               response(NO);
                                                           }];
            [alert addAction:ok];
            [alert addAction:cancel];
            
            [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                [self presentViewController:alert animated:YES completion:nil];
            }];
            break;
        }
        case ReachableViaWiFi:
        {
            response(YES);
            break;
        }
    }
}

@end
