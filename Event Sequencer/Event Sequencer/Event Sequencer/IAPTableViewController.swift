//
//  IAPTableViewController.swift
//  Muzoma
//
//  Created by Matthew Hopkins on 08/08/2016.
//  Copyright © 2016 Muzoma.com. All rights reserved.
//
//  Code to handle the UI side of in app purchases
//

import UIKit
import StoreKit
import Alamofire

class IAPTableViewController: UITableViewController {
    fileprivate var _transport:Transport! = nil
    
    var products = [SKProduct]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Muzoma In-App Purchases"
        
        refreshControl?.addTarget(self, action: #selector(IAPTableViewController.reload), for: .valueChanged)
        
        let restoreButton = UIBarButtonItem(title: "Restore",
                                            style: .plain,
                                            target: self,
                                            action: #selector(IAPTableViewController.restoreTapped(_:)))
        navigationItem.rightBarButtonItem = restoreButton
        
        NotificationCenter.default.addObserver(self, selector: #selector(IAPTableViewController.handlePurchaseNotification(_:)),
                                               name: NSNotification.Name(rawValue: IAPHelper.IAPHelperPurchaseNotification),
                                                         object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(IAPTableViewController.handleTransactionNotification(_:)),
                                               name: NSNotification.Name(rawValue: IAPHelper.IAPHelperTransactionIdNotification),
                                                         object: nil)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    override func viewDidAppear(_ animated: Bool) {
        //print( "viewDidAppear Docs View" )
        _transport = Transport( viewController: self, hideAllControls: true )
        reload()
        return super.viewDidAppear(animated)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        _transport?.willDeinit()
        _transport = nil
        super.viewDidDisappear(animated)
    }
    
    @objc func reload() {
        products = []
        
        tableView.reloadData()
        
        MuzomaProducts.store.requestProducts{success, products in
            if success {
                self.products = products!
                
                // must dispatch as more than one might be trying to display
                DispatchQueue.main.async(execute: {
                    self.tableView.reloadData()
                })
            }
            
            // must dispatch as more than one might be trying to display
            DispatchQueue.main.async(execute: {
                self.refreshControl?.endRefreshing()
            })
        }
    }
    
    @objc func restoreTapped(_ sender: AnyObject) {
        MuzomaProducts.store.restorePurchases()
        
        let alert = UIAlertController(title: "Restore Products", message: "A request to restore previously purchased products has been sent to the app store", preferredStyle: UIAlertController.Style.alert)
        
        alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: { (action: UIAlertAction!) in
        }))
        
        alert.modalPresentationStyle = UIModalPresentationStyle.overCurrentContext
        
        // must dispatch as more than one might be trying to display
        DispatchQueue.main.async(execute: {
            self.present(alert, animated: true, completion: nil)
        })
        
    }
    
    @objc func handlePurchaseNotification(_ notification: Notification)
    {
        guard let productID = notification.object as? String else { return }
        
        for (index, product) in products.enumerated()
        {
            guard product.productIdentifier == productID else { continue }

            var alert:UIAlertController! = nil
            let reg = UserRegistration()
            if( !reg.hasRegisteredLocally )
            {
                // Purchased, but not registered.
                alert = UIAlertController(title: "Registration", message: "Thank you very much for your purchase\nPlease register in order to set up your document defaults", preferredStyle: UIAlertController.Style.alert)
                
                alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { (action: UIAlertAction!) in
                    //print("load file Yes")
                    
                    let registerController = self.storyboard?.instantiateViewController(withIdentifier: "UserRegistrationTableViewController") as? UserRegistrationTableViewController
                    
                    self.navigationController?.pushViewController(registerController!, animated: true)
                    
                }))
                
                alert.addAction(UIAlertAction(title: "Later", style: .cancel, handler: { (action: UIAlertAction!) in
                    //print("load file No")
                    
                }))
            }
            else
            {
                alert = UIAlertController(title: "Thank You!", message: "Thank you very much for your purchase\nEnjoy using \(product.localizedTitle)", preferredStyle: UIAlertController.Style.alert)
                
                alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: { (action: UIAlertAction!) in
                }))
            }
              
            alert.modalPresentationStyle = UIModalPresentationStyle.overCurrentContext
            // must dispatch as more than one might be trying to display
            DispatchQueue.main.async(execute: {
                if( self.presentedViewController != nil )
                {
                    self.dismiss(animated: true, completion: {
                        self.present(alert, animated: true, completion: nil)
                    })
                }
                else
                {
                    self.present(alert, animated: true, completion: nil)
                }
            })
            
            tableView.reloadRows(at: [IndexPath(row: index, section: 0)], with: .fade)
        }
    }
    
    @objc func handleTransactionNotification(_ notification: Notification) {
        guard let tx = notification.object as? IAPHelper.IAPHelperTX else { return }
        
        // we need to make a note in the user registration of the transaction id
        if( tx.identifier == "MuzomaProducer" )
        {
            let reg = UserRegistration()
            reg.appleProducerPurchasedTXReceipt = tx.transactionId
            
            // handled async
            // 1a. its a user who logged their details, so restore the backend details to us
            if( tx.isRestoring )
            {
                // 1. call out to check if the transaction id is recognised on our backend
                reg.restoreCredentialsFromTransaction()
            }
            else if( reg.hasRegisteredLocally )
            {   // 1b. its a new purchase recognised user, so update our register on the backend
                _ = reg.updateMuzoma()
            }
            else
            {
                // not registered
            }
        }
    }

    
    // MARK: - Table view data source
    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return products.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "IAPProductCell", for: indexPath) as! IAPTableViewCell
        let product = products[indexPath.row]
        
        cell.product = product
        cell.buyButtonHandler = { product in
            MuzomaProducts.store.buyProduct(product)
        }
        
        return cell
    }
}


