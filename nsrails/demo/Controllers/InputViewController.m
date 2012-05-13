//
//  InputViewController.m
//  NSRailsApp
//
//  Created by Dan Hassin on 2/20/12.
//  Copyright (c) 2012 InContext LLC. All rights reserved.
//

#import "InputViewController.h"
#import <QuartzCore/QuartzCore.h>

/*
 =================================================
 This class has nothing to do with NSRails - just
 a method to get user input
 =================================================
 */

@interface InputViewController (private)

- (void) placehold;

@end

@implementation InputViewController
@synthesize messagePlaceholder, header;

- (id) initWithCompletionHandler:(PostInputBlock)completionBlock
{
	self = [super initWithNibName:@"InputViewController" bundle:nil];
	if (self)
	{
		block = completionBlock;
	}
	return self;
}

- (void) cancel
{
	[self dismissModalViewControllerAnimated:YES];
}

- (void) save
{
	NSString *author = authorField.text;
	NSString *message = (contentField.tag == 0 ? @"" : contentField.text); //blank if still on placeholder (tag 0)
	
	BOOL shouldDismiss = block(author, message);
	if (shouldDismiss)
		[self dismissModalViewControllerAnimated:YES];
}


#pragma mark - View lifecycle

- (void)viewDidLoad
{
	/*
	 Boring UI stuff
	 */
	
	headerLabel.text = header;
	
	// Focus on authorField
	[authorField becomeFirstResponder];
	
	// Make the fields look nice and round
	contentField.layer.cornerRadius = 4;
	contentField.layer.borderColor = [[UIColor grayColor] CGColor];
	contentField.layer.borderWidth = 1;
	
	authorField.layer.cornerRadius = 4;
	authorField.layer.borderColor = [[UIColor grayColor] CGColor];
	authorField.layer.borderWidth = 1;

	// Add some space to side of authorField
	UIView *paddingView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 5, 20)];
	authorField.leftView = paddingView;
	authorField.leftViewMode = UITextFieldViewModeAlways;
	
	// Start off the textview with the placeholder
	[self placehold];
	
    [super viewDidLoad];
}

/*
 Everything below is code for the placeholder in the message textview, which isn't built-in into iOS
 */

- (void) placehold
{
	contentField.text = messagePlaceholder;
	contentField.textColor = [UIColor lightGrayColor];
	contentField.tag = 0;
	
	[contentField setSelectedTextRange:[contentField textRangeFromPosition:[contentField beginningOfDocument] toPosition:[contentField beginningOfDocument]]];
}

- (BOOL) textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text
{
	if (text.length == 0 && ((range.length > 0 && range.length == textView.text.length) || (textView.tag == 0)))
	{
		[self placehold];
		
		return NO;
	}
	else
	{
		if (textView.tag == 0)
		{
			textView.text = @"";
		}
		textView.textColor = [UIColor blackColor];
		textView.tag = 1;
	}
	return YES;
}

- (BOOL) textViewShouldEndEditing:(UITextView *)textView
{
	if (textView.text.length == 0)
	{
		[self placehold];
	}
	return YES;
}

- (BOOL) textViewShouldBeginEditing:(UITextView *)textView
{
	if (textView.tag == 0)
	{
		[textView setSelectedTextRange:[textView textRangeFromPosition:[textView beginningOfDocument] toPosition:[textView beginningOfDocument]]];
	}
	return YES;
}

- (void) textViewDidChangeSelection:(UITextView *)textView
{
	if (textView.tag == 0)
	{
		//make it temporarily -1 to not start an infinite loop after next line
		textView.tag = -1;
		//move selection to beginning (now with tag -1)
		UITextRange *beg = [textView textRangeFromPosition:[textView beginningOfDocument] toPosition:[textView beginningOfDocument]];
		[textView setSelectedTextRange:beg];
		//back to 0
		textView.tag = 0;
	}
}

@end
