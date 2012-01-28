//
//  SLViewController.m
//  RailsTest
//
//  Created by Dan Hassin on 1/24/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "SLViewController.h"
#import "Story.h"

@implementation SLViewController

- (void) updateFields
{
	NSLog(@"from update UI method, %@/%@",user.username,user.password);
	usernameField.text = user.username;
	passwordField.text = user.password;
	idLabel.text = [user.modelID stringValue];
	friendField.text = user.myFriend.name;
	
	[usernameField resignFirstResponder];
	[passwordField resignFirstResponder];
	[friendField resignFirstResponder];
}

- (void) get1
{
	if (!user)
	{
		user = [User getRemoteObjectWithID:1];
		[self updateFields];
	}
	else
	{
		if (sync.on)
		{
			[user getRemoteLatest];
		}
		else
		{
			[user getRemoteLatestAsync:^(NSError *error) {
				if (error)
				{
					NSRLogError(error);
				}
				else
				{
					NSLog(@"block DONE, %@/%@!",user.username,user.password);
					[self performSelectorOnMainThread:@selector(updateFields) withObject:nil waitUntilDone:NO];
				}}];

		}
	}
}

- (void) update
{
	user.username = usernameField.text;
	user.password = passwordField.text;
	user.myFriend = nil;
	
	for (Story *st in user.stories)
	{
		st.destroyOnNesting = YES;
	}
	
	Story *s = [[Story alloc] init];
	s.content = @"From iphone 2";
	[user.stories addObject:s];
	
	if (sync.on)
	{
		[user updateRemote];
	}
	else
	{
		[user updateRemoteAsync:^(NSError *error) {
			NSLog(@"async!! with error %@", error);
			[self updateFields];
		}];
	}
}

- (void) create
{
	user = [[User alloc] init];
	user.username = usernameField.text;
	user.password = passwordField.text;
	
	Friend *f = [[Friend alloc] init];
	f.name = friendField.text;
	user.myFriend = f;
	
	if (sync.on)
	{
		[user createRemote];
	}
	else
	{
		[user createRemoteAsync:^(NSError *error) {
			NSLog(@"async!! with error %@", error);
			[self updateFields];
		}];
	}
	
	[self updateFields];
}

- (void) destroy
{	
	if (sync.on)
	{
		[user destroyRemote];
		user = nil;
	}
	else
	{
		[user destroyRemoteAsync:^(NSError *error) {
			NSLog(@"async!! with error %@", error);
			user = nil;
			[self updateFields];
		}];
	}
}

- (void) index
{
	if (sync.on)
	{
		NSArray *users = [User getAllRemote];
		for (User *u in users)
		{
			NSLog(@"%@/%@ id=%@",u.username,u.password,u.modelID);
		}
	}
	else
	{
		[User getAllRemoteAsync:^(NSArray *allRemote, NSError *error) {
			if (error)
			{
				NSLog(@"error in async:");
				NSRLogError(error);
			}
			else
			{
				NSLog(@"ASYNC!!");
				for (User *u in allRemote)
				{
					NSLog(@"%@/%@ id=%@",u.username,u.password,u.modelID);
				}
			}
		}];
	}
}

- (void)viewDidLoad
{	
}

@end
