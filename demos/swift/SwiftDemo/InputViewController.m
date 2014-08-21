//
//  InputViewController.m
//  NSRailsDemo
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
{
    PostInputBlock block;
}

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
    NSString *author = _authorField.text;
    NSString *message = (_contentField.tag == 0 ? @"" : _contentField.text); //blank if still on placeholder (tag 0)
    
    block(author, message);
}


#pragma mark - View lifecycle

- (void)viewDidLoad
{
    /*
     Boring UI stuff
     */
    
    _headerLabel.text = _header;
    
    // Focus on authorField
    [_authorField becomeFirstResponder];

    // Add some space to side of authorField
    UIView *paddingView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 5, 20)];
    _authorField.leftView = paddingView;
    _authorField.leftViewMode = UITextFieldViewModeAlways;
    
    // Start off the textview with the placeholder
    [self placehold];

    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancel)];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Post" style:UIBarButtonItemStyleDone target:self action:@selector(save)];
    
    self.title = @"New Post";
    
    [super viewDidLoad];
}

/*
 Everything below is code for the placeholder in the message textview, which isn't built-in into iOS
 */

- (void) placehold
{
    _contentField.text = _messagePlaceholder;
    _contentField.textColor = [UIColor lightGrayColor];
    _contentField.tag = 0;
    
    [_contentField setSelectedTextRange:[_contentField textRangeFromPosition:[_contentField beginningOfDocument] toPosition:[_contentField beginningOfDocument]]];
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
