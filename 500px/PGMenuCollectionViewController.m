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

@property (nonatomic, strong) UIView *darkenView;

@end

@implementation PGMenuCollectionViewController


-(instancetype)init{
    if (self = [super init]) {
        //nothing
    }
    return self;
}

#pragma mark - View loading methods

-(void)loadView{
    [super loadView];
    
    self.searchBar = [[UISearchBar alloc] initWithFrame:CGRectMake(-5.0, 0.0, 250.0, 30.0)];
    self.searchBar.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    self.searchBar.delegate = self;
    
    self.navigationItem.titleView = self.searchBar;
    
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc]
                                   initWithTarget:self
                                   action:@selector(dismissKeyboard)];
    
    [self.view addGestureRecognizer:tap];
    
    UIBarButtonItem *doneButton = [[UIBarButtonItem alloc] initWithTitle:@"Done"
                                                                   style:UIBarButtonItemStyleDone
                                                                  target:self
                                                                  action:@selector(doneSelecting:)];
    
    self.navigationItem.rightBarButtonItem = doneButton;
    
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
    
    self.darkenView = [[UIView alloc] initWithFrame:self.collectionView.frame];
    self.darkenView.backgroundColor = [UIColor blackColor];
    self.darkenView.alpha = 0.75;
}

-(void)doneSelecting:(UIButton*)button{
    [self dismissKeyboard];
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

-(void)didSelectNewTerm:(NSString*)term{
    //post notification with payload
    NSDictionary* userInfo = @{@"newCategory":term};
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"PGMenuControllerDidSelectNewCategory"
                                                        object:self
                                                      userInfo:userInfo];
    
    [self dismissViewControllerAnimated:YES completion:^{
        //nothing
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
    //post notification with payload
    [self didSelectNewTerm:[self titlesArray][indexPath.row]];
    
    [self dismissViewControllerAnimated:YES completion:^{
        //nothing
    }];
}

#pragma mark <UISearchBarDelegate>

-(void)searchBarTextDidBeginEditing:(UISearchBar *)searchBar{
    [self.collectionView addSubview:self.darkenView];
}

-(void)searchBarCancelButtonClicked:(UISearchBar *)searchBar{
    [searchBar resignFirstResponder];
}

-(void)searchBarSearchButtonClicked:(UISearchBar *)searchBar{
    //post notification with payload
    NSString *str = [NSString stringWithFormat:@"%@", searchBar.text];
    [self didSelectNewTerm:str];
    [self dismissKeyboard];
    
    [self dismissViewControllerAnimated:YES completion:^{
        //nothing
    }];
}

- (void) dismissKeyboard{
    [self.darkenView removeFromSuperview];
    [self.searchBar resignFirstResponder];
    [self.searchBar resignFirstResponder];
    self.searchBar.showsCancelButton = NO;
    self.searchBar.text = nil;
}

@end
