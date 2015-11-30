//
//  AppDelegate.m
//  500px
//
//  Created by Polo Garcia on 10/11/15.
//  Copyright © 2015 Polo Garcia. All rights reserved.
//

#import "PGAppDelegate.h"

#import "PGGalleryCollectionViewController.h"
#import "PGUserViewController.h"

#import "PGPhotoProvider.h"

#import "PGReachabilityManager.h"

@interface PGAppDelegate ()

/**
 This manager object will live through the whole life-span of the app and
 will post notifications whenever there is a change in the internet access medium.
 */
@property (nonatomic, strong) PGReachabilityManager *reachManager;

/**
 
 */
@property (nonatomic, strong) PGPhotoProvider *photoProvider;

@end

@implementation PGAppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    self.window = [UIWindow new];
    [self.window makeKeyAndVisible];
    self.window.frame = [[UIScreen mainScreen] bounds];
    
    //Configuration for gallery view controller
    PGGalleryCollectionViewController *galleryViewController = [[PGGalleryCollectionViewController alloc] init];
    galleryViewController.tabBarItem = [[UITabBarItem alloc] initWithTitle:nil image:[UIImage imageNamed:@"gallery"] selectedImage:nil];
    
    //Configuration for user view controller
    PGUserViewController *userViewController = [[PGUserViewController alloc] init];
    userViewController.tabBarItem = [[UITabBarItem alloc] initWithTitle:nil image:[UIImage imageNamed:@"user"] selectedImage:nil];
    
    //Wrap both view controllers under a navigation controller, and then add them to a tab bar controller
    UINavigationController *navControllerFirst = [[UINavigationController alloc] initWithRootViewController:galleryViewController];
    UINavigationController *navControllerSecond = [[UINavigationController alloc] initWithRootViewController:userViewController];
    

    if([navControllerFirst respondsToSelector:@selector(hidesBarsOnSwipe)]) {
        navControllerFirst.hidesBarsOnSwipe = YES;
    }
    
    NSArray *viewControllersArray = @[navControllerFirst, navControllerSecond];
    UITabBarController *tabBar = [[UITabBarController alloc] init];
    [tabBar setViewControllers:viewControllersArray];
    
    self.reachManager = [[PGReachabilityManager alloc] init];
    
    [PGPhotoProvider createPhotoProviderWithCompletionHandler:^(PGPhotoProvider *ph, NSError *error) {
        if (!error) {
            self.photoProvider = ph;
            galleryViewController.photoProvider = ph;
            userViewController.photoProvider = ph;
            
            [[NSNotificationCenter defaultCenter] postNotificationName:@"PGPhotoProviderDidSucceedNotification"
                                                                object:self
                                                              userInfo:nil];
        }
        else{
            NSLog(@"error initializing PGPhotoProvider: %@", [error localizedDescription]);
        }
    }];
    
    [self.window setRootViewController:tabBar];
    [self.window setBackgroundColor:[UIColor whiteColor]];
    
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application {
    [self.photoProvider persistData];
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    [self.photoProvider persistData];
}

- (void)applicationWillTerminate:(UIApplication *)application {
    [self.photoProvider persistData];
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    //
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}



@end
