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

class ProductCell : UITableViewCell {
    
    
    @IBOutlet weak var labTitle: UITextField!
    @IBOutlet weak var textViewDesc: UITextView!
    @IBOutlet weak var labPrice: UILabel!
    @IBOutlet weak var butBuy: UIButton!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        
        // Configure the view for the selected state
    }
    
    static let priceFormatter: NSNumberFormatter = {
        let formatter = NSNumberFormatter()
        
        formatter.formatterBehavior = .Behavior10_4
        formatter.numberStyle = .CurrencyStyle
        
        return formatter
    }()
    
    var buyButtonHandler: ((product: SKProduct) -> ())?
    
    var product: SKProduct? {
        didSet {
            guard let product = product else { return }
            
            labTitle.text = "\(product.localizedTitle)"
            
            if MuzomaProducts.store.isProductPurchased(product.productIdentifier) {
                accessoryType = .Checkmark
                accessoryView = nil
                detailTextLabel?.text = ""
            } else if IAPHelper.canMakePayments() {
                textViewDesc.text = "\(product.localizedDescription)"
                
                ProductCell.priceFormatter.locale = product.priceLocale
                let priceString = ProductCell.priceFormatter.stringFromNumber(product.price)
                labPrice.text = "\(priceString!)"
                accessoryType = .None
                accessoryView = self.newBuyButton()
            } else {
                detailTextLabel?.text = "Not available"
            }
        }
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        textLabel?.text = ""
        detailTextLabel?.text = ""
        accessoryView = nil
    }
    
    func newBuyButton() -> UIButton {
        let button = UIButton(type: .System)
        button.setTitleColor(tintColor, forState: .Normal)
        button.setTitle("Buy", forState: .Normal)
        button.addTarget(self, action: #selector(ProductCell.buyButtonTapped(_:)), forControlEvents: .TouchUpInside)
        button.sizeToFit()
        
        return button
    }
    
    func buyButtonTapped(sender: AnyObject) {
        buyButtonHandler?(product: product!)
    }
}