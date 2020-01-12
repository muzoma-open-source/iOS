/*!
 @header AudioPasteViewController
 A UIViewController subclass that manages the display and interactions for the AudioPaste functionality.  Host apps are encouraged to implement this controller in their applications to quickly (and consistently with other AudioCopy-enabled apps) enable the functionality.
 
 These controllers allow apps to host the AudioCopy and AudioPaste UI in their own UIs.  These controllers will work without requiring the (free) AudioCopy app to be installed, however their utility is greatly improved when it is.
 @copyright 2013 Retronyms
*/

#import <UIKit/UIKit.h>

/*!
 @protocol
 @discussion Delegates can receive messages about what is being pasted, when it is done and when the UI should be dismissed.
 */
@protocol AudioPasteViewControllerDelegate <NSObject>

@optional
/*!
 @method
 @abstract
 @discussion
 @param viewcontroller
 @param path to the file that the user selected in the AudioPasteViewController
 @param name
 @param meta assiocated with the file.  If the AudioCopy app isn't installed, this will be empty.
 @version AudioCopy 2.x
 */
- (void) didPaste: (id) viewcontroller
		   atPath: (NSString*) path
		itemNamed: (NSString*) name
	 withMetaData: (NSDictionary*) meta;


/*!
 @method
 @abstract Multiple paste method for pasting contents of a directory.
 @discussion Implement this method to enable multiple paste.
 @param viewcontroller
 @param directory
 @param paths to the files that the user selected in the AudioPasteViewController
 @param array of dictionaries for the metadata assiocated with the files.  If the AudioCopy app isn't installed, this will be empty.
 @version AudioCopy 3.x
 */
- (void) didMultiplePaste:  (id) viewcontroller
            fromDirectory:  (NSString *) directory
            atPaths:        (NSArray *) paths
            withMetaData:   (NSArray *) meta;

/*!
 @method
 @abstract Multiple paste method for pasting contents of a directory.
 @discussion Implement this method to enable multiple paste.
 @param viewcontroller
 @param directory
 @param paths to the files that the user selected in the AudioPasteViewController
 @param array of dictionaries for the metadata assiocated with the files.  If the AudioCopy app isn't installed, this will be empty.
 @param Root directory meta data for this file group.
 @version AudioCopy 3.x
 */
- (void) didMultiplePaste: (id) viewcontroller
            fromDirectory: (NSString *) directory
                  atPaths: (NSArray *) paths
             withMetaData: (NSArray *) meta
        withGroupMetaData: (NSDictionary *) groupMetaData;

/*!
 @method
 @abstract Called when multiple paste cancel button is pressed
 @discussion Implement this method to handle custom dismiss after cancel
 @version AudioCopy 3.x
 */
- (void) multiplePasteCancelled;

/*!
 @method
 @abstract After paste is completed or canceled this method is called so the AudioPasteViewController can be cleaned up.
 @discussion You can prevent this method from being called by setting dismissAfterPasteComplete to NO.  It's on by default unless the AudioPasteViewController is embedded inside a UINavigationController using parentNavigationController.
 @version AudioCopy 2.x
 */
- (void) dismissAudioPasteUI;


/*!
 @method
 @abstract
 @discussion
 @param pasteToArray
 @param index
 @param channels
 @version AudioCopy 1.x
 */
- (void) getPasteToArrayForAudioPaste: (NSMutableArray*) pasteToArray
								index: (int*) index
							 channels: (int) channels;

/*!
 @method
 @abstract
 @discussion
 @return The current packet
 @version AudioCopy 1.x
 */
- (UInt64) getCurrentPacketForAudioPaste;

/*!
 @method
 @abstract
 @discussion
 @return
 @version AudioCopy 1.x
 */
- (double) getCurrentPositionInSecondsForAudioPaste;

/*!
 @method
 @abstract
 @discussion
 @param channels
 @param index
 @param tempo
 @param packetpos
 @version AudioCopy 1.x
 */
- (void) didSucceedForAudioPaste: (int) channels
						   index: (int) index
						   tempo: (int) tempo
				  packetPosition: (int) packetpos;

/*!
 @method
 @abstract
 @discussion
 @param channels
 @param index
 @version AudioCopy 1.x
 */
- (void) setDataForAudioPaste: (int) channels
						index: (int) index;

/*!
 @method
 @abstract
 @discussion
 @param packetPosition
 @param pastePackets
 @param trackLengthInPackets
 @param channels
 @version AudioCopy 1.x
 */
- (void) audioPasteBlockCompleted: (UInt64*) packetPosition
					   numPackets: (UInt64*) pastePackets
		 totalFileLengthInPackets: (UInt64*) trackLengthInPackets
						 channels: (int) channels;

/*!
 @method
 @abstract
 @discussion
 @param channels
 @param index
 @version AudioCopy 1.x
 */
- (void) setupForAudioPaste: (int) channels
					  index: (int) index;



@end;

/*!
 @class
 @abstract UIViewController subclass to show the AudioPaste UI.
 */
@interface AudioPasteViewController : UIViewController

/*!
 @property
 @abstract The current delegate for this controller.
 */
@property (readwrite,assign) id<AudioPasteViewControllerDelegate> delegate;

/*!
 @property
 @abstract Call the delegate's dismissAudioPasteUI method.
 @discussion Set this to have the delegate's dismissAudioPasteUI method be called when the paste operation has completed.  The default is YES.  Note that if the controller is embedded in a parent UINavigationController, this is ignored.
 */
@property BOOL dismissAfterPasteComplete;

/*!
 @property
 @abstract Hide the controller's Done button
 @discussion Set this to control when the controller's Done button is shown.  This should be set after the controller is created and before it's view has been added to a superview.  The default is NO.
 */
@property (nonatomic) BOOL doneButtonHidden;

/*!
 @property
 @abstract Additional metadata about the audio file.
 */
@property (readwrite, retain) NSDictionary* meta;

/*!
 @property
 @abstract Name of the application 
 */
@property (readonly) NSString* name;

/*!
 @property parentNavigationController
 @abstract Parent navigation this controller is embedded
 @discussion If the controller is to be embedded in an existing UINavigationController, this property must be set so that the controller can properly manage child controllers.  The default is NO, meaning the controller will create and manage it's own UINavigationController.
 */
@property (assign, nonatomic) UINavigationController* parentNavigationController;

/*!
 @property
 @abstract Path to the current audio file.
 @return Returns the path specified in initWithPath: or nil if no path was specified.
 */
@property (readonly) NSString* path;

/*!
 @method
 @abstract Initialize the controller pointing at the directory with the pasted files.
 @param path Path to directory of pasted files
 */
- (id) initWithPath: (NSString*) path;

/*!
 @method
 @abstract Show or hide the controller's Done button
 @discussion Allows the host to specify if the controller has a Done button which can be set appropriaetly for how the controller is displayed.  For example, if the controller is in a UIPopoverController, then the Done button should be show.  If the controller is embedded in a UINavigationController, then the Done button should be hidden.
 @deprecated Use the readwrite property doneButtonHidden instead.
 */
- (void) showDoneButton: (BOOL) doShowDoneButton;

/*!
 @method
 @abstract Returns the status of the multiple paste process
 @discussion Dismissing a UIPopoverController during the multiple paste process will cause a crash. You can use this in UIPopoverControllerDelegate's popoverControllerShouldDismissPopover method to prevent this. See Example.
 */
- (BOOL) didPasteFinish;


@end

