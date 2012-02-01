//
//  MasterViewController.h
//  NSRailsApp
//
//  Created by Dan Hassin on 1/29/12.
//  Copyright (c) 2012 InContext LLC. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Brain.h"

@interface MasterViewController : UIViewController <UIPickerViewDelegate, UIPickerViewDataSource>
{
	IBOutlet UIPickerView *picker;
	NSMutableArray *people;
	
	IBOutlet UIBarButtonItem *create, *update, *destroy, *refresh;
	IBOutlet UITextField *nameField, *ageField, *brainSizeField;
	IBOutlet UILabel *idLabel;
	IBOutlet UIToolbar *toolbar;
	IBOutlet UIButton *brainButton;
	
	Person *person;
}

- (IBAction) create;
- (IBAction) update;
- (IBAction) destroy;
- (IBAction) refresh;

- (IBAction) seeThoughts;


@end
