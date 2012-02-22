//
//  PostsViewController.m
//  NSRailsApp
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

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) 
	{
		self.title = @"Posts";
    }
    return self;
}

#pragma mark - View lifecycle

- (void) refresh
{
	posts = [Post remoteAll];
	
	[self.tableView reloadData];
}

- (void) addPost
{
	InputViewController *newPostVC = [[InputViewController alloc] initWithCompletionHandler:
										  ^BOOL (NSString *author, NSString *content) 
										  {
											  NSError *error;
											  
											  Post *newPost = [[Post alloc] init];
											  newPost.author = author;
											  newPost.body = content;
											  
											  if ([newPost remoteCreate:&error])
											  {
												  [self refresh];
												  return YES;
											  }
											  
											  [(AppDelegate *)[UIApplication sharedApplication].delegate alertForError:error];
											  
											  return NO;
										  }];
	
	newPostVC.header = @"Post something to NSRails.com!";
	newPostVC.messagePlaceholder = @"A comment about NSRails, a philosophical inquiry, or simply a \"Hello world\"!";
	
	[self presentModalViewController:newPostVC animated:YES];
}

- (void)viewDidLoad
{
	[self refresh];
	
	//add refresh button
	UIBarButtonItem *refresh = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh target:self action:@selector(refresh)];
	self.navigationItem.leftBarButtonItem = refresh;
	
	//add the + button
	UIBarButtonItem *new = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(addPost)];
	self.navigationItem.rightBarButtonItem = new;
	
    [super viewDidLoad];
}

#pragma mark - Table view data source

// Customize the number of sections in the table view.
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
	return 1;
}

- (CGFloat) tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
	return 50;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	return posts.count;
}

// Customize the appearance of table view cells.
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
	cell.textLabel.text = post.body;
	cell.detailTextLabel.text = post.author;
	
	return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	Post *post = [posts objectAtIndex:indexPath.row];

	ResponsesViewController *rvc = [[ResponsesViewController alloc] initWithPost:post];
	[self.navigationController pushViewController:rvc animated:YES];
}

@end
