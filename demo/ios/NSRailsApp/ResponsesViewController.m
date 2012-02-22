//
//  ResponsesViewController.m
//  NSRailsApp
//
//  Created by Dan Hassin on 2/20/12.
//  Copyright (c) 2012 InContext LLC. All rights reserved.
//

#import "ResponsesViewController.h"
#import "Response.h"
#import "AppDelegate.h"
#import "InputViewController.h"

@implementation ResponsesViewController

- (id)initWithPost:(Post *)p
{
    self = [super initWithStyle:UITableViewStyleGrouped];
    if (self) {
		post = p;
    }
    return self;
}

#pragma mark - View lifecycle

- (void) addResponse
{
	InputViewController *newPostVC = [[InputViewController alloc] initWithCompletionHandler:
										  ^BOOL (NSString *author, NSString *content) 
										  {
											  NSError *error;
											  
											  Response *newResp = [[Response alloc] init];
											  newResp.author = author;
											  newResp.body = content;
											  newResp.post = post;
											  
											  if ([newResp remoteCreate:&error])
											  {
												  [post remoteGetLatest];
												  
												  [self.tableView reloadData];
												  return YES;
											  }
											  [(AppDelegate *)[UIApplication sharedApplication].delegate alertForError:error];

											  return NO;
										  }];
	
	newPostVC.header = [NSString stringWithFormat:@"Write your response to %@:",post.author];
	newPostVC.messagePlaceholder = @"Your response";
	
	[self presentModalViewController:newPostVC animated:YES];
}

- (void)viewDidLoad
{	
	self.title = [NSString stringWithFormat:@"Post #%@",post.modelID];
	
	//add the + button
	UIBarButtonItem *new = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemReply target:self action:@selector(addResponse)];
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
    return post.responses.count;
}

- (NSString *) tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section
{
	if (post.responses.count == 0)
	{
		return @"\nThere are no responses to this post.\nSay something!";
	}
	return nil;
}

- (NSString *) tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
	return [NSString stringWithFormat:@"\"%@\"",post.body];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
    }
    
	Response *resp = [post.responses objectAtIndex:indexPath.row];
	cell.textLabel.text = [NSString stringWithFormat:@"\"%@\"",resp.body];
	cell.detailTextLabel.text = resp.author;
    
    return cell;
}

@end
