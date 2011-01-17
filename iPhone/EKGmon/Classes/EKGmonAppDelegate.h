//
//  EKGmonAppDelegate.h
//  EKGmon
//
//  Created by Jordan Schneider on 7/13/10.
//  Copyright Copyleft 2010. All rights reserved.
//

@class EKGmonViewController;

@interface EKGmonAppDelegate : NSObject <UIApplicationDelegate> {
    UIWindow *window;
    EKGmonViewController *viewController;
}

@property (nonatomic, retain) IBOutlet UIWindow *window;
@property (nonatomic, retain) IBOutlet EKGmonViewController *viewController;

@end

