//
//  ResponsesViewController.m
//  NSRailsDemo
//
//  Created by Dan Hassin on 2/20/12.
//  Copyright (c) 2012 InContext LLC. All rights reserved.
//

#import "ResponsesViewController.h"
#import "Response.h"
#import "AppDelegate.h"
#import "InputViewController.h"

@implementation ResponsesViewController
@synthesize post;

/*
 =================================================
 RELEVANT NSRAILS STUFF
 =================================================
 */


- (void) addResponse
{
	InputViewController *newPostVC = [[InputViewController alloc] initWithCompletionHandler:
										  ^BOOL (NSString *author, NSString *content) 
										  {
											  NSError *error;
											  											  
											  Response *newResp = [[Response alloc] init];
											  newResp.author = author;
											  newResp.content = content;
											  newResp.post = post;    //check out Response.m for more detail on how this line is possible
											  
											  
											  if (![newResp remoteCreate:&error])
											  {
												  [AppDelegate alertForError:error];
												  
												  return NO;
											  }

											  [post.responses addObject:newResp]; 
											  [self.tableView reloadData];
											  
											  return YES;
											  
											  /* 
											   Instead of line 40 (the belongs_to trick), you could also add the new response to the post's "responses" array and then update it:
											   
											     [post.responses addObject:newResp];
											     [post remoteUpdate:&error];
											   
											   Doing this may be tempting since it'd already be in post's "responses" array, BUT: you'd have to take into account the Response validation failing (you'd then have to remove it from the array). Also, creating the Response rather than updating the Post will set newResp's remoteID, so we can do remote operations on it later!
											  */
										  }];
	
	newPostVC.header = [NSString stringWithFormat:@"Write your response to %@:",post.author];
	newPostVC.messagePlaceholder = @"Your response";
	
	[self presentModalViewController:newPostVC animated:YES];
}

- (void) deleteResponseAtIndexPath:(NSIndexPath *)indexPath
{
	NSError *error;
	
	Response *resp = [post.responses objectAtIndex:indexPath.row];
	if ([resp remoteDestroy:&error])
	{
		// Remember to delete the object from our local array too
		[post.responses removeObject:resp];
		
		[self.tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
		
		if (post.responses.count == 0)
			[self.tableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationAutomatic];
	}
	else
	{
		[AppDelegate alertForError:error];
	}
	
	/* 
	 If we wanted to batch-delete or something, we could also do:
	 
		resp.remoteDestroyOnNesting = YES;
		//do the same for other post's other responses
		[post remoteUpdate:&e];
	 
	 For this to work, you need to set `:allow_destroy => true` in Rails
	 */
}




/*
 =================================================
 UI + TABLE STUFF
 =================================================
 */


- (void)viewDidLoad
{	
	self.title = @"Responses";
	
	// Add the reply button
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
	NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
	[formatter setDateFormat:@"MM/dd/yy"];
	NSString *timestamp = [NSString stringWithFormat:@"(Posted on %@)",[formatter stringFromDate:post.createdAt]];

	NSString *encouragement = @"There are no responses to this post.\nSay something!\n\n";

	return [NSString stringWithFormat:@"%@%@", (post.responses.count == 0) ? encouragement : @"", timestamp];
}

- (NSString *) tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
	return [NSString stringWithFormat:@"“%@”",post.content];
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
	cell.textLabel.text = [NSString stringWithFormat:@"%@",resp.content];
	cell.detailTextLabel.text = resp.author;
    
    return cell;
}

- (void) tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
	[self deleteResponseAtIndexPath:indexPath];
}

@end
