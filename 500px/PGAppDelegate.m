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

@property (nonatomic, strong) PGReachabilityManager *reachManager;

@end

@implementation PGAppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    self.window = [UIWindow new];
    
    //Configuration for gallery view controller
    PGGalleryCollectionViewController *galleryViewController = [[PGGalleryCollectionViewController alloc] init];
    galleryViewController.tabBarItem = [[UITabBarItem alloc] initWithTitle:nil image:[UIImage imageNamed:@"home"] selectedImage:nil];
    
    //Configuration for user view controller
    PGUserViewController *userViewController = [[PGUserViewController alloc] init];
    userViewController.tabBarItem = [[UITabBarItem alloc] initWithTitle:nil image:[UIImage imageNamed:@"user"] selectedImage:nil];
    
    UINavigationController *navControllerFirst = [[UINavigationController alloc] initWithRootViewController:galleryViewController];
    UINavigationController *navControllerSecond = [[UINavigationController alloc] initWithRootViewController:userViewController];
    
    NSArray *viewControllersArray = @[navControllerFirst, navControllerSecond];
    UITabBarController *tabBar = [[UITabBarController alloc] init];
    [tabBar setViewControllers:viewControllersArray];
    
    self.reachManager = [[PGReachabilityManager alloc] init];

    
    [PGPhotoProvider createPhotoProviderWithCompletionHandler:^(PGPhotoProvider *ph, NSError *error) {
        if (!error) {
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
    [self.window makeKeyAndVisible];
    
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

@end
