//
//  SLViewController.m
//  RailsTest
//
//  Created by Dan Hassin on 1/24/12.
//  Copyright (c) 2012 InContext LLC. All rights reserved.
//

#import "SLViewController.h"
#import "Thought.h"

@implementation SLViewController

- (void) updateFields
{
	nameField.text = person.name;
	brainSizeField.text = person.brain.size;
	idLabel.text = [person.modelID stringValue];
	ageField.text = [person.age description];
	
	[nameField resignFirstResponder];
	[brainSizeField resignFirstResponder];
}

- (void) get1
{
	if (!person)
	{
		person = [Person getRemoteObjectWithID:1];
		[self updateFields];
	}
	else
	{
		[person getRemoteLatest];
	}
}

- (void) clearMind
{
	for (Thought *st in person.brain.thoughts)
	{
		st.destroyOnNesting = YES;
	}
	
	[person.brain updateRemote];
}

- (void) update
{
	person.name = nameField.text;
	person.age = [NSNumber numberWithInt:[ageField.text intValue]];
	person.brain.size = brainSizeField.text;
	
	[person updateRemote];
}

- (void) create
{
	person = [[Person alloc] init];
	person.name = nameField.text;
	person.age = [NSNumber numberWithInt:[ageField.text intValue]];
	
	Brain *f = [[Brain alloc] init];
	f.size = brainSizeField.text;
	person.brain = f;
	
	[person createRemote];
	
	[self updateFields];
}

- (void) destroy
{	
	[person destroyRemote];
	person = nil;
}

- (void) index
{
	NSArray *persons = [Person getAllRemote];
	for (Person *u in persons)
	{
		NSLog(@"%@ id=%@",u.name,u.modelID);
	}
}

- (void)viewDidLoad
{	
}

@end
