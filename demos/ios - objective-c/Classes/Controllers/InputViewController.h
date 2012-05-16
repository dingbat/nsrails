//
//  InputViewController.h
//  NSRailsDemo
//
//  Created by Dan Hassin on 2/20/12.
//  Copyright (c) 2012 InContext LLC. All rights reserved.
//

#import <UIKit/UIKit.h>


/*
 =================================================
 This class has nothing to do with NSRails - just
 a method to get user input
 =================================================
 */


//needs to resolve to a BOOL (whether or not we should dismiss the VC)
//provides the two strings the user entered
typedef BOOL (^PostInputBlock)(NSString *author, NSString *content);

@interface InputViewController : UIViewController <UITextViewDelegate>
{
	PostInputBlock block;
	
	IBOutlet UITextField *authorField;
	IBOutlet UITextView *contentField;
	IBOutlet UILabel *headerLabel;
}

@property (nonatomic, retain) NSString *header, *messagePlaceholder;

//when the user hits "save", we'll execute this block
//this just makes everything easier to visualize since all the relevant code is in the same VC
- (id) initWithCompletionHandler:(PostInputBlock)completionBlock;

- (IBAction) save;
- (IBAction) cancel;

@end
