/*!
 @header AudioCopyPaste
 TO DO
 Explain the difference between inter-app audio and the general pasteboard.
 @author Dan Walton
 @copyright 2013 Retronyms
 */

#import <UIKit/UIPasteboard.h>
#import <AudioToolbox/AudioFile.h>
#import <AudioToolbox/ExtendedAudioFile.h>
#import <MobileCoreServices/UTCoreTypes.h>

/*!
 @enum
 */
typedef enum InterAppLaunchStyle : NSUInteger {
    kLaunchStyleDefault = 0,
    kLaunchStyleInterAppAttempt,
    kLaunchStyleRedirectOnly
} InterAppLaunchStyle;

/*!
 @protocol
 @discussion Delegates will be informed when the paste operation has completed.
 */
@protocol AudioPasteCallbackDelegate

/*!
 @method
 @abstract Informs a delegate when a paste operation has completed, including packet information, length and channels.
 @param packetPosition
 @param pastePackets
 @param trackLengthInPackets
 @param channels
 */
- (void) audioPasteBlockCompleted: (UInt64*) packetPosition
					   numPackets: (UInt64*) pastePackets
		 totalFileLengthInPackets: (UInt64*) trackLengthInPackets
						 channels: (int) channels;

@end

/*!
 @struct
 @abstract Structure representing the WAV file format header.
 @discussion Note that WAV is currently the only supported format.
 */
typedef struct
{
	char	ChunkID[4];
	int32_t	ChunkSize;
	char	Format[4];
	char	Subchunk1ID[4];
	int32_t	Subchunk1Size;
	int16_t	AudioFormat;
	int16_t	NumChannels;
	int32_t	SampleRate;
	int32_t	ByteRate;
	int16_t	BlockAlign;
	int16_t	BitsPerSample;
	char	Subchunk2ID[4];
	int32_t	Subchunk2Size;
} wavefileheader;

/*!
 @class AudioCopyPaste
 @var mHeader Header of the audio file data.
 */
@interface AudioCopyPaste : NSObject
{
	wavefileheader* mHeader;
}

/*!
 @method
 @abstract Sets the launch style of the app.
 @discussion By default we will try to launch the AudioCopy app as an "inter-app" audio node.  If that fails or is otherwise impractical (if you publish a node) we will launch using an urlscheme.  You can force the redirect method here.
 @param launchStyle The desired launch style.
 @return
 */
+ (void) setAudioCopyAppLaunchStyle: (InterAppLaunchStyle) launchStyle;

/*!
 @method
 @abstract Returns the current launch style specified in setAudioCopyAppLaunchStyle:
 @return The current launch style
 */
+ (InterAppLaunchStyle) audioCopyAppLaunchStyle;


/*!
 @method
 @abstract Returns the current URL scheme set by setURLScheme:
 @return The current URLScheme
 */
+ (NSString*) URLScheme;

/*!
 @method
 @abstract Set the
 @discussion Use when the app is not launched as an "inter-app" audio node.
 @param scheme
 */
+ (void) setURLScheme: (NSString*) scheme;

/*!
 @method
 @version AudioCopy 1.x
 @deprecated This method is no longer required for AudioCopy and has no effect.
 */
+ (void) initPasteBoard;


/*!
 @method
 @version AudioCopy 3
 @discussion incase you need to get the affiliate code.
*/
+ (NSString *)affiliateCode;

/*!
 @method
 @version AudioCopy 3
 @discussion set affiliate code in order to be credit with sales
 */
+ (void)setAffiliateCode:(NSString *)aic;


/*!
 @method
 @abstract Called by AudioCopySDK to ensure basic settings are correct.
*/
+ (void)verifyConfiguration;

/*!
 @method
 @abstract Prints the app's current AudioCopy configuration to the console.
 */
+ (void) debugConfiguration;

/*!
 @method
 @abstract Returns an url that can be used to show the content store
 @return the content store launch url.  pass to canOpenUrl to launch.  canOpenUrl returns NO if AudioCopy isn't installed.
 */
+ (NSURL *) contentStoreLaunchURL;

/*!
 @method
 @abstract Returns parameters that can be passed to the storekit to show the AudioCopy download.
 @return a dictionary that can be passed to the [StoreKitProductViewController loadProductWithParameters:skparams completionBlock:nil] method.
 */
+ (NSDictionary *) parametersForStoreKit;

/*!
 @method
 @abstract
 @discussion Use this function if you are not using any UI and need a one time function to call with no setup.
 @param path The audio file to be copied
 @param nameornil The application name
 @param meta Additional key/value pairs including tempo, duration and channels to better describe what is being copied.
 @return YES for success, NO for a fail
 */
+ (BOOL) copyAudioFileAtPath: (NSString*) path
					withName: (NSString*) nameornil
					withMeta: (NSDictionary*) meta;

/*!
 @method
 @abstract Copy the audio at the specified path to the OS pasteboard.
 @param path Path to the audio file to be pasted.
 @return
 */
+ (BOOL) copyAudioFileAtPathToGeneralPasteboard: (NSString*) path;

/*!
 @method
 @abstract Copy an audio file from the specified path, including additional metadata.
 @discussion Similar to copyAudioFileAtPath.
 @param path Path to the audio file to be copied.
 @param meta Additional information about the audio file being copied.
 @return
 */
+ (BOOL) basicCopyMappedAudioFileAtPath: (NSString*) path
							   withMeta: (NSDictionary*) meta;

/*!
 @method
 @abstract Simple version of pasting the audio to a destination.
 @param path Path to the where the audio file will be pasted.
 @return
 */
+ (BOOL) basicPasteToFileAtPath: (NSString*) path;

/*!
 @method
 @abstract Copy one or more files, with offset and loops, from the OS pasteboard.
 @discussion Use this function if you are not using any UI and need a one time function to call with no setup.  
 @param filepaths Paths to where the audio file on the OS pasteboard will be copied.
 @param temppath Path to writable directory where the audio files are copied first.
 @param loopCount Number of times to loop the original file when pasting.
 @param offset Number of bytes into the destination audio file to start pasting.
 @param pasteDelegate Delegate to be called when the paste operation is completed.
 @return YES for success, NO for a fail
 */
+ (BOOL) pasteAudioFileFromGeneralPasteboard: (NSMutableArray*) filepaths
								  orTempPath: (NSString*) temppath
							   withLoopCount: (int) loopCount
									atOffset: (UInt64) offset
							   pasteDelegate: (id) pasteDelegate;

/*!
 @method
 @abstract Returns a bool indicating if there is data on the General Pasteboard
 @return YES there is data, NO there is not.
 */
+ (BOOL) hasGeneralPasteboardData;

@end
