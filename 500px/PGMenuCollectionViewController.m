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

@interface PGMenuCollectionViewController ()

@property (nonatomic, strong) NSDictionary *menuDictionary;
@property (nonatomic, strong) NSArray *titlesArray;

/**
 Object that handles data business. We will mostly make ASYNCHRONOUS requests to it.
 
 @warning It must be initialized in the background, so we subscribe to the notification it will post
 when it is done initializing, and only then can we start making service requests to it.
 */
//@property (nonatomic, strong) PGPhotoProvider *photoProvider;

/**
 Object that allows us to know what kind of internet connection (if any) the user has,
 so we can make a more responsible use of data exchange.
 */
//@property (nonatomic, strong) Reachability *reach;

@property (nonatomic, strong) UICollectionView *collectionView;

@property (nonatomic, strong) UISearchBar *searchBar;

@end

@implementation PGMenuCollectionViewController

- (instancetype)init
{
    if (self = [super init]) {
        //nothing
    }
    return self;
}

#pragma mark - View loading methods

-(void)loadView{
    [super loadView];
    
    UIBarButtonItem *doneButton = [[UIBarButtonItem alloc] initWithTitle:@"Done"
                                                                   style:UIBarButtonItemStyleDone
                                                                  target:self
                                                                  action:@selector(doneSelecting:)];
    
    self.navigationItem.rightBarButtonItem = doneButton;
    
//    self.searchBar = [[UISearchBar alloc] init];
//    self.searchBar.frame = CGRectMake(0, 50, self.view.frame.size.width,44);
//    self.searchBar.delegate = self;
//    self.searchBar.placeholder = @"Search for info";
//    
//    [self.view addSubview: self.searchBar];
    
    PGMenuFlowLayout *layout = [[PGMenuFlowLayout alloc] init];
    
    CGRect frame = CGRectMake(0.0, 0.0, self.view.frame.size.width, self.view.frame.size.height);
    self.collectionView = [[UICollectionView alloc] initWithFrame:frame collectionViewLayout:layout];
    [self.collectionView setDataSource:self];
    [self.collectionView setDelegate:self];
    [self.collectionView registerClass:[PGMenuCell class] forCellWithReuseIdentifier:@"MenuCell"];
    [self.collectionView registerClass:[UICollectionReusableView class]
            forSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:@"HeaderView"];

    [self.collectionView setBackgroundColor:[UIColor whiteColor]];
    [self.view addSubview:self.collectionView];
    
}

-(void)doneSelecting:(UIButton*)button{
    [self dismissViewControllerAnimated:YES completion:^{
        //
    }];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self loadMenu];
}

-(void) loadMenu{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
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
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.collectionView reloadData];
        });
    });    
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
    //post notification with payload
    NSDictionary* userInfo = @{@"newCategory":[self titlesArray][indexPath.row]};
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"PGMenuControllerDidSelectNewCategory"
                                                        object:self
                                                      userInfo:userInfo];
    
    [self dismissViewControllerAnimated:YES completion:^{
        //nothing
    }];
}

@end
