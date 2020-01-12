//
//  UserRegistrationTableViewController.swift
//  Muzoma
//
//  Created by Matthew Hopkins on 15/08/2016.
//  Copyright © 2016 Muzoma.com. All rights reserved.
//
//  Allow the user to set up their personal preferences and to register with Muzoma
//

import UIKit
import Alamofire
import SwaggerUserRegSite


class UserRegistration
{
    // properties
    internal var hasRegisteredLocally:Bool
    {
        set( newVal )
        {
            UserDefaults.standard.set( newVal, forKey: "hasRegisteredLocally_preference")
            UserDefaults.standard.synchronize()
        }
        
        get
        {
            UserDefaults.standard.synchronize()
            let val = UserDefaults.standard.value(forKey: "hasRegisteredLocally_preference") as! Bool?
            return(val != nil ? val! : false)
        }
    }
    
    internal var hasRegisteredOnMuzoma:Bool
    {
        set( newVal )
        {
            UserDefaults.standard.set( newVal, forKey: "hasRegisteredOnMuzoma_preference")
            UserDefaults.standard.synchronize()
        }
        
        get
        {
            UserDefaults.standard.synchronize()
            let val = UserDefaults.standard.value(forKey: "hasRegisteredOnMuzoma_preference") as! Bool?
            return(val != nil ? val! : false)
        }
    }
    
    internal var hasRegisteredOnMuzomaCom:Bool
    {
        set( newVal )
        {
            UserDefaults.standard.set( newVal, forKey: "hasRegisteredOnMuzomaCom_preference")
            UserDefaults.standard.synchronize()
        }
        
        get
        {
            UserDefaults.standard.synchronize()
            let val = UserDefaults.standard.value(forKey: "hasRegisteredOnMuzomaCom_preference") as! Bool?
            return(val != nil ? val! : false)
        }
    }
    
    
    internal var userId:String?
    {
        set( newVal )
        {
            UserDefaults.standard.set( newVal, forKey: "userId_preference" )
            UserDefaults.standard.synchronize()
        }
        
        get
        {
            UserDefaults.standard.synchronize()
            let val = UserDefaults.standard.value(forKey: "userId_preference") as! String?
            return(val)
        }
    }
    
    internal var appleProducerPurchasedTXReceipt:String?
    {
        set( newVal )
        {
            UserDefaults.standard.set( newVal, forKey: "appleProducerPurchasedTXReceipt_preference" )
            UserDefaults.standard.synchronize()
        }
        
        get
        {
            UserDefaults.standard.synchronize()
            let val = UserDefaults.standard.value(forKey: "appleProducerPurchasedTXReceipt_preference") as! String?
            return(val)
        }
    }
    
    
    internal var communityName:String?
    {
        set( newVal )
        {
            UserDefaults.standard.set( newVal, forKey: "communityName_preference" )
        }
        
        get
        {
            let val = UserDefaults.standard.value(forKey: "communityName_preference") as! String?
            return(val)
        }
    }
    
    internal var firstName:String?
    {
        set( newVal )
        {
            UserDefaults.standard.set( newVal, forKey: "firstName_preference" )
        }
        
        get
        {
            let val = UserDefaults.standard.value(forKey: "firstName_preference") as! String?
            return(val)
        }
    }
    
    internal var middleName:String?
    {
        set( newVal )
        {
            UserDefaults.standard.set( newVal, forKey: "middleName_preference" )
        }
        
        get
        {
            let val = UserDefaults.standard.value(forKey: "middleName_preference") as! String?
            return(val)
        }
    }
    
    
    internal var lastName:String?
    {
        set( newVal )
        {
            UserDefaults.standard.set( newVal, forKey: "lastName_preference" )
        }
        
        get
        {
            let val = UserDefaults.standard.value(forKey: "lastName_preference") as! String?
            return(val)
        }
    }
    
    internal var emailAddr:String?
    {
        set( newVal )
        {
            UserDefaults.standard.set( newVal, forKey: "emailAddr_preference" )
        }
        
        get
        {
            let val = UserDefaults.standard.value(forKey: "emailAddr_preference") as! String?
            return(val)
        }
    }
    
    var _originalPassword:String! = ""
    internal var originalPassword:String?
    {
        set( newVal )
        {
            _originalPassword = newVal
        }
        
        get
        {
            return(_originalPassword )
        }
    }
    
    var _originalPasswordHint:String! = ""
    internal var originalPasswordHint:String?
    {
        set( newVal )
        {
            _originalPasswordHint = newVal
        }
        
        get
        {
            return(_originalPasswordHint )
        }
    }
    
    internal var password:String?
    {
        set( newVal )
        {
            UserDefaults.standard.set( newVal, forKey: "password_preference" )
        }
        
        get
        {
            let val = UserDefaults.standard.value(forKey: "password_preference") as! String?
            return(val)
        }
    }
    
    internal var _verifyPassword:String! = nil
    
    internal var verifyPassword:String?
    {
        
        set( newVal )
        {
            _verifyPassword = newVal
        }
        
        get
        {
            let val = _verifyPassword
            return(val)
        }
    }
    
    internal var passwordReminderPhrase:String?
    {
        set( newVal )
        {
            UserDefaults.standard.set( newVal, forKey: "passwordReminderPhrase_preference" )
        }
        
        get
        {
            let val = UserDefaults.standard.value(forKey: "passwordReminderPhrase_preference") as! String?
            return(val)
        }
    }
    
    internal var OKToEmail:Bool
    {
        set( newVal )
        {
            UserDefaults.standard.set( newVal, forKey: "OKToEmail_preference")
        }
        
        get
        {
            let val = UserDefaults.standard.value(forKey: "OKToEmail_preference") as! Bool?
            return(val != nil ? val! : true)
        }
    }
    
    internal var emailVerified:Bool
    {
        set( newVal )
        {
            UserDefaults.standard.set( newVal, forKey: "emailVerified_preference")
        }
        
        get
        {
            let val = UserDefaults.standard.value(forKey: "emailVerified_preference") as! Bool?
            return(val != nil ? val! : false)
        }
    }
    
    internal var artist:String?
    {
        set( newVal )
        {
            UserDefaults.standard.set( newVal, forKey: "artist_preference" )
        }
        
        get
        {
            let val = UserDefaults.standard.value(forKey: "artist_preference") as! String?
            return(val)
        }
    }
    
    internal var author:String?
    {
        set( newVal )
        {
            UserDefaults.standard.set( newVal, forKey: "author_preference" )
        }
        
        get
        {
            let val = UserDefaults.standard.value(forKey: "author_preference") as! String?
            return(val)
        }
    }
    
    internal var copyright:String?
    {
        set( newVal )
        {
            UserDefaults.standard.set( newVal, forKey: "copyright_preference" )
        }
        
        get
        {
            let val = UserDefaults.standard.value(forKey: "copyright_preference") as! String?
            return(val)
        }
    }
    
    internal var publisher:String?
    {
        set( newVal )
        {
            UserDefaults.standard.set( newVal, forKey: "publisher_preference" )
        }
        
        get
        {
            let val = UserDefaults.standard.value(forKey: "publisher_preference") as! String?
            return(val)
        }
    }
    
    internal var commentsToMuzoma:String?
    {
        set( newVal )
        {
            UserDefaults.standard.set( newVal, forKey: "commentsToMuzoma_preference" )
        }
        
        get
        {
            let val = UserDefaults.standard.value(forKey: "commentsToMuzoma_preference") as! String?
            return(val)
        }
    }
    
    
    
    internal var iAmABandMember:Bool
    {
        set( newVal )
        {
            UserDefaults.standard.set( newVal, forKey: "iAmABandMember_preference")
        }
        
        get
        {
            let val = UserDefaults.standard.value(forKey: "iAmABandMember_preference") as! Bool?
            return(val != nil ? val! : false)
        }
    }
    
    internal var iAmABassPlayer:Bool
    {
        set( newVal )
        {
            UserDefaults.standard.set( newVal, forKey: "iAmABassPlayer_preference")
        }
        
        get
        {
            let val = UserDefaults.standard.value(forKey: "iAmABassPlayer_preference") as! Bool?
            return(val != nil ? val! : false)
        }
    }
    
    
    internal var iAmADrummer:Bool
    {
        set( newVal )
        {
            UserDefaults.standard.set( newVal, forKey: "iAmADrummer_preference")
        }
        
        get
        {
            let val = UserDefaults.standard.value(forKey: "iAmADrummer_preference") as! Bool?
            return(val != nil ? val! : false)
        }
    }
    
    
    internal var iAmAStudent:Bool
    {
        set( newVal )
        {
            UserDefaults.standard.set( newVal, forKey: "iAmAStudent_preference")
        }
        
        get
        {
            let val = UserDefaults.standard.value(forKey: "iAmAStudent_preference") as! Bool?
            return(val != nil ? val! : false)
        }
    }
    
    
    internal var iAmATeacher:Bool
    {
        set( newVal )
        {
            UserDefaults.standard.set( newVal, forKey: "iAmATeacher_preference")
        }
        
        get
        {
            let val = UserDefaults.standard.value(forKey: "iAmATeacher_preference") as! Bool?
            return(val != nil ? val! : false)
        }
    }
    
    
    internal var iAmAComposer:Bool
    {
        set( newVal )
        {
            UserDefaults.standard.set( newVal, forKey: "iAmAComposer_preference")
        }
        
        get
        {
            let val = UserDefaults.standard.value(forKey: "iAmAComposer_preference") as! Bool?
            return(val != nil ? val! : false)
        }
    }
    
    
    internal var iAmAMusician:Bool
    {
        set( newVal )
        {
            UserDefaults.standard.set( newVal, forKey: "iAmAMusician_preference")
        }
        
        get
        {
            let val = UserDefaults.standard.value(forKey: "iAmAMusician_preference") as! Bool?
            return(val != nil ? val! : false)
        }
    }
    
    
    internal var iAmAProducer:Bool
    {
        set( newVal )
        {
            UserDefaults.standard.set( newVal, forKey: "iAmAProducer_preference")
        }
        
        get
        {
            let val = UserDefaults.standard.value(forKey: "iAmAProducer_preference") as! Bool?
            return(val != nil ? val! : false)
        }
    }
    
    
    internal var iAmAVocalist:Bool
    {
        set( newVal )
        {
            UserDefaults.standard.set( newVal, forKey: "iAmAVocalist_preference")
        }
        
        get
        {
            let val = UserDefaults.standard.value(forKey: "iAmAVocalist_preference") as! Bool?
            return(val != nil ? val! : false)
        }
    }
    
    
    internal var iAmAPerformer:Bool
    {
        set( newVal )
        {
            UserDefaults.standard.set( newVal, forKey: "iAmAPerformer_preference")
        }
        
        get
        {
            let val = UserDefaults.standard.value(forKey: "iAmAPerformer_preference") as! Bool?
            return(val != nil ? val! : false)
        }
    }
    
    
    internal var iAmAPublisher:Bool
    {
        set( newVal )
        {
            UserDefaults.standard.set( newVal, forKey: "iAmAPublisher_preference")
        }
        
        get
        {
            let val = UserDefaults.standard.value(forKey: "iAmAPublisher_preference") as! Bool?
            return(val != nil ? val! : false)
        }
    }
    
    
    internal var iAmASoloArtist:Bool
    {
        set( newVal )
        {
            UserDefaults.standard.set( newVal, forKey: "iAmASoloArtist_preference")
        }
        
        get
        {
            let val = UserDefaults.standard.value(forKey: "iAmASoloArtist_preference") as! Bool?
            return(val != nil ? val! : false)
        }
    }
    
    
    internal var iAmACoverArtist:Bool
    {
        set( newVal )
        {
            UserDefaults.standard.set( newVal, forKey: "iAmACoverArtist_preference")
        }
        
        get
        {
            let val = UserDefaults.standard.value(forKey: "iAmACoverArtist_preference") as! Bool?
            return(val != nil ? val! : false)
        }
    }
    
    
    internal var iAmAGuitarPlayer:Bool
    {
        set( newVal )
        {
            UserDefaults.standard.set( newVal, forKey: "iAmAGuitarPlayer_preference")
        }
        
        get
        {
            let val = UserDefaults.standard.value(forKey: "iAmAGuitarPlayer_preference") as! Bool?
            return(val != nil ? val! : false)
        }
    }
    
    
    internal var iAmAStreetArtist:Bool
    {
        set( newVal )
        {
            UserDefaults.standard.set( newVal, forKey: "iAmAStreetArtist_preference")
        }
        
        get
        {
            let val = UserDefaults.standard.value(forKey: "iAmAStreetArtist_preference") as! Bool?
            return(val != nil ? val! : false)
        }
    }
    
    
    internal var iAmASoundEngineer:Bool
    {
        set( newVal )
        {
            UserDefaults.standard.set( newVal, forKey: "iAmASoundEngineer_preference")
        }
        
        get
        {
            let val = UserDefaults.standard.value(forKey: "iAmASoundEngineer_preference") as! Bool?
            return(val != nil ? val! : false)
        }
    }
    
    
    internal var iAmAWorshipArtist:Bool
    {
        set( newVal )
        {
            UserDefaults.standard.set( newVal, forKey: "iAmAWorshipArtist_preference")
        }
        
        get
        {
            let val = UserDefaults.standard.value(forKey: "iAmAWorshipArtist_preference") as! Bool?
            return(val != nil ? val! : false)
        }
    }
    
    
    internal var iAmAKeyboardPlayer:Bool
    {
        set( newVal )
        {
            UserDefaults.standard.set( newVal, forKey: "iAmAKeyboardPlayer_preference")
        }
        
        get
        {
            let val = UserDefaults.standard.value(forKey: "iAmAKeyboardPlayer_preference") as! Bool?
            return(val != nil ? val! : false)
        }
    }
    
    
    internal var iAmOriginalArtist:Bool
    {
        set( newVal )
        {
            UserDefaults.standard.set( newVal, forKey: "iAmOriginalArtist_preference")
        }
        
        get
        {
            let val = UserDefaults.standard.value(forKey: "iAmOriginalArtist_preference") as! Bool?
            return(val != nil ? val! : false)
        }
    }
    
    init()
    {
        UserDefaults.standard.synchronize()
    }
    
    // http://torquemag.io/2015/08/working-with-users-via-the-wordpress-rest-api/
    // e.g. http://www.muzoma.com/wp-json/wp/v2/users
    // http://www.muzoma.com/wp-json/wp/v2/users?mattyh
    func saveAndVerifyOnMuzomaCom()
    {
        self.hasRegisteredOnMuzomaCom = true
    }
    
    // initial save
    func saveToMuzoma()
    {
        self.hasRegisteredLocally = true
        let registration:RegisterBindingModel = RegisterBindingModel()
        
        registration.communityName = self.communityName
        registration.email = self.emailAddr
        registration.password = self.password
        registration.confirmPassword = self.verifyPassword
        registration.passwordReminderPhrase = self.passwordReminderPhrase
        registration.firstName = self.firstName
        registration.middleName = self.middleName
        registration.lastName = self.lastName
        registration.allowMuzomaContact = self.OKToEmail
        registration.artist = self.artist
        registration.author = self.author
        registration.copyright = self.copyright
        registration.publisher = self.publisher
        registration.appleProducerPurchasedTXReceipt = self.appleProducerPurchasedTXReceipt
        registration.commentsToMuzoma = self.commentsToMuzoma
        
        // TODO: Set up the key

        // register - call out to our backend
        AccountAPI.accountPostRegister(model: registration) { (data, error) in
            if( error != nil  ) // we got an error back
            {
                var errorMessage:String! = nil
                var errors = [String]()
                
                //print( " data: \(data) \nerror: \(error)" )
                // return results in string
                let errorTxt = data as! String?
                if( errorTxt != nil )
                {
                    let json = errorTxt?.parseJSONString!
                    
                    if( JSONSerialization.isValidJSONObject(json!) )
                    {
                        errorMessage = json!["Message"] as! String?
                        if let modelState = json!["ModelState"] as? [String: [AnyObject?]] {
                            for prop in modelState
                            {
                                for val in prop.1
                                {
                                    errors.append(val as! String)
                                }
                            }
                        }
                    }
                }
                
                var errorString = errorMessage != nil ? errorMessage + "\n" : "Sorry, there was an error communicating with Muzoma, please check your network settings and retry later."
                for err in errors
                {
                    errorString += err + "\n"
                }
                
                NotificationCenter.default.post(name: Notification.Name(rawValue: "RegistrationError"), object: errorString)
            }
            else
            {
                self.hasRegisteredOnMuzoma = true
                NotificationCenter.default.post(name: Notification.Name(rawValue: "RegistrationOK"), object: self)
            }
        }
    }
    
    // delta update
    func updateMuzoma() -> Bool
    {
        self.hasRegisteredLocally = true
        let registration:RegisterBindingModel = RegisterBindingModel()
        
        registration.communityName = self.communityName
        registration.email = self.emailAddr
        registration.password = self.password
        if( self.verifyPassword == nil )
        {
            self.verifyPassword = self.password
        }
        registration.confirmPassword = self.verifyPassword
        registration.passwordReminderPhrase = self.passwordReminderPhrase
        registration.firstName = self.firstName
        registration.middleName = self.middleName
        registration.lastName = self.lastName
        registration.allowMuzomaContact = self.OKToEmail
        registration.artist = self.artist
        registration.author = self.author
        registration.copyright = self.copyright
        registration.publisher = self.publisher
        registration.appleProducerPurchasedTXReceipt = self.appleProducerPurchasedTXReceipt
        registration.commentsToMuzoma = self.commentsToMuzoma
        registration.emailVerified = self.emailVerified
        
        // TODO: Set up the key

        var ret:Bool = false
        
        if( self.password != nil &&  self.emailAddr != nil )
        {
            // build parameters
            let parameters = [  "grant_type": "password",
                                "username": self.emailAddr!,
                                "password": self.password!
            ]
            
            // build request
            var token = ""
            // token grab uses form encoding
            let tokenURLString =  SwaggerClientAPI.basePath + "/token"
            Alamofire.request(tokenURLString, method: .post, parameters: parameters, encoding: URLEncoding.default).responseJSON { response in
                
                response.result.ifSuccess
                    {
                        print("Validation Successful")
                        if let JSON = response.result.value as! NSDictionary?  {
                            print(JSON)
                            
                            if( JSON["error"] != nil )
                            {
                                var error = "There was an error restoring your details\n"
                                
                                error += (JSON["error"] as! String?)! + "\n"
                                
                                if( JSON["error_description"] != nil )
                                {
                                    error += (JSON["error_description"] as! String?)!
                                }
                                NotificationCenter.default.post(name: NSNotification.Name(rawValue: "RegistrationError"), object: error)
                            }
                            else
                            {
                                token = JSON["access_token"] as! String
                                SwaggerClientAPI.customHeaders["Authorization"] = "Bearer " + token
                                AccountAPI.accountPostRegistrationInfo(model: registration, completion: { (data, error) in
                                    if( error != nil  ) // we got an error back
                                    {
                                        var errorMessage:String! = nil
                                        var errors = [String]()
                                        
                                        //print( " data: \(data) \nerror: \(error)" )
                                        
                                        // return results in string
                                        let errorTxt = data as! String?
                                        if( errorTxt != nil )
                                        {
                                            let json = errorTxt?.parseJSONString!
                                            
                                            if( JSONSerialization.isValidJSONObject(json!) )
                                            {
                                                errorMessage = json!["Message"] as! String?
                                                if let modelState = json!["ModelState"] as? [String: [AnyObject?]] {
                                                    for prop in modelState
                                                    {
                                                        for val in prop.1
                                                        {
                                                            //print( val  as! String )
                                                            errors.append(val as! String)
                                                        }
                                                    }
                                                }
                                            }
                                        }
                                        
                                        var errorString = errorMessage != nil ? errorMessage + "\n" : "There was an error communicating with Muzoma to update your registration details, please check your network settings and retry later."
                                        for err in errors
                                        {
                                            errorString += err + "\n"
                                        }
                                        
                                        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "RegistrationError"), object: "Sorry, registration details could not be updated \(errorString)\nplease try later")
                                    } else
                                    {
                                        if( data != nil ) // looks good
                                        {
                                            //self.mergeParamsFromBackEnd(data!)
                                            ret = true
                                            NotificationCenter.default.post(name: NSNotification.Name(rawValue: "RegistrationOK"), object: self)
                                        }
                                        else // no good
                                        {
                                            NotificationCenter.default.post(name: NSNotification.Name(rawValue: "RegistrationError"), object: "Sorry, registration details were not found at this time, please try later")
                                        }
                                    }
                                })
                            }
                        }
                }
                
            }
        }
        else
        {
            NotificationCenter.default.post(name: Notification.Name(rawValue: "RegistrationError"), object: "Email and password must be set!")
        }
        
        return( ret )
    }
    
    
    // restore from apple store transaction id - already paid
    func restoreCredentialsFromTransaction()
    {
        var txId = Date().dateDDMM
        txId += self.appleProducerPurchasedTXReceipt!
        // TODO: Add string for Key
        AccountAPI.accountGetUserDetailsByTransactionId(apiKey: "", transactionId: txId ) { (data, error) in
            if( data != nil && data?.email != nil && data?.registrationId != nil ) // looks good
            {
                _ = self.mergeParamsFromBackEnd( data! )
                NotificationCenter.default.post(name: Notification.Name(rawValue: "RegistrationOK"), object: self)
            }
            else
            {
                NotificationCenter.default.post(name: Notification.Name(rawValue: "RegistrationError"), object: "Could not retrieve registration details stored for you, please register with Muzoma")
            }
        }
    }
    
    // allow user to retrieve their registration credentials
    func restoreCredentialsFromUserAndPassword() -> Bool
    {
        var ret:Bool = false
        
        if( self.password != nil &&  self.emailAddr != nil )
        {
            // build parameters
            let parameters = [  "grant_type": "password",
                                "username": self.emailAddr!,
                "password": self.password!
            ]
            
            // token grab uses form encoding
            let tokenURLString =  SwaggerClientAPI.basePath + "/token"
            Alamofire.request(tokenURLString, method: .post, parameters: parameters, encoding: URLEncoding.default).responseJSON { response in
                
                response.result.ifSuccess
                    {
                        print("Validation Successful")
                        if let JSON = response.result.value as! NSDictionary? {
                            print(JSON)
                            
                            if( JSON["error"] != nil )
                            {
                                var error = "There was an error restoring your details\n"
                                
                                error += (JSON["error"] as! String?)! + "\n"
                                
                                if( JSON["error_description"] != nil )
                                {
                                    error += (JSON["error_description"] as! String?)!
                                }
                                NotificationCenter.default.post(name: NSNotification.Name(rawValue: "RegistrationError"), object: error)
                            }
                            else
                            {
                                let token = JSON["access_token"] as! String
                                SwaggerClientAPI.customHeaders["Authorization"] = "Bearer " + token
         
                                AccountAPI.accountGetRegistrationInfo { (data, error) in
                                    if( data != nil && data?.email != nil && data?.registrationId != nil ) // looks good
                                    {
                                        if( self.mergeParamsFromBackEnd(data!) ) // need to re-save
                                        {
                                            _ = self.updateMuzoma()
                                        }
                                        else
                                        {
                                            NotificationCenter.default.post(name: NSNotification.Name(rawValue: "RegistrationOK"), object: self)
                                        }
                                        ret = true
                                    }
                                    else // no good
                                    {
                                        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "RegistrationError"), object: "Sorry, registration details were not found at this time, please try later")
                                    }
                                }
                            }
                        }
                }
            }
        }
        else
        {
            NotificationCenter.default.post(name: Notification.Name(rawValue: "RegistrationError"), object: "Email and password must be set!")
        }
        
        return( ret )
    }
    
    // allow password reset
    func resetPasswordForUser() -> Bool
    {
        var ret:Bool = false
        
        if( self.emailAddr != nil )
        {
            let emailToken = Date().dateDDMM + self.emailAddr!
            // Todo: set key
            AccountAPI.accountGetForgotPassword( apiKey: "", emailAddress: emailToken, completion: { (data, error) in
                if( data != nil  ) // looks good
                {
                    //self.mergeParamsFromBackEnd(data!)
                    ret = true
                    NotificationCenter.default.post(name: Notification.Name(rawValue: "ForgotPasswordRequestSent"), object: self)
                }
                else // no good
                {
                    NotificationCenter.default.post(name: Notification.Name(rawValue: "ForgotPasswordRequestSentError"), object: "Sorry, the request to reset your password could not be sent, please try later")
                }
            })
        }
        else
        {
            NotificationCenter.default.post(name: Notification.Name(rawValue: "ForgotPasswordRequestSentError"), object: "Email must be set!")
        }
        
        return( ret )
    }
    
    // resend the user a confirmation email
    func resendConfirmationEmailFromUserAndPassword() -> Bool
    {
        var ret:Bool = false
        
        if( self.password != nil &&  self.emailAddr != nil )
        {
            // build parameters
            let parameters = [  "grant_type": "password",
                                "username": self.emailAddr!,
                                "password": self.password!
            ]
            
            // build request
            var token = ""
            // token grab uses form encoding
            let tokenURLString =  SwaggerClientAPI.basePath + "/token"
            Alamofire.request(tokenURLString, method: .post, parameters: parameters, encoding: URLEncoding.default).responseJSON {  response in
                response.result.ifSuccess
                    {
                        print("Validation Successful")
                        if let JSON = response.result.value as! NSDictionary?  {
                            print(JSON)
                            
                            if( JSON["error"] != nil )
                            {
                                var error = "There was an error restoring your details\n"
                                
                                error += (JSON["error"] as! String?)! + "\n"
                                
                                if( JSON["error_description"] != nil )
                                {
                                    error += (JSON["error_description"] as! String?)!
                                }
                                NotificationCenter.default.post(name: NSNotification.Name(rawValue: "RegistrationError"), object: error)
                            }
                            else
                            {
                                token = JSON["access_token"] as! String
                                SwaggerClientAPI.customHeaders["Authorization"] = "Bearer " + token
                                
                                let emailToken = Date().dateDDMM + self.emailAddr!
                                // TODO: set key
                                AccountAPI.accountGetResendConfirmationEmail(apiKey: "", emailAddress: emailToken, completion: { (data, error) in
                                    if( data != nil ) // looks good
                                    {
                                        ret = true
                                        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "ConfirmationEmailSent"), object: self)
                                    }
                                    else // no good
                                    {
                                        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "ConfirmationEmailSendError"), object: "Sorry, the email could not be sent, please try later")
                                    }
                                })
                            }
                        }
                }
            }
        }
        else
        {
            NotificationCenter.default.post(name: Notification.Name(rawValue: "RegistrationError"), object: "Email and password must be set!")
        }
        
        return( ret )
    }
    
    // allow the user to change their password
    func changePassword() -> Bool
    {
        var ret:Bool = false
        
        if( self.originalPassword == nil )
        {
            self.originalPassword = self.password // could be fresh install, will prompt if this is wrong
        }
        
        if( self.password != nil && self.originalPassword != nil && self.emailAddr != nil )
        {
            // build parameters
            let parameters = [  "grant_type": "password",
                                "username": self.emailAddr!,
                                "password": self.originalPassword!
            ]
            
            // build request
            var token = ""
            // token grab uses form encoding
            let tokenURLString =  SwaggerClientAPI.basePath + "/token"
            Alamofire.request(tokenURLString, method: .post, parameters: parameters, encoding: URLEncoding.default).responseJSON { response in
                response.result.ifSuccess
                    {
                        print("Validation Successful")
                        if let JSON = response.result.value as! NSDictionary? {
                            print(JSON)
                            
                            if( JSON["error"] != nil )
                            {
                                var error = "There was an error changing your password\n"
                                
                                error += (JSON["error"] as! String?)! + "\n"
                                
                                if( JSON["error_description"] != nil )
                                {
                                    error += (JSON["error_description"] as! String?)!
                                }
                                NotificationCenter.default.post(name: NSNotification.Name(rawValue: "AccountChangePasswordErrorOriginalPWWrong"), object: error)
                            }
                            else
                            {
                                token = JSON["access_token"] as! String
                                SwaggerClientAPI.customHeaders["Authorization"] = "Bearer " + token
                                
                                let changePW = ChangePasswordBindingModel()
                                
                                changePW.oldPassword = self.originalPassword
                                changePW.newPassword = self.password
                                changePW.confirmPassword = self.verifyPassword
                                changePW.passwordReminderPhrase = self.passwordReminderPhrase
                                
                                AccountAPI.accountPostChangePassword(model: changePW, completion: { (data, error) in
                                    if( error != nil  ) // we got an error back
                                    {
                                        var errorMessage:String! = nil
                                        var errors = [String]()
                                        
                                        // return results in string
                                        let errorTxt = data as! String?
                                        if( errorTxt != nil )
                                        {
                                            let json = errorTxt?.parseJSONString!
                                            
                                            if( JSONSerialization.isValidJSONObject(json!) )
                                            {
                                                errorMessage = json!["Message"] as! String?
                                                if let modelState = json!["ModelState"] as? [String: [AnyObject?]] {
                                                    for prop in modelState
                                                    {
                                                        for val in prop.1
                                                        {
                                                            errors.append(val as! String)
                                                        }
                                                    }
                                                }
                                            }
                                        }
                                        
                                        var errorString = errorMessage != nil ? errorMessage + "\n" : "There was an error communicating with Muzoma to update your registration details, please check your network settings and retry later."
                                        for err in errors
                                        {
                                            errorString += err + "\n"
                                        }
                                        
                                        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "AccountChangePasswordError"), object: "Sorry, there was an error setting the password: \(errorString)")
                                    }
                                    else if( data != nil ) // looks good
                                    {
                                        ret = true
                                        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "AccountChangePasswordOK"), object: self)
                                    }
                                    else // no good
                                    {
                                        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "AccountChangePasswordError"), object: "Sorry, the password could not be sent, please try later")
                                    }
                                })
                            }
                        }

                        response.result.ifFailure {
                            NotificationCenter.default.post(name: NSNotification.Name(rawValue: "AccountChangePasswordError"), object: "Sorry, the password could not be sent")
                            
                        }
                }
            }
        }
        else
        {
            NotificationCenter.default.post(name: Notification.Name(rawValue: "AccountChangePasswordError"), object: "Email and password must be set!")
        }
        
        return( ret )
    }
    
    // merge existing details from server
    func mergeParamsFromBackEnd( _ model:RegisterBindingModel ) -> Bool
    {
        var needReSave:Bool = false
        if( model.appleProducerPurchasedTXReceipt == nil && self.appleProducerPurchasedTXReceipt != nil ) // need to update our tx id
        {
            needReSave = true
        }
        else
        {
            self.appleProducerPurchasedTXReceipt = model.appleProducerPurchasedTXReceipt
        }
        self.artist = model.artist
        self.author = model.author
        self.commentsToMuzoma = model.commentsToMuzoma
        self.communityName = model.communityName
        self.copyright = model.copyright
        self.emailAddr = model.email
        self.emailVerified = model.emailVerified == nil ? false : model.emailVerified!
        self.firstName = model.firstName
        self.middleName = model.middleName
        self.hasRegisteredLocally = true
        self.hasRegisteredOnMuzoma = true
        self.lastName = model.lastName
        self.OKToEmail = model.allowMuzomaContact == nil ? false : model.allowMuzomaContact!
        self.passwordReminderPhrase = model.passwordReminderPhrase
        self.publisher = model.publisher
        self.userId = model.registrationId
        
        self.iAmABandMember   =       model.iAmABandMember == nil ? false : model.iAmABandMember!
        self.iAmABassPlayer   =       model.iAmABassPlayer == nil ? false : model.iAmABassPlayer!
        self.iAmADrummer   =          model.iAmADrummer == nil ? false : model.iAmADrummer!
        self.iAmAStudent   =          model.iAmAStudent == nil ? false : model.iAmAStudent!
        self.iAmATeacher   =          model.iAmATeacher == nil ? false : model.iAmATeacher!
        self.iAmAComposer   =         model.iAmAComposer == nil ? false : model.iAmAComposer!
        self.iAmAMusician   =         model.iAmAMusician == nil ? false : model.iAmAMusician!
        self.iAmAProducer   =         model.iAmAProducer == nil ? false : model.iAmAProducer!
        self.iAmAVocalist   =         model.iAmAVocalist == nil ? false : model.iAmAVocalist!
        self.iAmAPerformer   =        model.iAmAPerformer == nil ? false : model.iAmAPerformer!
        self.iAmAPublisher   =        model.iAmAPublisher == nil ? false : model.iAmAPublisher!
        self.iAmASoloArtist   =       model.iAmASoloArtist == nil ? false : model.iAmASoloArtist!
        self.iAmACoverArtist   =      model.iAmACoverArtist == nil ? false : model.iAmACoverArtist!
        self.iAmAGuitarPlayer   =     model.iAmAGuitarPlayer == nil ? false : model.iAmAGuitarPlayer!
        self.iAmAStreetArtist   =     model.iAmAStreetArtist == nil ? false : model.iAmAStreetArtist!
        self.iAmASoundEngineer   =    model.iAmASoundEngineer == nil ? false : model.iAmASoundEngineer!
        self.iAmAWorshipArtist   =    model.iAmAWorshipArtist == nil ? false : model.iAmAWorshipArtist!
        self.iAmAKeyboardPlayer   =   model.iAmAKeyboardPlayer == nil ? false : model.iAmAKeyboardPlayer!
        self.iAmOriginalArtist   =    model.iAmOriginalArtist == nil ? false : model.iAmOriginalArtist!
        
        return( needReSave )
    }
}



// class to handle the UI side of the registration details
class UserRegistrationTableViewController: UITableViewController, UITextFieldDelegate {
    
    let nc = _gNC// NSNotificationCenter.defaultCenter()
    
    override func viewDidAppear(_ animated: Bool) {
        nc.addObserver(self, selector: #selector(UserRegistrationTableViewController.registrationOK(_:)), name: NSNotification.Name(rawValue: "RegistrationOK"), object: nil)
        nc.addObserver(self, selector: #selector(UserRegistrationTableViewController.registrationError(_:)), name: NSNotification.Name(rawValue: "RegistrationError"), object: nil)
        nc.addObserver(self, selector: #selector(UserRegistrationTableViewController.confirmationEmailSent(_:)), name: NSNotification.Name(rawValue: "ConfirmationEmailSent"), object: nil)
        nc.addObserver(self, selector: #selector(UserRegistrationTableViewController.confirmationEmailSendError(_:)), name: NSNotification.Name(rawValue: "ConfirmationEmailSendError"), object: nil)
        nc.addObserver(self, selector: #selector(UserRegistrationTableViewController.forgotPasswordRequestSent(_:)), name: NSNotification.Name(rawValue: "ForgotPasswordRequestSent"), object: nil)
        nc.addObserver(self, selector: #selector(UserRegistrationTableViewController.forgotPasswordRequestSentError(_:)), name: NSNotification.Name(rawValue: "ForgotPasswordRequestSentError"), object: nil)
        nc.addObserver(self, selector: #selector(UserRegistrationTableViewController.accountChangePasswordOK(_:)), name: NSNotification.Name(rawValue: "AccountChangePasswordOK"), object: nil)
        nc.addObserver(self, selector: #selector(UserRegistrationTableViewController.accountChangePasswordError(_:)), name: NSNotification.Name(rawValue: "AccountChangePasswordError"), object: nil)
        nc.addObserver(self, selector: #selector(UserRegistrationTableViewController.accountChangePasswordErrorOriginalPWWrong(_:)), name: NSNotification.Name(rawValue: "AccountChangePasswordErrorOriginalPWWrong"), object: nil)
        
        return super.viewDidAppear(animated)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        nc.removeObserver( self, name: NSNotification.Name(rawValue: "RegistrationOK"), object: nil )
        nc.removeObserver( self, name: NSNotification.Name(rawValue: "RegistrationError"), object: nil )
        nc.removeObserver( self, name: NSNotification.Name(rawValue: "ConfirmationEmailSent"), object: nil )
        nc.removeObserver( self, name: NSNotification.Name(rawValue: "ConfirmationEmailSendError"), object: nil )
        nc.removeObserver( self, name: NSNotification.Name(rawValue: "ForgotPasswordRequestSent"), object: nil )
        nc.removeObserver( self, name: NSNotification.Name(rawValue: "ForgotPasswordRequestSentError"), object: nil )
        nc.removeObserver( self, name: NSNotification.Name(rawValue: "AccountChangePasswordOK"), object: nil )
        nc.removeObserver( self, name: NSNotification.Name(rawValue: "AccountChangePasswordError"), object: nil )
        nc.removeObserver( self, name: NSNotification.Name(rawValue: "AccountChangePasswordErrorOriginalPWWrong"), object: nil )
        
        
        return( super.viewDidDisappear(animated) )
    }
    
    @objc func registrationOK(_ notification: Notification) {
        
        DispatchQueue.main.async(execute: {
            // register on the wordpress site
            self.reg.saveAndVerifyOnMuzomaCom()
            
            self.runControlStateLogic()
            
            self.butRegister.setTitle("Registered", for: UIControl.State())
            self.regToScreen() // might have just been restored.
            self.tableView.reloadData()
            
            // ok
            let alert = UIAlertController(title: "Registration", message: self.reg.emailVerified ? "Thanks for registering with Muzoma" : "Registration sent\nThanks for registering, an email will arrive shortly (allow 5 to 10 minutes).\nPlease check your email and validate your email address to complete the process", preferredStyle: UIAlertController.Style.alert )
            
            alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: { (action: UIAlertAction!) in
                //print("Handle Ok logic here")
            }))
            // must dispatch as more than one might be trying to display
            DispatchQueue.main.async(execute: {
                self.present(alert, animated: true, completion: nil)
            })
        })
    }
    
    @objc func registrationError(_ notification: Notification) {
        DispatchQueue.main.async(execute: {
            self.runControlStateLogic()
            var errorText = ""
            if( notification.object is String )
            {
                errorText = notification.object as! String
            }
            
            let alert = UIAlertController(title: "Registration", message: errorText, preferredStyle: UIAlertController.Style.alert )
            
            alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: { (action: UIAlertAction!) in
                self.butRegister.isEnabled = true
                self.butRegister.setTitle("Save and Verify On Muzoma.com", for: UIControl.State())
            }))
            // must dispatch as more than one might be trying to display
            DispatchQueue.main.async(execute: {
                self.present(alert, animated: true, completion: nil)
            })
        })
    }
    
    
    @objc func confirmationEmailSent(_ notification: Notification) {
        DispatchQueue.main.async(execute: {
            self.runControlStateLogic()
            
            let alert = UIAlertController(title: "Registration", message: "Email request sent OK", preferredStyle: UIAlertController.Style.alert )
            
            alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: { (action: UIAlertAction!) in
                
            }))
            // must dispatch as more than one might be trying to display
            DispatchQueue.main.async(execute: {
                self.present(alert, animated: true, completion: nil)
            })
        })
    }
    
    
    @objc func confirmationEmailSendError(_ notification: Notification) {
        DispatchQueue.main.async(execute: {
            self.runControlStateLogic()
            var errorText = ""
            if( notification.object is String )
            {
                errorText = notification.object as! String
            }
            
            let alert = UIAlertController(title: "Registration", message: errorText, preferredStyle: UIAlertController.Style.alert )
            
            alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: { (action: UIAlertAction!) in
                
            }))
            // must dispatch as more than one might be trying to display
            DispatchQueue.main.async(execute: {
                self.present(alert, animated: true, completion: nil)
            })
        })
    }
    
    
    @objc func forgotPasswordRequestSent(_ notification: Notification) {
        DispatchQueue.main.async(execute: {
            self.runControlStateLogic()
            
            let alert = UIAlertController(title: "Registration", message: "Password reset request sent OK\nPlease check your email", preferredStyle: UIAlertController.Style.alert )
            
            alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: { (action: UIAlertAction!) in
                
            }))
            // must dispatch as more than one might be trying to display
            DispatchQueue.main.async(execute: {
                self.present(alert, animated: true, completion: nil)
            })
        })
    }
    
    
    @objc func forgotPasswordRequestSentError(_ notification: Notification) {
        DispatchQueue.main.async(execute: {
            self.runControlStateLogic()
            var errorText = ""
            if( notification.object is String )
            {
                errorText = notification.object as! String
            }
            
            let alert = UIAlertController(title: "Registration", message: errorText, preferredStyle: UIAlertController.Style.alert )
            
            alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: { (action: UIAlertAction!) in
                self.butRegister.isEnabled = true
                self.butRegister.setTitle("Save and Verify On Muzoma.com", for: UIControl.State())
            }))
            // must dispatch as more than one might be trying to display
            DispatchQueue.main.async(execute: {
                self.present(alert, animated: true, completion: nil)
            })
        })
    }
    
    
    @objc func accountChangePasswordOK(_ notification: Notification) {
        
        DispatchQueue.main.async(execute: {
            // register on the wordpress site
            self.reg.saveAndVerifyOnMuzomaCom()
            
            self.runControlStateLogic()
            
            self.butRegister.setTitle("Registered", for: UIControl.State())
            
            // ok
            let alert = UIAlertController(title: "Registration", message: "Password changed OK", preferredStyle: UIAlertController.Style.alert )
            
            alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: { (action: UIAlertAction!) in
                //print("Handle Ok logic here")
            }))
            // must dispatch as more than one might be trying to display
            DispatchQueue.main.async(execute: {
                self.present(alert, animated: true, completion: nil)
            })
        })
    }
    
    @objc func accountChangePasswordError(_ notification: Notification) {
        DispatchQueue.main.async(execute: {
            self.tfPassword.text = self.reg.originalPassword
            self.tfVerifyPassword.text = self.reg.originalPassword
            
            self.runControlStateLogic()
            var errorText = ""
            if( notification.object is String )
            {
                errorText = notification.object as! String
            }
            
            let alert = UIAlertController(title: "Registration", message: errorText, preferredStyle: UIAlertController.Style.alert )
            
            alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: { (action: UIAlertAction!) in
                
            }))
            // must dispatch as more than one might be trying to display
            DispatchQueue.main.async(execute: {
                self.present(alert, animated: true, completion: nil)
            })
        })
    }
    
    @objc func accountChangePasswordErrorOriginalPWWrong(_ notification: Notification) {
        DispatchQueue.main.async(execute: {
            self.runControlStateLogic()

            var inputTextFieldPassword: UITextField?
            
            //Create the AlertController
            let actionSheetController: UIAlertController = UIAlertController(title: "Registration Password", message: "To change passwords, please enter your current password, or the password sent by the reset password procedure here:", preferredStyle: .alert)
            
            //Create and add the Cancel action
            let cancelAction: UIAlertAction = UIAlertAction(title: "Cancel", style: .cancel) { action -> Void in
                //Do some stuff
            }
            actionSheetController.addAction(cancelAction)
            
            //Create and an option action
            let nextAction: UIAlertAction = UIAlertAction(title: "OK", style: .default) { action -> Void in
                //Do some other stuff
                self.reg.originalPassword = inputTextFieldPassword?.text
                _ = self.reg.changePassword()
            }
            actionSheetController.addAction(nextAction)
            
            //Add a text field
            actionSheetController.addTextField { textField -> Void in
                inputTextFieldPassword = textField
                inputTextFieldPassword?.isSecureTextEntry = true
                inputTextFieldPassword?.text = ""
            }
            
            //Present the AlertController
            // must dispatch as more than one might be trying to display
            DispatchQueue.main.async(execute: {
                self.present(actionSheetController, animated: true, completion: nil)
            })
        })
    }

    @IBAction func editButtonClicked(_ sender: AnyObject) {
        goEditMode()
    }
    
    @IBOutlet weak var butEdit: UIButton!
    @IBOutlet weak var labHelpText: UILabel!
    @IBOutlet weak var tfCommunityName: UITextField!
    @IBOutlet weak var tfFirstName: UITextField!
    @IBOutlet weak var tfMiddleName: UITextField!
    @IBOutlet weak var tfLastName: UITextField!
    @IBOutlet weak var tfEmailAddress: UITextField!
    @IBOutlet weak var swEmailOK: UISwitch!
    @IBOutlet weak var tfArtist: UITextField!
    @IBOutlet weak var tfAuthor: UITextField!
    @IBOutlet weak var tfCopyright: UITextField!
    @IBOutlet weak var tfPublisher: UITextField!
    @IBOutlet weak var tfPassword: UITextField!
    @IBOutlet weak var tfPasswordHint: UITextField!
    @IBOutlet weak var tfVerifyPassword: UITextField!
    @IBOutlet weak var edCommentsToMuzoma: UITextView!
    @IBOutlet weak var butValidateEmail: UIButton!
    @IBOutlet weak var butRegister: UIButton!
    let reg = UserRegistration()
    
    @IBOutlet weak var butChangePassword: UIButton!
    
    @IBOutlet weak var butResendRegEmail: UIButton!
    
    
    @IBAction func forgotPasswordClicked(_ sender: AnyObject) {
        resetPasswordClicked(sender)
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {   //delegate method
        textField.resignFirstResponder()
        return true
    }
    
    @IBAction func communityNameChanged(_ sender: AnyObject) {
        reg.communityName = tfCommunityName.text
    }
    
    @IBAction func firstNameChanged(_ sender: AnyObject) {
        reg.firstName = tfFirstName.text
    }
    
    @IBAction func middleNameChanged(_ sender: AnyObject) {
        reg.middleName = tfMiddleName.text
    }
    
    @IBAction func lastNameChanged(_ sender: AnyObject) {
        reg.lastName = tfLastName.text
    }
    
    @IBAction func emailSwitchChanged(_ sender: AnyObject) {
        reg.OKToEmail = swEmailOK.isOn
    }
    
    @IBAction func emailAddressChanged(_ sender: AnyObject) {
        reg.emailAddr = tfEmailAddress.text
    }
    
    @IBAction func passwordHintChanged(_ sender: AnyObject) {
        reg.passwordReminderPhrase = tfPasswordHint.text
    }
    
    @IBAction func artistChanged(_ sender: AnyObject) {
        reg.artist = tfArtist.text
    }
    
    @IBAction func authorChanged(_ sender: AnyObject) {
        reg.author = tfAuthor.text
    }
    
    @IBAction func copyrightChanged(_ sender: AnyObject) {
        reg.copyright = tfCopyright.text
    }
    
    @IBAction func publisherChanged(_ sender: AnyObject) {
        reg.publisher = tfPublisher.text
    }
    
    @IBAction func passwordChanged(_ sender: AnyObject) {
        reg.password = tfPassword.text
    }
    
    @IBAction func verifyPasswordChanged(_ sender: AnyObject) {
        reg.verifyPassword = tfVerifyPassword.text
    }
    
    @IBOutlet weak var butIAlreadyRegistered: UIButton!
    
    @IBAction func iAlreadyRegisteredClick(_ sender: AnyObject) {
        var inputTextFieldEmail: UITextField?
        var inputTextFieldPassword: UITextField?
        
        //Create the AlertController
        let actionSheetController: UIAlertController = UIAlertController(title: "Restore Registration", message: "Please enter your email address followed by the password you created when registering", preferredStyle: .alert)
        
        //Create and add the Cancel action
        let cancelAction: UIAlertAction = UIAlertAction(title: "Cancel", style: .cancel) { action -> Void in
            //Do some stuff
        }
        actionSheetController.addAction(cancelAction)
        
        //Create and an option action
        let nextAction: UIAlertAction = UIAlertAction(title: "OK", style: .default) { action -> Void in
            //Do some other stuff
            self.reg.emailAddr = inputTextFieldEmail?.text
            self.reg.password = inputTextFieldPassword?.text
            self.reg.verifyPassword = inputTextFieldPassword?.text
            self.tfEmailAddress.text = self.reg.emailAddr
            self.tfPassword.text = self.reg.verifyPassword
            self.tfVerifyPassword.text = self.reg.verifyPassword
            _ = self.reg.restoreCredentialsFromUserAndPassword()
        }
        actionSheetController.addAction(nextAction)
        
        //Add a text field
        actionSheetController.addTextField { textField -> Void in
            // you can use this text field
            inputTextFieldEmail = textField
            inputTextFieldEmail?.text = self.reg.emailAddr
            inputTextFieldEmail?.placeholder = "Email address"
        }
        
        //Add a text field
        actionSheetController.addTextField { textField -> Void in
            // you can use this text field
            inputTextFieldPassword = textField
            inputTextFieldPassword?.isSecureTextEntry = true
            inputTextFieldPassword?.text = self.reg.password
            inputTextFieldPassword?.placeholder = "Password"
        }
        
        //Present the AlertController
        self.present(actionSheetController, animated: true, completion: nil)

    }
    
    
    @IBAction func resendRegEmailPressed(_ sender: AnyObject) {
        var inputTextFieldEmail: UITextField?
        var inputTextFieldPassword: UITextField?
        
        //Create the AlertController
        let actionSheetController: UIAlertController = UIAlertController(title: "Resend Registration Email", message: "Please confirm your email address followed by the password you created when registering", preferredStyle: .alert)
        
        //Create and add the Cancel action
        let cancelAction: UIAlertAction = UIAlertAction(title: "Cancel", style: .cancel) { action -> Void in
            //Do some stuff
        }
        actionSheetController.addAction(cancelAction)
        
        //Create and an option action
        let nextAction: UIAlertAction = UIAlertAction(title: "OK", style: .default) { action -> Void in
            //Do some other stuff
            self.reg.emailAddr = inputTextFieldEmail?.text
            self.reg.password = inputTextFieldPassword?.text
            self.reg.verifyPassword = inputTextFieldPassword?.text
            self.tfEmailAddress.text = self.reg.emailAddr
            self.tfPassword.text = self.reg.verifyPassword
            self.tfVerifyPassword.text = self.reg.verifyPassword
            _ = self.reg.resendConfirmationEmailFromUserAndPassword()
        }
        actionSheetController.addAction(nextAction)
        
        //Add a text field
        actionSheetController.addTextField { textField -> Void in
            // you can use this text field
            inputTextFieldEmail = textField
            inputTextFieldEmail?.text = self.reg.emailAddr
        }
        
        //Add a text field
        actionSheetController.addTextField { textField -> Void in
            // you can use this text field
            inputTextFieldPassword = textField
            inputTextFieldPassword?.isSecureTextEntry = true
            inputTextFieldPassword?.text = self.reg.password
        }
        
        //Present the AlertController
        self.present(actionSheetController, animated: true, completion: nil)
        
    }
    
    @IBAction func verifyOnWebSite(_ sender: AnyObject) {
        butRegister.isEnabled = false
        butRegister.becomeFirstResponder()
        tfCommunityName.resignFirstResponder()
        tfFirstName.resignFirstResponder()
        tfMiddleName.resignFirstResponder()
        tfLastName.resignFirstResponder()
        tfEmailAddress.resignFirstResponder()
        swEmailOK.resignFirstResponder()
        tfArtist.resignFirstResponder()
        tfAuthor.resignFirstResponder()
        tfCopyright.resignFirstResponder()
        tfPublisher.resignFirstResponder()
        tfPassword.resignFirstResponder()
        tfVerifyPassword.resignFirstResponder()
        tfPasswordHint.resignFirstResponder()
        edCommentsToMuzoma.resignFirstResponder()
        self.reg.commentsToMuzoma = edCommentsToMuzoma.text
        
        // do we update the existing or is it a new registration?
        if( butRegister.titleLabel?.text == "Update" )
        {
            // update details
            butRegister.setTitle("Updating...", for: UIControl.State())
            labHelpText.text = "Updating details..."
            _ = self.reg.updateMuzoma()
        }
        else
        {
            butRegister.setTitle("Registering...", for: UIControl.State())
            labHelpText.text = "Registering details..."
            self.reg.saveToMuzoma()
        }
    }
    
    // reset password button
    @IBAction func resetPasswordClicked(_ sender: AnyObject) {
        var inputTextFieldEmail: UITextField?
        
        //Create the AlertController
        let actionSheetController: UIAlertController = UIAlertController(title: "Reset Password", message: "Please check or enter your email address, press Reset Password and an email will be sent to you with further details", preferredStyle: .alert)
        
        //Create and add the Cancel action
        let cancelAction: UIAlertAction = UIAlertAction(title: "Cancel", style: .cancel) { action -> Void in
            //Do some stuff
        }
        actionSheetController.addAction(cancelAction)
        
        //Create and an option action
        let nextAction: UIAlertAction = UIAlertAction(title: "Reset Password", style: .default) { action -> Void in
            //Do some other stuff
            self.reg.emailAddr = inputTextFieldEmail?.text
            _ = self.reg.resetPasswordForUser()
        }
        actionSheetController.addAction(nextAction)
        
        //Add a text field
        actionSheetController.addTextField { textField -> Void in
            // you can use this text field
            inputTextFieldEmail = textField
            inputTextFieldEmail?.text = self.reg.emailAddr
            inputTextFieldEmail?.placeholder = "email address"
        }
        
        //Present the AlertController
        self.present(actionSheetController, animated: true, completion: nil)
    }
    
    
    @IBAction func changePasswordPressed(_ sender: AnyObject) {
        butCancelPasswordChange.isHidden = false
        butChangePassword.isHidden = true
        butSaveChangePassword.isEnabled = true
        reg.originalPassword = reg.password
        reg.originalPasswordHint = reg.passwordReminderPhrase
        tfPassword.isEnabled = true
        tfPassword.becomeFirstResponder()
        tfVerifyPassword.isEnabled = true
        tfPasswordHint.isEnabled = true
        butEdit.isEnabled = false
    }
    
    @IBOutlet weak var butSaveChangePassword: UIButton!
    @IBAction func saveChangePasswordPressed(_ sender: AnyObject) {
        // make the change
        //butChangePassword.enabled = true
        butCancelPasswordChange.isHidden = true
        butSaveChangePassword.isEnabled = false
        butChangePassword.isHidden = false
        tfPassword.isEnabled = false
        tfVerifyPassword.isEnabled = false
        tfPasswordHint.isEnabled = false
        butEdit.isEnabled = true
        _ = reg.changePassword()
        runControlStateLogic()
    }
    
    @IBAction func cancelPasswordChange(_ sender: AnyObject) {
        butCancelPasswordChange.isHidden = true
        butSaveChangePassword.isEnabled = false
        butChangePassword.isHidden = false
        tfPassword.isEnabled = false
        tfVerifyPassword.isEnabled = false
        tfPasswordHint.isEnabled = false
        butEdit.isEnabled = true
        reg.password = reg.originalPassword
        reg.passwordReminderPhrase = reg.originalPasswordHint
        tfPassword.text = reg.password
        tfVerifyPassword.text = reg.password
        tfPasswordHint.text = reg._originalPasswordHint
        runControlStateLogic()
    }
    
    @IBOutlet weak var butCancelPasswordChange: UIButton!
    
    
    func regToScreen()
    {
        tfCommunityName.text = reg.communityName
        tfFirstName.text = reg.firstName
        tfMiddleName.text = reg.middleName
        tfLastName.text = reg.lastName
        tfEmailAddress.text = reg.emailAddr
        swEmailOK.isOn = reg.OKToEmail
        tfArtist.text = reg.artist
        tfAuthor.text = reg.author
        tfCopyright.text = reg.copyright
        tfPublisher.text = reg.publisher
        tfPassword.text = reg.password
        tfPasswordHint.text = reg.passwordReminderPhrase
        reg.verifyPassword = reg.password
        tfVerifyPassword.text = reg.verifyPassword
        edCommentsToMuzoma.text = reg.commentsToMuzoma
    }
    
    func runControlStateLogic()
    {
        
        butEdit.setTitle("Edit", for: UIControl.State())
        
        if( reg.hasRegisteredOnMuzoma ) // disable changing email address
        {
            tfPassword.isEnabled = false
            tfVerifyPassword.isEnabled = false
            tfPasswordHint.isEnabled = false
            
            butIAlreadyRegistered.isHidden = true
            
            labHelpText.text = reg.emailVerified ? "Registered and verified - Thankyou" : "Registered but unverified - please verify your registration email and then reopen this view"
            
            if( !reg.emailVerified )
            {
                butResendRegEmail.isHidden = false
                butEdit.isHidden = true
            }
            else
            {
                butResendRegEmail.isHidden = true
                butEdit.isHidden = false
                butChangePassword.isEnabled = true
            }
            
            butIAlreadyRegistered.isHidden = true
            tfCommunityName.isEnabled = false
            tfFirstName.isEnabled = false
            tfMiddleName.isEnabled = false
            tfLastName.isEnabled = false
            tfEmailAddress.isEnabled = false
            swEmailOK.isEnabled = false
            tfArtist.isEnabled = false
            tfAuthor.isEnabled = false
            tfCopyright.isEnabled = false
            tfPublisher.isEnabled = false
            butRegister.isEnabled = false
            butRegister.setTitle("Registered", for: UIControl.State())
            edCommentsToMuzoma.isUserInteractionEnabled = false
            edCommentsToMuzoma.isEditable = false
        }
        else
        {
            tfPassword.isEnabled = true
            tfVerifyPassword.isEnabled = true
            tfPasswordHint.isEnabled = true
            labHelpText.text = "Set defaults, and register with Muzoma"
            butIAlreadyRegistered.isHidden = false
            butResendRegEmail.isHidden = true
        }
    }
    
    func goEditMode()
    {
        if( reg.hasRegisteredOnMuzoma ) // disable changing email address
        {
            butIAlreadyRegistered.isHidden = true
            
            if( butEdit.titleLabel?.text == "Edit" )
            {
                // can only edit certain fields
                
                labHelpText.text="Some fields can now be edited, for security reasons, your user name (email address) and primary details are fixed"
                swEmailOK.isEnabled = true
                edCommentsToMuzoma.isEditable = true
                edCommentsToMuzoma.isUserInteractionEnabled = true
                
                tfArtist.isEnabled = true
                tfAuthor.isEnabled = true
                tfCopyright.isEnabled = true
                tfPublisher.isEnabled = true
                butRegister.isEnabled = true
                butRegister.setTitle("Update", for: UIControl.State())
                butEdit.setTitle("Cancel", for: UIControl.State())
                
                tfArtist.becomeFirstResponder()
                let indexPath = IndexPath(row: 0, section: 8)
                self.tableView.scrollToRow(at: indexPath,
                                           at: UITableView.ScrollPosition.middle, animated: true)
            }
            else
            {
                butEdit.setTitle("Edit", for: UIControl.State())
                runControlStateLogic()
            }
        }
        else
        {
            butIAlreadyRegistered.isHidden = false
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        runControlStateLogic()
        
        // check if we have registered and password has not been confirmed
        if( !reg.emailVerified )
        {
            _ = reg.restoreCredentialsFromUserAndPassword(); // double check
        }
        
        self.refreshControl?.addTarget(self, action: #selector(UserRegistrationTableViewController.refresh(_:)), for: UIControl.Event.valueChanged)
        
        regToScreen()
    }
    
    @objc func refresh(_ sender:AnyObject)
    {
        // Updating your data here...
        // check if we have registered and password has not been confirmed
        if( !reg.emailVerified )
        {
            _ = reg.restoreCredentialsFromUserAndPassword() // double check
        }
        
        regToScreen()
        self.tableView.reloadData()
        self.refreshControl?.endRefreshing()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    // MARK: - Navigation
    override func willMove(toParent parent: UIViewController?) {
        if( parent == nil )
        {
            if(self.edCommentsToMuzoma.text != reg.commentsToMuzoma )
            {
                reg.commentsToMuzoma = self.edCommentsToMuzoma.text
            }
            
            if( self.butEdit.titleLabel?.text == "Cancel" ) // in edit mode
            {
                let alert = UIAlertController(title: "Unsaved changes", message: "There are unsaved registration changes, do you wish to keep them?", preferredStyle: UIAlertController.Style.alert)
                
                alert.addAction(UIAlertAction(title: "Keep", style: .default, handler: { (action: UIAlertAction!) in
                    //print("reg change keep")
                    DispatchQueue.main.async(execute: {
                        _ = self.reg.updateMuzoma()
                    })
                }))
                
                alert.addAction(UIAlertAction(title: "Cancel", style: .default, handler: { (action: UIAlertAction!) in
                    //print("reg change cancel")
                    DispatchQueue.main.async(execute: {
                        _ = self.reg.restoreCredentialsFromUserAndPassword()
                    })
                }))
                
                alert.modalPresentationStyle = UIModalPresentationStyle.overCurrentContext
                let keyWind = UIApplication.shared.keyWindow!
                if( keyWind.visibleViewController != nil )
                {
                    let currentVC = keyWind.visibleViewController
                    currentVC!.present(alert, animated: true, completion: {})
                }
            }
        }
        
        super.willMove(toParent: parent)
    }
}
