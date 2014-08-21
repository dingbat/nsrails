//
//  AppDelegate.m
//  NSRailsDemo
//
//  Created by Dan Hassin on 2/20/12.
//  Copyright (c) 2012 InContext LLC. All rights reserved.
//

#import "AppDelegate.h"
#import <NSRails/NSRails.h>

#import "PostsViewController.h"

@implementation AppDelegate
@synthesize window, navigationController;

- (BOOL) application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    [[NSRConfig defaultConfig] setRootURL:[NSURL URLWithString:@"http://nsrails.com"]];
    
    // For testing on local server:
    //[[NSRConfig defaultConfig] setAppURL:@"http://localhost:3000"];
    
    //authentication
    [[NSRConfig defaultConfig] setBasicAuthUsername:@"NSRails"];
    [[NSRConfig defaultConfig] setBasicAuthPassword:@"iphone"];
    
    
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    
    PostsViewController *posts = [[PostsViewController alloc] initWithStyle:UITableViewStyleGrouped];
    self.navigationController = [[UINavigationController alloc] initWithRootViewController:posts];
    
    self.window.rootViewController = self.navigationController;
    [self.window makeKeyAndVisible];
    
    return YES;
}

+ (void) alertForError:(NSError *)e
{
    NSString *errorString;
    
    NSDictionary *validationErrors = [[e userInfo] objectForKey:NSRErrorResponseBodyKey];
    
    if (validationErrors)
    {
        errorString = [NSString string];
        
        // Iterate through each failed property (keys)
        for (NSString *failedProperty in validationErrors)
        {
            // Iterate through each reason the property failed
            for (NSString *reason in [validationErrors objectForKey:failedProperty])
            {
                errorString = [errorString stringByAppendingFormat:@"%@ %@. ", [failedProperty capitalizedString], reason];
                //=> "Name can't be blank."
            }
        }
    }
    else
    {
        if (e.domain == NSRRemoteErrorDomain)
        {
            errorString = @"Something went wrong! Please try again later or contact us if this error continues.";
        }
        else
        {
            errorString = @"There was an error connecting to the server.";
        }
    }
    
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error"
                                                    message:errorString 
                                                   delegate:nil 
                                          cancelButtonTitle:@"OK" 
                                          otherButtonTitles:nil];
    [alert show];
}

@end
