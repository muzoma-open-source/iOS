//
//  Version.swift
//  Muzoma
//
//  Created by Matthew Hopkins on 15/06/2016.
//  Copyright © 2016 Muzoma.com. All rights reserved.
//

import UIKit

/*
 Internal testers. You are not required to supply all metadata in order to invite internal testers to test a prerelease build of your app.
 
 External testers. To enable external users to test a prerelease build of your app, you must supply the following metadata.
 */


public struct VersionDetail
{
    var date:Date
    var title:String
    var shortDescription:String
    var longDescription:String
    var authors:String
    var changes:[String]
}

public struct Version {
    static let VersionHistory: [String: VersionDetail] = [
        // keep in order latest at top
        "3.0.0": VersionDetail( date: Date(dateString: "2019-11-30"), title: "Production version", shortDescription: "Prod",
                                longDescription: "Open source version",  authors: "Matt H",
                                changes: [ "Open source version","Open source version"
            ] ),
        "2.7.0": VersionDetail( date: Date(dateString: "2019-04-28"), title: "Production version", shortDescription: "Prod",
                                longDescription: "Fix for KV image file location change",  authors: "Matt H",
                                changes: [ "Fix for KV image file location change","Fix for KV image file location change"
            ] ),
        "2.6.0": VersionDetail( date: Date(dateString: "2019-03-09"), title: "Production version", shortDescription: "Prod",
                                longDescription: "Added basic midi MMC, Fix import of remote docs",  authors: "Matt H",
                                changes: [ "Added MMC","Fix import of remote docs"
            ] ),
        "2.5.0": VersionDetail( date: Date(dateString: "2019-03-02"), title: "Production version", shortDescription: "Prod",
                                longDescription: "Update midi library to latest",  authors: "Matt H",
                                changes: [ "Update midi library to latest"
            ] ),
        "2.4.0": VersionDetail( date: Date(dateString: "2018-01-12"), title: "Production version", shortDescription: "Prod",
                                longDescription: "Improve editor zooming",  authors: "Matt H",
                                changes: [ "Improve editor zooming"
            ] ),
        "2.3.0": VersionDetail( date: Date(dateString: "2018-01-06"), title: "Production version", shortDescription: "Prod",
                                 longDescription: "Fix for chord pro import issue",  authors: "Matt H",
                                 changes: [ "Fix for chord pro import issue"
            ] ),
        "2.2.52": VersionDetail( date: Date(dateString: "2018-10-18"), title: "Production version", shortDescription: "Prod",
                                 longDescription: "Fixes for fwd and rew when in home screen. Lose the re-sync notifications",  authors: "Matt H",
                                changes: [ "Fixes for fwd and rew when in home screen. Lose the re-sync notifications"
            ] ),
        "2.2.4": VersionDetail( date: Date(dateString: "2018-10-15"), title: "Production version", shortDescription: "Prod",
                                longDescription: "Alert and re-sync on hot plug of audio hardware",  authors: "Matt H",
                                changes: [ "Alert and re-sync on hot plug of audio hardware"
            ] ),
        "2.2.3": VersionDetail( date: Date(dateString: "2018-09-22"), title: "Production version", shortDescription: "Prod",
                                longDescription: "KV download format changed, Link with latest Apple SDK",  authors: "Matt H",
                                changes: [ "KV download format changed", "Link with latest Apple SDK"
            ] ),
        "2.2.2": VersionDetail( date: Date(dateString: "2018-09-14"), title: "Production version", shortDescription: "Prod",
                                longDescription: "Added support for Cymatic UTool2 exports",  authors: "Matt H",
                                changes: [ "Added support for Cymatic UTool2 exports", "Bug fixes for sets issue when sharing"
            ] ),
        "2.2.1": VersionDetail( date: Date(dateString: "2018-09-12"), title: "Production version", shortDescription: "Prod",
                                longDescription: "Added support for Cymatic UTool2 exports",  authors: "Matt H",
                                changes: [ "Added support for Cymatic UTool2 exports", "Added support for Cymatic UTool2 exports", "Added support for Cymatic UTool2 exports"
            ] ),
        "2.2.0": VersionDetail( date: Date(dateString: "2018-09-09"), title: "Production version", shortDescription: "Prod",
                                longDescription: "Added export sets to Cymatic LP16 Device",  authors: "Matt H",
                                changes: [ "Added export sets to Cymatic LP16 Device", "Added export sets to Cymatic LP16 Device", "Added export sets to Cymatic LP16 Device"
            ] ),
        "2.1.1": VersionDetail( date: Date(dateString: "2018-09-02"), title: "Production version", shortDescription: "Prod",
                                longDescription: "KV image files now download from CDN",  authors: "Matt H",
                                changes: [ "KV image files now download from CDN", "KV layout changes caused download issues", "KV layout changes caused download issues"
            ] ),
        "2.1.0": VersionDetail( date: Date(dateString: "2018-08-20"), title: "Production version", shortDescription: "Prod",
            longDescription: "KV layout changes caused download issues",  authors: "Matt H",
            changes: [ "KV layout changes caused download issues", "KV layout changes caused download issues", "KV layout changes caused download issues"
            ] ),
        "2.0.62": VersionDetail( date: Date(dateString: "2018-07-20"), title: "Production version", shortDescription: "Prod",
            longDescription: "iOS11 files app support, Fix for some sets issues, KV https support",  authors: "Matt H",
            changes: [ "iOS11 files app support", "Fix for some sets issues", "KV https support"
            ] ),
        "2.0.61": VersionDetail( date: Date(dateString: "2018-07-12"), title: "Production version", shortDescription: "Prod",
            longDescription: "iOS11 files app support, Fix for some sets issues",  authors: "Matt H",
            changes: [ "iOS11 files app support", "Fix for some sets issues"
            ] ),
        "2.0.6": VersionDetail( date: Date(dateString: "2018-06-29"), title: "Production version", shortDescription: "Prod",
            longDescription: "iOS11 files app support, Fix for some sets issues",  authors: "Matt H",
            changes: [ "iOS11 files app support", "Fix for some sets issues"
            ] ),
        "2.0.5": VersionDetail( date: Date(dateString: "2018-02-09"), title: "Production version", shortDescription: "Prod",
            longDescription: "Fix for KV downloads with special file name characters",  authors: "Matt H",
            changes: [ "Fix for KV downloads"
            ] ),
        "2.0.4": VersionDetail( date: Date(dateString: "2017-10-01"), title: "Beta version", shortDescription: "Prod",
            longDescription: "Fix for KV downloads",  authors: "Matt H",
            changes: [ "Fix for KV downloads"
            ] ),
        "2.0.2": VersionDetail( date: Date(dateString: "2017-09-29"), title: "Production version", shortDescription: "Prod",
            longDescription: "Fix for KV downloads",  authors: "Matt H",
            changes: [ "Fix for KV downloads"
            ] ),
        "2.0.1": VersionDetail( date: Date(dateString: "2017-05-20"), title: "Production version", shortDescription: "Prod",
            longDescription: "Karaoke-version imports - add pitch shifting ability",  authors: "Matt H",
            changes: [ "Karaoke-version imports - add pitch shifting ability"
            ] ),
        "2.0.0": VersionDetail( date: Date(dateString: "2017-04-20"), title: "Production version", shortDescription: "Prod",
            longDescription: "Audio mixer and recording, midi control, AudioShare support, karaoke-version.com supported",  authors: "Matt H",
            changes: [ "Audio mixer and recording added", "Midi control added", "AudioShare support added", "karaoke-version.com support added"
            ] ),
        "1.1.0": VersionDetail( date: Date(dateString: "2017-01-23"), title: "Production version", shortDescription: "Prod",
            longDescription: "Smart line split in editor, Refresh chord pallet from document - button added",  authors: "Matt H",
            changes: [  "Smart line split added in compose editor",
                        "Deleting a set could leave orphans songs, option to delete songs from the set added",
                        "Refresh chord pallet from document - button added"
                        /*"Smarter chord dropping",
                        "Bug re-importing - renaming not working properly - keeping original file in folder - fixed",
                        "Filter pipes and non file symbols everywhere where file names are made",
                        "Fix for some pro format imports",
                        "Refresh editor view properly after text or pro import"*/
            ] ),
        "1.0.9": VersionDetail( date: Date(dateString: "2017-01-19"), title: "Production version", shortDescription: "Prod",
            longDescription: "Configurable zoom level for AirPlayer",  authors: "Matt H",
            changes: [ "Configurable zoom level for AirPlayer",
                "User download tab added",
                "Bug fixes"
                /*
                "Redemption code on downloads page",
                "iPhone editor covered up text",
                "Mark user on download url",
                "Character set in text export",
                "registration not required to buy",
                "multiple Redemption codes on downloads page",
                "automatic fullstops in chord editor on timing edit page",
                "import of text is keeping prefixes",
                "copy paste - formats, multi-line",
                "Extra line spaces in imports",
                "Chord player not working on editor page",
                "Green not always working on timing edit",
                "Chord breaker not working on slash chords or min7s etc"*/
                 ] ),
        "1.0.8": VersionDetail( date: Date(dateString: "2017-01-09"), title: "Production version", shortDescription: "Prod",
            longDescription: "Re-branding, Default backing track to playback on internal hardware",  authors: "Matt H",
            changes: [ "Re-branding", "Default backing track to playback on internal hardware",
                "Option to set or disable tool bar collapsing on the player screen - useful for the smaller screen devices.",
                "Fix for the green bar not extending to the whole length of the playback screen when zoomed right out",
                "Added a small level zoom option available in the app settings to allow more text on a small screen by default",
                "Bug fixes" ] ),
        "1.0.7": VersionDetail( date: Date(dateString: "2017-01-05"), title: "Production version", shortDescription: "Prod",
            longDescription: "Add switches for internal and external audio per track, plus bug fixes",  authors: "Matt H",
            changes: [ "Add switches for internal and external audio per track", "Bug fixes" ] ),
        "1.0.6": VersionDetail( date: Date(dateString: "2016-12-19"), title: "Production version", shortDescription: "Prod",
            longDescription: "Chords play on timing editor, fix issue where leading spaces were truncated on import",  authors: "Matt H",
            changes: [ "Chord playing in timing editor", "fix issue where leading spaces were truncated on import" ] ),
        "1.0.5": VersionDetail( date: Date(dateString: "2016-12-05"), title: "Production version", shortDescription: "Prod",
            longDescription: "Fix web download, optimise editor and import",  authors: "Matt H",
            changes: [ "Better access to online content" ] ),
        "1.0.4": VersionDetail( date: Date(dateString: "2016-12-05"), title: "Production version", shortDescription: "Prod",
            longDescription: "Added ability for repeat play of sets",  authors: "Matt H",
            changes: [ "Better access to online content" ] ),
        "1.0.3": VersionDetail( date: Date(dateString: "2016-12-02"), title: "Beta version", shortDescription: "Beta",
            longDescription: "Optimise home screen. Better access to online content.  Improve editor",  authors: "Matt H",
            changes: [ "Better access to online content" ] ),
        "1.0.2": VersionDetail( date: Date(dateString: "2016-11-19"), title: "Production version", shortDescription: "Prod",
            longDescription: "Improve audio engine, rewind and forward now scrub audio if playing",  authors: "Matt H",
            changes: [ "Improve audio engine" ] ),
        "1.0.1": VersionDetail( date: Date(dateString: "2016-11-13"), title: "Initial production version", shortDescription: "Prod",
            longDescription: "Initial production, trim dependencies",  authors: "Matt H",
            changes: [ "Production readying minor fixings" ] ),
        "1.0.0": VersionDetail( date: Date(dateString: "2016-11-06"), title: "Initial production version", shortDescription: "Prod",
            longDescription: "Initial production version",  authors: "Matt H",
            changes: [ "Production readying minor fixings" ] ),
        "0.9.1": VersionDetail( date: Date(dateString: "2016-11-05"), title: "Beta pre release RC2", shortDescription: "BetaRC2",
            longDescription: "Beta release, optimise doc loading",  authors: "Matt H",
            changes: [ "Doc optimisations" ] ),
        "0.9.0": VersionDetail( date: Date(dateString: "2016-11-03"), title: "Beta pre release", shortDescription: "Beta",
            longDescription: "Beta release, optimise doc loading",  authors: "Matt H",
            changes: [ "Remote registration fixes and functionality updates" ] ),
        "0.6.5": VersionDetail( date: Date(dateString: "2016-11-02"), title: "Testflight release", shortDescription: "Testflight",
            longDescription: "Testflight release pre v1.0 release, add in iBooks help",  authors: "Matt H",
            changes: [ "Remote registration fixes and functionality updates" ] ),
        "0.6.4": VersionDetail( date: Date(dateString: "2016-10-30"), title: "Testflight release", shortDescription: "Testflight",
            longDescription: "Testflight release pre v1.0 release, bug fixes for renames and copies",  authors: "Matt H",
            changes: [ "Remote registration fixes and functionality updates" ] ),
        "0.6.3": VersionDetail( date: Date(dateString: "2016-10-25"), title: "Testflight release", shortDescription: "Testflight",
            longDescription: "Testflight release pre v1.0 release, bug fixes for sets",  authors: "Matt H",
            changes: [ "Remote registration fixes and functionality updates" ] ),
        "0.6.2": VersionDetail( date: Date(dateString: "2016-09-21"), title: "Testflight release", shortDescription: "Testflight with registration",
            longDescription: "Testflight release pre v1.0 release, includes remote registration",  authors: "Matt H",
            changes: [ "Remote registration fixes and functionality updates" ] ),
        "0.6.1": VersionDetail( date: Date(dateString: "2016-09-20"), title: "Testflight release", shortDescription: "Testflight with registration",
            longDescription: "Testflight release pre v1.0 release, includes remote registration",  authors: "Matt H",
            changes: [ "Remote registration fixes and functionality updates" ] ),
        "0.6.0": VersionDetail( date: Date(dateString: "2016-09-01"), title: "Testflight release", shortDescription: "Testflight with registration",
            longDescription: "Testflight release pre v1.0 release, includes remote registration",  authors: "Matt H",
            changes: [ "Added remote registration" ] ),
        "0.5.1": VersionDetail( date: Date(dateString: "2016-08-04"), title: "Testflight release", shortDescription: "Testflight release pre v1.0 release",
            longDescription: "Testflight release pre v1.0 release",  authors: "Matt H",
            changes: [ "Fix version number to allow multiple decimal points" ] ),
        "0.5.0": VersionDetail( date: Date(dateString: "2016-06-20"), title: "Beta release", shortDescription: "Beta release pre v1.0 release",
            longDescription: "Beta release pre v1.0 release",  authors: "Matt H",
            changes: [ "" ] ),
        "0.1.0": VersionDetail( date: Date(dateString: "2015-08-13"), title: "Initial codebase", shortDescription: "Initial codebase",
            longDescription: "Initial codebase", authors: "Matt H",
            changes: [ "" ] )
    ]
    static let DocVersion: String = VersionHistory.sortedKeys({ (key1, key2) -> Bool in
        if( key1 > key2 )
        {
            return true
        }else
        {
            return false
        }
    }).first!

    static let appDescription = "Muzoma is a musical productivity app that works on the iPad and iPhone."  + "\n\r"
        + "If you are an artist, composer, performer, band member, sound engineer, producer, DJ, karaoke author, busker, publisher, or music content creator, some or " + "\n\r"
        + "all of the features of Muzoma will be of interest to you." + "\n\r"
        + "Muzoma allows the organisation, sharing and playback of multi-channel / multi-track and / or stereo backing tracks synchronized with lyric and chord cues " + "\n\r"
        +  "on the device and optionally via Apple Airplay (tm) and / or Muzoma's band share peer to peer feature." + "\n\r"
    + "\n\r"
    + "\n\r"
    +  "With the in-app purchase of the Producer version, you can create, develop and share your own Muzoma content with other Muzoma users.  Muzoma Producer is " + "\n\r"
    +  "designed to be the next step in the chain from your Digital Audio Workstation (DAW) i.e. this is the app you will use after the ProTools, Cubase, " + "\n\r"
    +  "Reason or Ableton* production process." + "\n\r"
    + "\n\r"
    +  "You can take the output from your DAW as 'stems' in MP3 format, import these into Muzoma, include the mix-down as the guide track, include an audio click " + "\n\r"
    +  "track, and add the lyrics and chord cues to the production.  Muzoma Producer works with iCloud (and other cloud services) enabling content to be" + "\n\r"
    + "\n\r"
    +  "easily imported and included in a Muzoma song.  Once created, the song is then ready to share or add to a set for sharing and conveniently on the iPad " + "\n\r"
    +  "or iPhone to use live and in a multi-channel, multi-track situation." + "\n\r"
    + "\n\r"
    +  "Muzoma is unique because it offers multi-channel audio output (including multiple MP3) to popular iOS compatible audio hardware such as the (*) Midas " + "\n\r"
    +  "M32 / Behringer X32, Cymatic Audio LP16 and uTrack24, Antelope Orion 32, Focusrite Scarlett and iTrack and other class compliant audio interfaces all " + "\n\r"
    +  "via the Apple USB camera connection kit which makes it great for playback of in-ear click tracks, missing band member scenarios, virtual sound checks " + "\n\r"
    +  "or just expanding the band with sound effects, exotic instruments, doubled tracks and keyboard sounds." + "\n\r"
    + "\n\r"
    +  "Muzoma Producer includes a song editor for writing lyrics and chord editing.  Once the lyrics and chords are created and associated with a guide track, " + "\n\r"
    +  "it's then simply a case of using the timing editor to associate the chord and lyric events with the song." + "\n\r"
    + "\n\r"
    +  "Other Producer features include:" + "\n\r"
    +  "Import / Export the popular chord pro format as well as text file" + "\n\r"
    +  "Copyright, author and ownership markers" + "\n\r"
    +  "PDF / HTML / Text format export" + "\n\r"
    +  "Air Printing" + "\n\r"
    + "\n\r"
    + "\n\r"
    +  "(*) Brands mentioned are examples of compatibility and the companies mentioned are not directly associated with Muzoma Ltd" + "\n\r"
}
