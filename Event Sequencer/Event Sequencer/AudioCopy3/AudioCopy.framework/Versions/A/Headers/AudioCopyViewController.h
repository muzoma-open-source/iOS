/*!
 @header AudioCopyViewController
 A UIViewController subclass that manages the display and interactions for the AudioCopy functionality.  Host apps are encouraged to implement this controller in their applications to quickly (and consistently with other AudioCopy-enabled apps) enable the functionality.
 
 These controllers allow apps to host the AudioCopy and AudioPaste UI in their own UIs.  These controllers will work without requiring the (free) AudioCopy app to be installed, however their utility is greatly improved when it is.
 @copyright 2013 Retronyms
 */

#import <UIKit/UIKit.h>

/*!
 @protocol
 @discussion Delegates can receive messages about what is being copied, when it is done and when the UI should be dismissed.
 */
@protocol AudioCopyViewControllerDelegate <NSObject>

@optional

/*!
 @method
 @abstract Tells the delegate when to dismiss the AudioCopy UI.
 @version AudioCopy 2.x
 */
- (void) dismissAudioCopyUI;

/*!
 @method
 @abstract Tells the delegate when the copy operation has completed.
 @param player
 @version AudioCopy 2.x
 */
- (void) didCopy: (id) player;

/*!
 @method
 @abstract Allows the controller to ask the host the path of the audio file being copied.
 @param sender
 @return The path
 @version AudioCopy 1.x
 */
- (NSString*) pathForAudioCopy: (id) sender;

/*!
 @method
 @abstract Allows the controller to ask the host the current copying operation's progress.
 @discussion This is used by the controller to update it's own progress UI.
 @param sender
 @version AudioCopy 1.x
 */
- (float) getRenderProgressForAudioCopy: (id) sender;

/*!
 @method
 @abstract Allows the controller to ask the host if the copy operation is complete.
 @param sender
 @version AudioCopy 1.x
 */
- (BOOL) isRenderDoneForAudioCopy: (id) sender;

/*!
 @method
 @abstract Allows the controller to ask the host if the copy operation is possible.
 @param sender
 @version AudioCopy 1.x
 */
- (BOOL) shouldRenderForAudioCopy: (id) sender;

/*!
 @method
 @abstract Allows the controller to ask the host what the audio file's tempo is.
 @discussion This is used by the controller to render the audio file at a particular tempo.
 @param sender
 @version AudioCopy 1.x
 */
- (int) getTempoForAudioCopy: (id) sender;

/*!
 @method
 @abstract Allows the controller to ask the host for it's application name.
 @param sender
 @version AudioCopy 1.x
 */
- (NSString*) getSenderForAudioCopy: (id) sender;

@end;

@interface AudioCopyViewController : UIViewController 

/*!
 @property
 @abstract The current delegate for this controller.
 */
@property (assign, readwrite) id<AudioCopyViewControllerDelegate> delegate;

/*!
 @property
 @abstract Hide the controller's Done button
 @discussion Set this to control when the controller's Done button is shown.  This should be set after the controller is created and before it's view has been added to a superview.  The default is NO.
 */
@property (nonatomic) BOOL doneButtonHidden;

/*!
 @property parentNavigationController
 @abstract Parent navigation this controller is embedded
 @discussion If the controller is to be embedded in an existing UINavigationController, this property must be set so that the controller can properly manage child controllers.  The default is NO, meaning the controller will create and manage it's own UINavigationController.
 */
@property (assign, nonatomic) UINavigationController* parentNavigationController;

/*!
 @property
 @return The path that was specified in initWithPath: or nil.
 */
@property (readwrite, retain) NSString* path;

/*!
 @method
 @abstract
 @discussion Unexpected results if the path specified is nil.
 @param path The destination directory for the copy
 @return An instance of the controller
 */
- (id) initWithPath: (NSString*) path;

/*!
 @method
 @abstract
 @discussion Unexpected results if the path specified is nil.
 @param path The destination directory for the copy
 @param meta Additional key/value pairs including tempo, duration and channels to better describe what is being copied.
 @return An instance of the controller
 */
- (id) initWithPath: (NSString*) path andMetaData: (NSMutableDictionary*) meta;

/*!
 @method
 @abstract Show or hide the controller's Done button
 @discussion Allows the host to specify if the controller has a Done button which can be set appropriaetly for how the controller is displayed.  For example, if the controller is in a UIPopoverController, then the Done button should be show.  If the controller is embedded in a UINavigationController, then the Done button should be hidden.
 @deprecated Use the readwrite property doneButtonHidden instead.
 */
- (void) showDoneButton: (BOOL) doShowDoneButton;

@end
