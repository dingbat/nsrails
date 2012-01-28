//
//  SLViewController.h
//  RailsTest
//
//  Created by Dan Hassin on 1/24/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "User.h"

@interface SLViewController : UIViewController
{
	User *user;
	IBOutlet UITextField *usernameField;
	IBOutlet UITextField *passwordField;
	IBOutlet UITextField *friendField;
	IBOutlet UILabel *idLabel;
	
	IBOutlet UISwitch *sync;
}

- (IBAction) get1;
- (IBAction) create;
- (IBAction) update;
- (IBAction) destroy;
- (IBAction) index;


@end
