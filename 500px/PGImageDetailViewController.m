//
//  PGImageMapViewController.m
//  500px
//
//  Created by Polo Garcia on 20/11/15.
//  Copyright © 2015 Polo Garcia. All rights reserved.
//

#import "PGImageDetailViewController.h"
#import "PGPhotoModel.h"
#import "PGPhotoProvider.h"

@interface PGImageDetailViewController ()

@property (strong, nonatomic) UIImageView *detailImageView;

@property (strong, nonatomic) UIScrollView *scrollView;

@property (nonatomic, strong) PGPhotoModel *photoModel;

@property (nonatomic, strong) PGPhotoProvider *photoProvider;

@end

@implementation PGImageDetailViewController


-(instancetype)init{
    [NSException raise:@"ImageDetailViewInitException"
                format:@"Use initWithPhotoModel:forPhoto:, not init"];
    
    return nil;
}

-(instancetype)initWithPhotoProvider:(PGPhotoProvider*)photoProv forPhoto:(PGPhotoModel*)photo{
    if (!(self = [super init])) {
        return nil;
    }
    if (!photo) {
        [NSException raise:@"ImageDetailViewNilPhotoException"
                    format:@"The PGPhotoModel object must not be nil"];
    }
    
    if (!photoProv) {
        [NSException raise:@"ImageDetailViewNilPhotoProviderException"
                    format:@"The PGPhotoProvider object must not be nil"];
    }
    self.photoModel = photo;
    
    self.photoProvider = photoProv;
    
    [self.photoProvider getFullPhotoInPhotoModel:
     self.photoModel completion:^(UIImage *fullphoto, NSError *error) {
         if (fullphoto) {
             [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                 [UIView transitionWithView:self.detailImageView
                                   duration:0.3
                                    options:UIViewAnimationOptionTransitionCrossDissolve
                                 animations:^{
                                     self.detailImageView.image = fullphoto;
                                     self.detailImageView.contentMode = UIViewContentModeScaleAspectFit;
                                 } completion:^(BOOL finished) {
                                 }];
             }];
         }
    }];
    
    return self;
}

-(UIView*)viewForZoomingInScrollView:(UIScrollView *)scrollView{
    return self.detailImageView;
}

-(BOOL)prefersStatusBarHidden{
    return YES;
}

-(void)loadView{
    [super loadView];
    
    [self prefersStatusBarHidden];
    
    //imageView config
    self.detailImageView = [[UIImageView alloc] initWithFrame:self.view.bounds];
    self.detailImageView.image = self.photoModel.thumbnailImage;
    self.detailImageView.contentMode = UIViewContentModeScaleAspectFit;
    [self.detailImageView setUserInteractionEnabled:YES];
    
    //scrollView config
    self.scrollView = [[UIScrollView alloc] initWithFrame:self.view.bounds];
    [self.scrollView setDelegate:self];
    [self.scrollView setUserInteractionEnabled:YES];
    [self.scrollView setShowsVerticalScrollIndicator:NO];
    [self.scrollView setShowsHorizontalScrollIndicator:NO];
    [self.scrollView setScrollEnabled:YES];
    [self.scrollView setClipsToBounds:YES];
    [self.scrollView setBackgroundColor:[UIColor blackColor]];
    [self.scrollView setMaximumZoomScale:2.0];
    [self.scrollView setMinimumZoomScale:1.0];
    self.scrollView.contentSize = CGSizeMake(self.detailImageView.frame.size.width, self.detailImageView.frame.size.width);
    
    //Double tap recognizer
    UITapGestureRecognizer *doubleTap =
    [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(processDoubleTap:)];
    [doubleTap setNumberOfTapsRequired:2];
    [doubleTap setDelaysTouchesBegan:YES];
    [doubleTap setDelegate:self];
    [self.scrollView addGestureRecognizer:doubleTap];
    
    //Tap recognizer config
    UITapGestureRecognizer *tapGesture =
    [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(processTap:)];
    [tapGesture setNumberOfTapsRequired:1];
    [tapGesture setDelaysTouchesBegan:YES];
    [tapGesture setDelegate:self];
    [self.scrollView addGestureRecognizer:tapGesture];
    
    [tapGesture requireGestureRecognizerToFail:doubleTap];
    
    
    //Add the image to the scrollView
    [self.scrollView addSubview:self.detailImageView];
    //Add the scrollView to the view
    [self.view addSubview:self.scrollView];
    
    //Put the image at the center of the screen
    //[self.detailImageView setCenter:self.scrollView.center];
}


-(CGRect)zoomRectForScale:(float)scale withCenter:(CGPoint)center{
    
    CGRect zoomRect;
    
    zoomRect.size.height = [self.detailImageView frame].size.height / scale;
    zoomRect.size.width  = [self.detailImageView frame].size.width  / scale;
    
    center = [self.detailImageView convertPoint:center fromView:self.view];
    
    zoomRect.origin.x = center.x - ((zoomRect.size.width / 2.0));
    zoomRect.origin.y = center.y - ((zoomRect.size.height / 2.0));
    
    return zoomRect;
}

- (void)processDoubleTap:(UITapGestureRecognizer *)recognizer {
    
    float newScale = self.scrollView.zoomScale * 3.0;
    
    if (self.scrollView.zoomScale > self.scrollView.minimumZoomScale){
        [self.scrollView setZoomScale:self.scrollView.minimumZoomScale animated:YES];
    }
    else{
        CGRect zoomRect = [self zoomRectForScale:newScale
                                      withCenter:[recognizer locationInView:recognizer.view]];
        [self.scrollView zoomToRect:zoomRect animated:YES];
    }
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch{
    return YES;
}

-(void)processTap:(UITapGestureRecognizer *)sender
{
    if (sender.state == UIGestureRecognizerStateEnded)
    {
        [self dismissViewControllerAnimated:YES completion:^{
            //nothing
        }];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
