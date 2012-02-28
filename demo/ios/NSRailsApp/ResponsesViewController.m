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
											  newResp.content = content;
											  newResp.post = post;      //check out Response.m for more detail on this line
											  
											  
											  [newResp remoteCreate:&error];

											  
											  /* 
											   Instead of line 40 (the belongs_to trick), you could also add the new response to the post's "responses" array and then update it:
											   
											     [post.responses addObject:newResp];
											     [post remoteUpdate:&error];
											   
											   Doing this may be better for your structure since it'd already be in post's "responses" array.
											   However, you have to take into account the case where the Response validation fails and you'd have to remove it from the array. Also, creating the Response rather than updating the Post will set newResp's remoteID! And, doing it this way will demonstrate that doing a [post remoteGetLatest]; in the next line will update post.responses.
											  */
											  
											  
											  if (!error)
											  {
												  //since it's not part of our post.responses array yet, let's remoteGetLatest
												  //(we could also just do a simple [post.responses addObject:newResp])
												  
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
	self.title = [NSString stringWithFormat:@"Post #%@",post.remoteID];
	
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
	return [NSString stringWithFormat:@"\"%@\"",post.content];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
		cell.selectionStyle = UITableViewCellSelectionStyleNone;
    }
    
	Response *resp = [post.responses objectAtIndex:indexPath.row];
	cell.textLabel.text = [NSString stringWithFormat:@"\"%@\"",resp.content];
	cell.detailTextLabel.text = resp.author;
    
    return cell;
}

- (void) tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
	//here, on the delete, we're calling remoteDestroy to destroy our object remotely. remember to remove it from our local array, too.

	Response *resp = [post.responses objectAtIndex:indexPath.row];
	[resp remoteDestroy];
	[post.responses removeObject:resp];
	
	[tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
}

@end
