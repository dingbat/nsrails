//
//  SLViewController.h
//  RailsTest
//
//  Created by Dan Hassin on 1/24/12.
//  Copyright (c) 2012 InContext LLC. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Person.h"

@interface SLViewController : UIViewController
{
	Person *person;
	IBOutlet UITextField *nameField, *ageField, *brainSizeField;
	IBOutlet UILabel *idLabel;
}

- (IBAction) get1;
- (IBAction) create;
- (IBAction) update;
- (IBAction) destroy;
- (IBAction) index;
- (IBAction) clearMind;


@end
