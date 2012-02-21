//
//  DetailViewController.m
//  NSRailsApp
//
//  Created by Dan Hassin on 1/29/12.
//  Copyright (c) 2012 InContext LLC. All rights reserved.
//

#import "DetailViewController.h"
#import "Thought.h"
#import "Brain.h"
#import "Person.h"

@implementation DetailViewController

@synthesize brain;

#pragma mark - View lifecycle

- (void) refresh
{
	[brain remoteGetLatest]; ///<------------------ get (read/retrieve) will update this instance's attributes to match server
	
	[self.tableView reloadData];
}

- (void)viewDidLoad
{
	UIBarButtonItem *ref = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh target:self action:@selector(refresh)];
	self.navigationItem.rightBarButtonItem = ref;
	
    [super viewDidLoad];
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	if (section == 0)
		return [brain.thoughts count];
	
	return 1;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
	return 2;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }
	
	if (indexPath.section == 0)
	{
		cell.textLabel.text = [(Thought *)[brain.thoughts objectAtIndex:indexPath.row] content];
		cell.textLabel.textAlignment = UITextAlignmentLeft;
    }
	else
	{
		cell.textLabel.text = @"Clear my cluttered mind!";
		cell.textLabel.textAlignment = UITextAlignmentCenter;
	}
	return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	//if user selected the "cluttered mind" row (only row in section 1)
	if (indexPath.section == 1)
	{
		for (Thought *t in brain.thoughts)
		{
			t.destroyOnNesting = YES;  ///<------------------ mark each Thought for delete on the nested update later
		}
		[brain remoteUpdate];  ///<------------------ update to server (will return boolean for whether it was successful)
		
		[brain.thoughts removeAllObjects];
		[tableView reloadData];
	}
}

							
@end
