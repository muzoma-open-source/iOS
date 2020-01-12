//------------------------------------------------------------------------------
//  ViewController.h
//  Example
//
//  Copyright (c) 2013 retronyms. All rights reserved.
//
//------------------------------------------------------------------------------

#import <UIKit/UIKit.h>
#import "AudioCopy/AudioCopyViewController.h"
#import "AudioCopy/AudioPasteViewController.h"

//------------------------------------------------------------------------------

@interface ViewController : UIViewController <AudioCopyViewControllerDelegate,
											  AudioPasteViewControllerDelegate,
											  UIPopoverControllerDelegate>

//------------------------------------------------------------------------------

@property (nonatomic, weak) IBOutlet UIView* desiredSuperview;
@property (nonatomic, weak) IBOutlet UISegmentedControl* desiredStyleControl;

//------------------------------------------------------------------------------

@property (nonatomic, strong) IBOutlet UINavigationController* audioCopyNavigationController;
@property (nonatomic, strong) IBOutlet UINavigationController* audioPasteNavigationController;

//------------------------------------------------------------------------------

//@property (nonatomic, strong) UIPopoverController* presentedPopoverController;


//------------------------------------------------------------------------------

- (void) presentAudioCopyViewControllerModally;
- (void) presentAudioCopyViewControllerInPopover;
- (void) presentAudioCopyViewControllerInSuperview;
- (void) presentAudioCopyViewControllerInNavigationController;

//------------------------------------------------------------------------------

- (void) presentAudioPasteViewControllerModally;
- (void) presentAudioPasteViewControllerInPopover;
- (void) presentAudioPasteViewControllerInSuperview;
- (void) presentAudioPasteViewControllerInNavigationController;

//------------------------------------------------------------------------------

@end
