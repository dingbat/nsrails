//
//  PostsViewController.m
//  NSRailsDemo
//
//  Created by Dan Hassin on 2/20/12.
//  Copyright (c) 2012 InContext LLC. All rights reserved.
//

#import "PostsViewController.h"
#import "InputViewController.h"
#import "AppDelegate.h"
#import "ResponsesViewController.h"

#import "Post.h"

@implementation PostsViewController


/*
 =================================================
	RELEVANT NSRAILS STUFF
 =================================================
 */

- (void) refresh
{
	// When the refresh button is hit, refresh our array of posts (uses a category on NSMutableArray)
	
	BOOL changes;
	NSError *error;
	
	BOOL success = [posts remoteFetchAll:[Post class] error:&error changes:&changes];
	
	if (!success)
	{
		[AppDelegate alertForError:error];
	}
	else if (changes)
	{
		[self.tableView reloadData];
	}
	
	// This could also be done by setting posts to the result of [Post remoteAll:&error], but the NSMutableArray category will persist the same objects and update their respective properties instead of replacing everything, which could be desirable
}

- (void) addPost
{
	// When the + button is hit, display an InputViewController (this is the shared input view for both posts and responses)
	// It has an init method that accepts a completion block - this block of code will be executed when the user hits "save"
	
	InputViewController *newPostVC = [[InputViewController alloc] initWithCompletionHandler:
										  ^BOOL (NSString *author, NSString *content) 
										  {
											  NSError *error;
											  
											  Post *newPost = [[Post alloc] init];
											  newPost.author = author;
											  newPost.content = content;
											  											  
											  if (![newPost remoteCreate:&error])
											  {
												  [AppDelegate alertForError:error];
												  
												  //don't dismiss the input VC
												  return NO;
											  }
											  											  
											  [posts insertObject:newPost atIndex:0];
											  [self.tableView reloadData];
											  
											  return YES;											  
										  }];
	
	newPostVC.header = @"Post something to NSRails.com!";
	newPostVC.messagePlaceholder = @"A comment about NSRails, a philosophical inquiry, or simply a \"Hello world\"!";
	
	[self presentModalViewController:newPostVC animated:YES];
}

- (void) deletePostAtIndexPath:(NSIndexPath *)indexPath
{
	NSError *error;
	
	Post *post = [posts objectAtIndex:indexPath.row];
	if ([post remoteDestroy:&error])
	{
		// Remember to delete the object from our local array too
		[posts removeObject:post];
		
		[self.tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
	}
	else
	{
		[AppDelegate alertForError:error];
	}
}

/*
 =================================================
 UI + TABLE STUFF
 =================================================
 */

- (void)viewDidLoad
{
	posts = [[NSMutableArray alloc] init];
	
	[self refresh];
	
	self.title = @"Posts";
	
	// Add refresh button
	UIBarButtonItem *refresh = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh 
																			 target:self 
																			 action:@selector(refresh)];
	self.navigationItem.leftBarButtonItem = refresh;
	
	// Add the + button
	UIBarButtonItem *new = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd 
																		 target:self 
																		 action:@selector(addPost)];
	self.navigationItem.rightBarButtonItem = new;
	
    [super viewDidLoad];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
	return 1;
}

- (CGFloat) tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
	return 60;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	return posts.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) 
	{
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }

	Post *post = [posts objectAtIndex:indexPath.row];
	cell.textLabel.text = post.content;
	cell.detailTextLabel.text = post.author;
	
	return cell;
}

- (void) tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
	[self deletePostAtIndexPath:indexPath];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	Post *post = [posts objectAtIndex:indexPath.row];

	ResponsesViewController *rvc = [[ResponsesViewController alloc] initWithStyle:UITableViewStyleGrouped];
	rvc.post = post;
	[self.navigationController pushViewController:rvc animated:YES];
}

@end
