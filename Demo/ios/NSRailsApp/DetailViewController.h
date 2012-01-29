//
//  DetailViewController.h
//  NSRailsApp
//
//  Created by Dan Hassin on 1/29/12.
//  Copyright (c) 2012 InContext LLC. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Person.h"

@interface DetailViewController : UITableViewController

@property (strong, nonatomic) Brain *brain;

- (IBAction) refresh;

@end
