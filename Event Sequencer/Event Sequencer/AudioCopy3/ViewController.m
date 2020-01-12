//
//  ViewController.m
//  Example
//
//  Created by dan walton on 8/27/13.
//  Copyright (c) 2013 retronyms. All rights reserved.
//

/*
 
 The code below shows you how to integrate AudioCopy/Paste into your
 app. Note that NSAppTransportSecurity and LSApplicationQueriesScheme
 keys are now required in your app's info.plist in iOS 9. Please see
 http://acp.retronyms.com/getstarted for more information.

 The AudioCopy/Paste view controllers have been designed to be easy to interface
 with. The general outline is:
 
 1. Create the appropriate view controller.  AudioCopyViewController should be 
 initialized with a path to a valid 44.1k 16bit wav file.  This will allow the user
 to copy a file onto the pasteboard.  AudioPasteViewController should be 
 initialized with a directory.  This will be where the file is pasted into with a
 unique name.
 
 2. Present the controller
 
 There are appropriate methods for both types of controllers and for each way
 to present it.  Simply figure out how you want to integrate the controller,
 then look at the appropriate method and copy the code from the method body.
 
 - (void) presentAudioCopyViewControllerModally
 - (void) presentAudioCopyViewControllerInPopover
 - (void) presentAudioCopyViewControllerInSuperview
 - (void) presentAudioCopyViewControllerInNavigationController

 - (void) presentAudioPasteViewControllerModally
 - (void) presentAudioPasteViewControllerInPopover
 - (void) presentAudioPasteViewControllerInSuperview
 - (void) presentAudioPasteViewControllerInNavigationController
 
 Note that the ...InNavigationController methods will use a root controller
 with a button that when tapped, will push the controller onto the stack
 using the well-known UINavigationController:pushViewController:animated:completion
 method.  This is too simulate putting an AudioCopy controller at some
 level deeper than the navigation root.
 
 */

#import "ViewController.h"
#import "AudioCopy/AudioCopyPaste.h"

//------------------------------------------------------------------------------

@interface ViewController()

@property (nonatomic, strong) IBOutlet UIView* buttonsView;
@property (nonatomic, strong) IBOutlet UIButton* audioCopyButton;
@property (nonatomic, strong) IBOutlet UIButton* audioPasteButton;

@end

//------------------------------------------------------------------------------

@implementation ViewController

//------------------------------------------------------------------------------
#pragma mark - Overloaded methods
//------------------------------------------------------------------------------

- (void) viewDidLoad
{
    // If there is a specific urlscheme you would like to use, you can put it here.
	// You still have to enter it into your plist.
    //[AudioCopyPaste setURLScheme:@"Example"];

    // will print out the current app configuration
    [ AudioCopyPaste debugConfiguration ];
    
    // Set affiliate code, visit http://acp.retronyms.com/developers for more info.
    [AudioCopyPaste setAffiliateCode:@"5199af9d4e204ff58bad146a7cf2f9"];
    
	// round the corners of the desired superview
	// this is just to look nice
	self.desiredSuperview.layer.cornerRadius = 10.0;
	self.desiredSuperview.layer.masksToBounds = YES;
	
	// change the title of the first segment to better
	// match how controllers are modally presented on iPad
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
	{
		[ self.desiredStyleControl setTitle: @"Popover" forSegmentAtIndex: 0 ];
	}
}

//------------------------------------------------------------------------------
#pragma mark - Private methods
//------------------------------------------------------------------------------

- (void) cleanUpControllersAndViews
{
	// clean up views
	[ self.desiredSuperview.subviews makeObjectsPerformSelector: @selector(removeFromSuperview) ];
	
	// clean up any existing controllers
	[ self.childViewControllers makeObjectsPerformSelector: @selector(removeFromParentViewController) ];
	
	// clean up the nav controller and pop controllers off it
	[ self.audioCopyNavigationController popToRootViewControllerAnimated: NO ];
	[ self.audioPasteNavigationController popToRootViewControllerAnimated: NO ];
}

//------------------------------------------------------------------------------

- (void) cleanUpControllersAndViewsAnimated: (BOOL) animated
{
	// if no animation
	// just remove the controllers and views
	if (animated == NO)
	{
		[ self cleanUpControllersAndViews ];
		return;
	}
	
	// otherwise do a nice animated removal
	[ UIView animateWithDuration: 0.5
					  animations: ^
	{
		if (self.desiredSuperview.subviews.count > 0)
		{
			UIView* view = self.desiredSuperview.subviews[0];
			view.alpha = 0;
		}
	}
					  completion: ^(BOOL finished)
	{
		[ self cleanUpControllersAndViews ];
		self.audioCopyNavigationController.view.alpha = 1.0;
		self.audioPasteNavigationController.view.alpha = 1.0;
	} ];
}

//------------------------------------------------------------------------------
#pragma mark - AudioCopy and AudioPaste button handling
//------------------------------------------------------------------------------

- (IBAction) audioCopyPressed: (id) sender
{
	// always clean up any existing views and controller
	// this is just to be tidy for this sample code
	[ self cleanUpControllersAndViews ];
	
	// check which option in the desired style control is selected
	NSInteger index = self.desiredStyleControl.selectedSegmentIndex;
	
	// present modally on iPhone
	if (index == 0 && UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone)
	{
		[ self presentAudioCopyViewControllerModally ];
	}
	
	// present modally on iPad
	else if (index == 0 && UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
	{
		[ self presentAudioCopyViewControllerInPopover ];
	}
	
	// embed in UIView
	else if (index == 1)
	{
		[ self presentAudioCopyViewControllerInSuperview ];
	}
	
	// embed in UINavigationController
	else if (index == 2)
	{
		[ self presentAudioCopyViewControllerInNavigationController ];
	}
}

//------------------------------------------------------------------------------

- (IBAction) audioPastePressed: (id) sender
{
	// always clean up any existing views and controller
	// this is just to be tidy for this sample code
	[ self cleanUpControllersAndViews ];
	
	// check which option in the desired style control is selected
	NSInteger index = self.desiredStyleControl.selectedSegmentIndex;
	
	// present modally on iPhone
	if (index == 0 && UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone)
	{
		[ self presentAudioPasteViewControllerModally ];
	}
	
	// present modally on iPad
	else if (index == 0 && UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
	{
		[ self presentAudioPasteViewControllerInPopover ];
	}
	
	// embed in UIView
	else if (index == 1)
	{
		[ self presentAudioPasteViewControllerInSuperview ];
	}
	
	// embed in UINavigationController
	else if (index == 2)
	{
		[ self presentAudioPasteViewControllerInNavigationController ];
	}
}

//------------------------------------------------------------------------------
#pragma mark - Presenting the AudioCopyViewController
//------------------------------------------------------------------------------

- (void) presentAudioCopyViewControllerModally
{
    
	// path to the file to copy
	NSString* fileToCopy = [[[ NSBundle mainBundle ] bundlePath] stringByAppendingPathComponent: @"_Muzoma C3-Piano.m4a"/*testaudio-stereo.wav"*/ ];
	
	// create the audio copy view controller
	// when the controller is being presented modally by a parent controller
	// it may not need to be stored as a class variable or property
	AudioCopyViewController* audioCopyViewController = nil;
    audioCopyViewController = [[ AudioCopyViewController alloc ] initWithPath: fileToCopy andMetaData:(NSMutableDictionary *)@{@"foo":@"bar"}];
	
	// make sure the "Done" button is shown
	audioCopyViewController.doneButtonHidden = NO;
	
	// present using UIViewController's default mechanism
	// this works for iPhone and iPad but is most common on iPhone
	// note that controllers presented this way can ask their
	// parent view controller to dismiss themselves
	[ self presentViewController: audioCopyViewController
						animated: YES
					  completion: nil ];
}

//------------------------------------------------------------------------------

- (void) presentAudioCopyViewControllerInPopover
{
	// create the audio copy view controller
    NSString* fileToCopy = [[[ NSBundle mainBundle ] bundlePath] stringByAppendingPathComponent: @"_Muzoma C3-Piano.m4a"/*testaudio-stereo.wav"*/ ];
	AudioCopyViewController* audioCopyViewController = [[ AudioCopyViewController alloc ] initWithPath: fileToCopy ];
	
	// the "Done" button is optionally needed for popovers
	// some popovers can be dismissed by touching outside
	// of the popover
	audioCopyViewController.doneButtonHidden = YES;

	// present using a pop-over
	// implementing the delegate is important to properly
	// handle cleaning up the audio copy and paste controllers
	self.presentedPopoverController = [[ UIPopoverController alloc ] initWithContentViewController: audioCopyViewController ];
	self.presentedPopoverController.delegate = self;
	
	// present the popover from the audio copy button
	[ self.presentedPopoverController presentPopoverFromRect: self.audioCopyButton.frame
													  inView: self.buttonsView
									permittedArrowDirections: UIPopoverArrowDirectionAny
													animated: YES ];
}

//------------------------------------------------------------------------------

- (void) presentAudioCopyViewControllerInSuperview
{
	// create the audio copy view controller
	NSString* fileToCopy = [[[ NSBundle mainBundle ] bundlePath] stringByAppendingPathComponent: @"_Muzoma C3-Piano.m4a"/*testaudio-stereo.wav"*/ ];
	AudioCopyViewController* audioCopyViewController = [[ AudioCopyViewController alloc ] initWithPath: fileToCopy ];
	
	// remember that if you're not managing the reference to the controller
	// you can use the controller container methods to do so
	[ self addChildViewController: audioCopyViewController ];
	
	// setting the delegate is necessary to know when
	// to dismiss the controller's view or give status messages
	audioCopyViewController.delegate = self;
	
	// the "Done" button is optional when the controller is
	// embedded into a superview, but make sure the delegate
	// is implemented to know when to clean up the view and controller
	audioCopyViewController.doneButtonHidden = YES;

	// embed the controller's view into the desired superview
	// if your superview supports multiple layouts, you will
	// to tell the controller's view to fill the superview
	audioCopyViewController.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
	audioCopyViewController.view.frame = self.desiredSuperview.bounds;
	[ self.desiredSuperview addSubview: audioCopyViewController.view ];
}

//------------------------------------------------------------------------------

- (void) presentAudioCopyViewControllerInNavigationController
{
	// create a nav controller and put it into the desired superview
	self.audioCopyNavigationController.view.frame = self.desiredSuperview.bounds;
	[ self.desiredSuperview addSubview: self.audioCopyNavigationController.view ];

	// check out pushAudioCopyViewControllerTouchUpInside:
	// to see how the controller is configured and pushed
	// onto the provided navigation controller
}

//------------------------------------------------------------------------------

- (IBAction) pushAudioCopyViewControllerTouchUpInside: (UIButton*) button
{
	// create the audio copy view controller
	NSString* fileToCopy = [[[ NSBundle mainBundle ] bundlePath] stringByAppendingPathComponent: @"_Muzoma C3-Piano.m4a"/*testaudio-stereo.wav"*/ ];
	AudioCopyViewController* audioCopyViewController = [[ AudioCopyViewController alloc ] initWithPath: fileToCopy ];
	
	// the delegate can handle when to dismiss the UI or
	// show completion messages when copying is done
	audioCopyViewController.delegate = self;
	
	// specify if the controller shows a "Done" button
	// some UIs may not want the button if the controller is embedded
	audioCopyViewController.doneButtonHidden = YES;

	// controller needs to know that it is using someone
	// else's nav controller instead of it's own
	// this is be a weak reference in case the audio copy
	// view controller goes away
	audioCopyViewController.parentNavigationController = self.audioCopyNavigationController;
	
	// now push the audio copy view controller
	[ self.audioCopyNavigationController pushViewController: audioCopyViewController animated: YES ];
}

//------------------------------------------------------------------------------
#pragma mark - Presenting the AudioPasteViewController
//------------------------------------------------------------------------------

- (void) presentAudioPasteViewControllerModally
{
	// path for applications' Documents directory
	NSArray* paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
	NSString* docsPath = paths.firstObject;

	// create the audio paste view controller
	// when the controller is being presented modally by a parent controller
	// it may not need to be stored as a class variable or property
	AudioPasteViewController* audioPasteViewController = [[ AudioPasteViewController alloc ] initWithPath: docsPath ];
	
    audioPasteViewController.delegate = self;
    
	// make sure the "Done" button is shown
	audioPasteViewController.doneButtonHidden = NO;
	
	// present using UIViewController's default mechanism
	// this works for iPhone and iPad but is most common on iPhone
	[ self presentViewController: audioPasteViewController
						animated: YES
					  completion: nil ];
}

//------------------------------------------------------------------------------

- (void) presentAudioPasteViewControllerInPopover
{
	// create the audio paste view controller
	NSArray* paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
	NSString* docsPath = paths.firstObject;
    AudioPasteViewController* audioPasteViewController = [[ AudioPasteViewController alloc ] initWithPath: docsPath ];
	// setting the delegate is necessary to know when
	// to dismiss the controller's view or give status messages
	audioPasteViewController.delegate = self;

	// the "Done" button is optionally needed for popovers
	// some popovers can be dismissed by touching outside
	// of the popover
	audioPasteViewController.doneButtonHidden = YES;
	
	// present using a pop-over
	// implementing the delegate is important to properly
	// handle cleaning up the audio copy and paste controllers
	self.presentedPopoverController = [[ UIPopoverController alloc ] initWithContentViewController: audioPasteViewController ];
    
    
    // N.B. Using multiple paste within a popover will lead
    // to a crash if the popover is dismissed during the paste
    // operation. Implement the UIPopoverControllerDelegate
    // popoverControllerShouldDismissPopover method as below
    // to handle this, or use the passthroughViews property
    // to limit how the popover can be dismissed.
	self.presentedPopoverController.delegate = self;
	
	// present the popover from the audio copy button
	[ self.presentedPopoverController presentPopoverFromRect: self.audioPasteButton.frame
													  inView: self.buttonsView
									permittedArrowDirections: UIPopoverArrowDirectionAny
													animated: YES ];
}

//------------------------------------------------------------------------------

- (void) presentAudioPasteViewControllerInSuperview
{
	// create the audio paste view controller
	NSArray* paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
	NSString* docsPath = paths.firstObject;
	AudioPasteViewController* audioPasteViewController = [[ AudioPasteViewController alloc ] initWithPath: docsPath ];

	// remember that if you're not managing the reference to the controller
	// you can use the controller container methods to do so
	[ self addChildViewController: audioPasteViewController ];

	// setting the delegate is necessary to know when
	// to dismiss the controller's view or give status messages
	audioPasteViewController.delegate = self;

	// the controller's default behaviour is to dismiss
	// when pasting has completed, but since this controller
	// is embedded in a superview, behaviour can be turned off
	audioPasteViewController.dismissAfterPasteComplete = NO;
	
	// the "Done" button is optional when the controller is
	// embedded into a superview, but make sure the delegate
	// is implemented to know when to clean up the view and controller
	audioPasteViewController.doneButtonHidden = YES;
	
	// embed the controller's view into the desired superview
	// if your superview supports multiple layouts, you will
	// to tell the controller's view to fill the superview
	audioPasteViewController.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
	audioPasteViewController.view.frame = self.desiredSuperview.bounds;
	[ self.desiredSuperview addSubview: audioPasteViewController.view ];
}

//------------------------------------------------------------------------------

- (void) presentAudioPasteViewControllerInNavigationController
{
	// create a nav controller and put it into the desired superview
	self.audioPasteNavigationController.view.frame = self.desiredSuperview.bounds;
	[ self.desiredSuperview addSubview: self.audioPasteNavigationController.view ];
	
	// check out pushAudioPasteViewControllerTouchUpInside:
	// to see how the controller is configured and pushed
	// onto the provided navigation controller
}

//------------------------------------------------------------------------------

- (IBAction) pushAudioPasteViewControllerTouchUpInside: (UIButton*) button
{
	// the audio copy and paste controller's need to know
	// that they've been embedded into a parent UINavigationController
	NSArray* paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
	NSString* docsPath = paths.firstObject;
	AudioPasteViewController* audioPasteViewController = [[ AudioPasteViewController alloc ] initWithPath: docsPath ];
	
	// the delegate can handle when to dismiss the UI or
	// show completion messages when pasting is done
	audioPasteViewController.delegate = self;
	
	// controller needs to know that it is using someone
	// else's nav controller instead of it's own
	// this is be a weak reference in case the audio copy
	// view controller goes away
	audioPasteViewController.parentNavigationController = self.audioPasteNavigationController;
	
	// specify if the controller shows a "Done" button
	// some UIs may not want the button if the controller is embedded
	audioPasteViewController.doneButtonHidden = YES;
	
	// now push the audio paste view controller
	[ self.audioPasteNavigationController pushViewController: audioPasteViewController animated: YES ];
}

//------------------------------------------------------------------------------
#pragma mark - AudioCopyViewControllerDelegate
//------------------------------------------------------------------------------

- (void) dismissAudioCopyUI
{
	// if the controller was presented modally or in a pop-over
	// it could be dismissed, but in this sample code just some
	// clean up is done
	[ self cleanUpControllersAndViewsAnimated: YES ];
}

//------------------------------------------------------------------------------
#pragma mark - AudioPasteViewControllerDelegate
//------------------------------------------------------------------------------

- (void) dismissAudioPasteUI
{
	// if the controller was presented modally or in a pop-over
	// it could be dismissed, but in this sample code just some
	// clean up is done
	[ self cleanUpControllersAndViewsAnimated: YES ];
}


//------------------------------------------------------------------------------

- (void) didPaste: (id) player
		   atPath: (NSString*) path
		itemNamed: (NSString*) name
	 withMetaData: (NSDictionary*) meta
{
    NSLog(@"pasted %@",path);
}

- (void) didMultiplePaste: (id) viewcontroller
            fromDirectory: (NSString *) directory
                  atPaths: (NSArray *) paths
             withMetaData: (NSArray *) meta
{
    NSLog(@"Pasted from directory: %@ \n atPaths: %@ \n withMetaData: %@", directory, paths, meta);
}

- (void) didMultiplePaste:(id)viewcontroller
            fromDirectory:(NSString *)directory
                  atPaths:(NSArray *)paths
             withMetaData:(NSArray *)meta
        withGroupMetaData:(NSDictionary *)groupMetaData
{
    NSLog(@"Pasted from directory: %@ \n atPaths: %@ \n withMetaData: %@ \n withGroupDictionary: %@", directory, paths, meta,groupMetaData);
}

- (void) multiplePasteCancelled
{
    NSLog(@"Multipe Paste Cancelled, clean up any left over views");
}

//------------------------------------------------------------------------------
#pragma mark - UIPopoverControllerDelegate
//------------------------------------------------------------------------------

- (void) popoverControllerDidDismissPopover: (
                                              UIPopoverController*) popoverController
{
	// clean up any referenced audio copy or paste controllers
	[ self cleanUpControllersAndViews ];
	
	// clean up the popover controller
	self.presentedPopoverController = nil;
}


- (BOOL)popoverControllerShouldDismissPopover:(UIPopoverController *)popoverController
{
    // This will only let the popover be dismissed when multiple paste is inactive.
    if ( [self.presentedPopoverController.contentViewController isKindOfClass:[AudioPasteViewController class]] )
    {
        return [(AudioPasteViewController *)self.presentedPopoverController.contentViewController didPasteFinish];
    }
    else
    {
        return YES;
    }
}

//------------------------------------------------------------------------------
#pragma mark - UISwitch handling
//------------------------------------------------------------------------------

- (IBAction) desiredStyleControlValueChanged: (id) sender
{
	[ self cleanUpControllersAndViewsAnimated: YES ];
}

//------------------------------------------------------------------------------

@end
