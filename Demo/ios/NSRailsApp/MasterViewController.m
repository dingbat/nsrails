//
//  MasterViewController.m
//  NSRailsApp
//
//  Created by Dan Hassin on 1/29/12.
//  Copyright (c) 2012 InContext LLC. All rights reserved.
//

#import "MasterViewController.h"

#import "DetailViewController.h"

#import "JSONFramework.h"
#import "NSString+InflectionSupport.h"

@implementation MasterViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self)
	{
		self.title = @"NSRails";
    }
    return self;
}

- (void) updateUI
{
	nameField.text = person.name;
	ageField.text = [person.age stringValue];
	idLabel.text = [person.modelID stringValue];
	brainSizeField.text = person.brain.size;
	
	UIBarButtonItem *flex = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
	if (!person.modelID)
	{
		toolbar.items = [NSArray arrayWithObjects:create, flex, refresh, nil];
		brainButton.hidden = YES;
	}
	else
	{
		toolbar.items = [NSArray arrayWithObjects:update, flex, destroy, flex, refresh, nil];
		brainButton.hidden = NO;
	}
	
	[nameField resignFirstResponder];
	[ageField resignFirstResponder];
	[brainSizeField resignFirstResponder];
	
	[picker reloadAllComponents];
}

- (void) updateToRow:(int)row
{
	if (row == 0)
	{
		person = [[Person alloc] init];
		person.brain = [[Brain alloc] init];
	}
	else
	{
		person = [people objectAtIndex:row-1];
	}
	
	[self updateUI];
}

- (void) viewDidLoad
{
	[super viewDidLoad];
	
	[self updateToRow:0];
	[self refresh];
}

#pragma mark - View lifecycle

- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component
{
	return people.count+1;
}

- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView
{
	return 1;
}

- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component
{
	if (row == 0)
		return @"[New person]";

	return [(Person *)[people objectAtIndex:row-1] name];
}

- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component
{
	[self updateToRow:row];
}

#pragma mark CRUD

- (void) updateAttributesFromUI
{
	person.name = nameField.text;
	person.age = [NSNumber numberWithInt:[ageField.text intValue]];
	person.brain.size = brainSizeField.text;
}

- (IBAction) create
{	
	[self updateAttributesFromUI];
	
	NSError *e;
	if ([person createRemote:&e])
	{
		[people addObject:person];
		
		[self updateUI];
		[picker selectRow:people.count inComponent:0 animated:YES];
	}
	else
	{
		int errors = 0;
		NSString *errorString = @"";
		NSDictionary *error = [[e localizedDescription] JSONValue];
		for (NSString *property in error)
		{
			for (NSString *message in [error objectForKey:property])
			{
				errorString = [errorString stringByAppendingFormat:@"%@ %@. ",[property toClassName],message];
				errors++;
			}
		}
		UIAlertView *alert = [[UIAlertView alloc] initWithTitle:[NSString stringWithFormat:@"%d Error%@",errors,errors > 1 ? @"s" : @""] message:errorString delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
		[alert show];
		[self updateUI];
	}
}

- (IBAction) update
{
	[self updateAttributesFromUI];
	
	[person updateRemote];
	
	[self updateUI];
}

- (IBAction) destroy
{
	[person destroyRemote];
	
	int personIndex = [people indexOfObject:person];
	[people removeObjectIdenticalTo:person];

	if (people.count > 0)
	{
		if (personIndex == people.count)
			personIndex--;
		person = [people objectAtIndex:personIndex];
	}
	else
	{
		personIndex = -1;
		person = nil;
	}
	
	[self updateToRow:personIndex+1];

	[self updateUI];
}

- (IBAction) refresh
{
	people = [NSMutableArray arrayWithArray:[Person getAllRemote]];
	
	if (person.modelID)
	{
		[person getRemoteLatest];
	}

	[self updateUI];
}

- (void) seeThoughts
{
	DetailViewController *detail = [[DetailViewController alloc] initWithStyle:UITableViewStyleGrouped];
	detail.brain = person.brain;
	detail.title = [NSString stringWithFormat:@"%@'s brain",person.name];
	[self.navigationController pushViewController:detail animated:YES];
}

@end
