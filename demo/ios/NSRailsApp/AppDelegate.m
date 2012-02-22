//
//  AppDelegate.m
//  NSRailsApp
//
//  Created by Dan Hassin on 2/20/12.
//  Copyright (c) 2012 InContext LLC. All rights reserved.
//

#import "AppDelegate.h"

#import "PostsViewController.h"

#import "NSRConfig.h"

@implementation AppDelegate

@synthesize window = _window;
@synthesize navigationController = _navigationController;

- (BOOL) application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
	[[NSRConfig defaultConfig] setAppURL:@"http://localhost:3000/"];
	
	[[NSRConfig defaultConfig] setAppUsername:@"NSRails"];
	[[NSRConfig defaultConfig] setAppPassword:@"iphone"];
	
	
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];

	PostsViewController *masterViewController = [[PostsViewController alloc] initWithNibName:@"PostsViewController" bundle:nil];
	self.navigationController = [[UINavigationController alloc] initWithRootViewController:masterViewController];
	self.window.rootViewController = self.navigationController;
    [self.window makeKeyAndVisible];
    return YES;
}

- (void) alertForError:(NSError *)e
{
	int errors = 0;
	NSString *errorString = @"";
	NSString *errorTitle = @"Error";
	NSDictionary *validationErrors = [[e userInfo] objectForKey:NSRValidationErrorsKey];
	if (validationErrors)
	{
		for (NSString *property in validationErrors)
		{
			for (NSString *message in [validationErrors objectForKey:property])
			{
				NSString *properCase = [[[property substringToIndex:1] uppercaseString] stringByAppendingString:[property substringFromIndex:1]];
				errorString = [errorString stringByAppendingFormat:@"%@ %@. ",properCase,message];
				errors++;
			}
		}
		if (errors > 1)
			errorTitle = [NSString stringWithFormat:@"%d Errors",errors];
	}
	else
	{
		errorString = [e localizedDescription];
	}
	UIAlertView *alert = [[UIAlertView alloc] initWithTitle:errorTitle message:errorString delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
	[alert show];
}


@end
