//
//  InputViewController.h
//  NSRailsApp
//
//  Created by Dan Hassin on 2/20/12.
//  Copyright (c) 2012 InContext LLC. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef BOOL (^PostInputBlock)(NSString *author, NSString *content);

@interface InputViewController : UIViewController <UITextViewDelegate>
{
	PostInputBlock block;
	
	IBOutlet UITextField *authorField;
	IBOutlet UITextView *contentField;
	IBOutlet UILabel *headerLabel;
}

@property (nonatomic, retain) NSString *header, *messagePlaceholder;

- (id) initWithCompletionHandler:(PostInputBlock)completionBlock;

- (IBAction) save;
- (IBAction) cancel;

@end
