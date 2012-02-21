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

#pragma mark NSRails

- (IBAction) create
{	
	[self updateAttributesFromUI];
	
	NSError *e;
	if ([person remoteCreate:&e]) ///<------------------ create (will return boolean for whether it was successful)
	{
		[people addObject:person];
		
		[self updateUI];
		[picker selectRow:people.count inComponent:0 animated:YES];
	}
	else
	{
		[self alertForError:e];
		[self updateUI];
	}
}

- (IBAction) update
{
	[self updateAttributesFromUI];
	
	NSError *e;
	if (![person remoteUpdate:&e]) ///<------------------ update to server (will return boolean for whether it was successful)
	{
		[self alertForError:e];
	}
	
	[person remoteGetLatest];
	[self updateUI];
}

- (IBAction) destroy
{
	NSError *e;
	if ([person remoteDestroy:&e])  ///<------------------ destroy (will return boolean for whether it was successful)
	{
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
		
		[self updateUIToRow:personIndex+1];
	}
	else
	{
		[self alertForError:e];
	}
}

- (IBAction) refresh
{
	people = [NSMutableArray arrayWithArray:[Person remoteAll]]; ///<------- getAll (index) - will return an array of People
	
	if (person.modelID)
	{
		[person remoteGetLatest];  ///<------------------ get (read/retrieve) will update this instance's attributes to match server
	}
	
	[self updateUI];
}

#pragma mark App UI Stuff

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

- (void) updateUIToRow:(int)row
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
	
	[self updateUIToRow:0];
	[self refresh];
}

- (void) updateAttributesFromUI
{
	person.name = nameField.text;
	person.age = [NSNumber numberWithInt:[ageField.text intValue]];
	if (!person.brain)
		person.brain = [[Brain alloc] init];
	person.brain.size = brainSizeField.text;
}


#pragma mark - Picker stuff

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

	Person *p = [people objectAtIndex:row-1];
	return [p name];
}

- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component
{
	[self updateUIToRow:row];
}

#pragma mark Error handling

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
				errorString = [errorString stringByAppendingFormat:@"%@ %@. ",[property toClassName],message];
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

- (void) seeThoughts
{
	DetailViewController *detail = [[DetailViewController alloc] initWithStyle:UITableViewStyleGrouped];
	detail.brain = person.brain;
	detail.title = [NSString stringWithFormat:@"%@'s brain",person.name];
	[self.navigationController pushViewController:detail animated:YES];
}

@end
