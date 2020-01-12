/*
 * Copyright (c) 2016 Razeware LLC
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 */

import UIKit
import StoreKit

class MasterViewController: UITableViewController {
    
    let showDetailSegueIdentifier = "showDetail"
    
    var products = [SKProduct]()
    
    override func shouldPerformSegueWithIdentifier(identifier: String, sender: AnyObject?) -> Bool {
        if identifier == showDetailSegueIdentifier {
            guard let indexPath = tableView.indexPathForSelectedRow else {
                return false
            }
            
            let product = products[indexPath.row]
            
            return MuzomaProducts.store.isProductPurchased(product.productIdentifier)
        }
        
        return true
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == showDetailSegueIdentifier {
            guard let indexPath = tableView.indexPathForSelectedRow else { return }
            
            let product = products[indexPath.row]
            
            if let name = resourceNameForProductIdentifier(product.productIdentifier),
                detailViewController = segue.destinationViewController as? DetailViewController {
                let image = UIImage(named: name)
                detailViewController.image = image
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Muzoma In-App Purchases"
        
        refreshControl?.addTarget(self, action: #selector(MasterViewController.reload), forControlEvents: .ValueChanged)
        
        let restoreButton = UIBarButtonItem(title: "Restore",
                                            style: .Plain,
                                            target: self,
                                            action: #selector(MasterViewController.restoreTapped(_:)))
        navigationItem.rightBarButtonItem = restoreButton
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(MasterViewController.handlePurchaseNotification(_:)),
                                                         name: IAPHelper.IAPHelperPurchaseNotification,
                                                         object: nil)
        //self.tableView.registerClass(ProductCell.self, forCellReuseIdentifier: "ProductCell")

        
        /*
        refreshControl = UIRefreshControl()
        refreshControl?.addTarget(self, action: #selector(MasterViewController.reload), forControlEvents: .ValueChanged)
        
        let restoreButton = UIBarButtonItem(title: "Restore",
                                            style: .Plain,
                                            target: self,
                                            action: #selector(MasterViewController.restoreTapped(_:)))
        navigationItem.rightBarButtonItem = restoreButton
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(MasterViewController.handlePurchaseNotification(_:)),
                                                         name: IAPHelper.IAPHelperPurchaseNotification,
                                                         object: nil)
        self.tableView.registerClass(ProductCell.self, forCellReuseIdentifier: "ProductCell")
        self.tableView.autoresizesSubviews = true
        self.tableView.rowHeight = 60.0
        self.tableView.sizeToFit()*/
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        reload()
    }
    
    func reload() {
        products = []
        
        tableView.reloadData()
        
        MuzomaProducts.store.requestProducts{success, products in
            if success {
                self.products = products!
                print( " \(products!.count) products returned from Apple" )

                    for product in products! {
                        print( "got: \(product.productIdentifier) - \(product.localizedTitle) - \(product.localizedDescription)" )
                    }

                self.tableView.reloadData()
            }
            
            self.refreshControl?.endRefreshing()
        }
    }
    
    func restoreTapped(sender: AnyObject) {
        MuzomaProducts.store.restorePurchases()
        let alert = UIAlertController(title: "Restore Products", message: "A request to restore previously purchased products has been sent", preferredStyle: UIAlertControllerStyle.Alert)
        
        alert.addAction(UIAlertAction(title: "OK", style: .Cancel, handler: { (action: UIAlertAction!) in
        }))
        
        
        alert.modalPresentationStyle = UIModalPresentationStyle.OverCurrentContext
        self.presentViewController(alert, animated: true, completion: nil)
    }
    
    func handlePurchaseNotification(notification: NSNotification) {
        guard let productID = notification.object as? String else { return }
 
        for (index, product) in products.enumerate() {
            guard product.productIdentifier == productID else { continue }
            
            let alert = UIAlertController(title: "Thank You!", message: "Thank you very much for your purchase\nEnjoy using \(product.localizedTitle)", preferredStyle: UIAlertControllerStyle.Alert)
            
            alert.addAction(UIAlertAction(title: "OK", style: .Cancel, handler: { (action: UIAlertAction!) in
            }))
            
            
            alert.modalPresentationStyle = UIModalPresentationStyle.OverCurrentContext
            self.presentViewController(alert, animated: true, completion: nil)
            
            tableView.reloadRowsAtIndexPaths([NSIndexPath(forRow: index, inSection: 0)], withRowAnimation: .Fade)
        }
    }
}

// MARK: - UITableViewDataSource

extension MasterViewController {
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return products.count
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        var cell = tableView.dequeueReusableCellWithIdentifier("ProductCell", forIndexPath: indexPath)
        /*if cell == nil {
            cell = ProductCell(style: UITableViewCellStyle.Value1, reuseIdentifier: "ProductCell")
        }*/
        
        let product = products[indexPath.row]
        
        /*
        cell.product = product
        cell.buyButtonHandler = { product in
            MuzomaProducts.store.buyProduct(product)
        }
        */
        return cell
    }
}
