//
//  Use this file to import your target's public headers that you would like to expose to Swift.
//

#define Event_Sequencer_MidiCallback_h

#import <Foundation/Foundation.h>
#import <AudioToolbox/AudioToolbox.h>
typedef void (^OnCallback)(const MIDIPacketList *packetList);

@interface MIDIReadProcCallback : NSObject

+ (void (*)(const MIDIPacketList *pktlist, void *readProcRefCon, void *srcConnRefCon))midiReadProc;
+ (void)setOnCallback:(OnCallback)onCallback;

@end