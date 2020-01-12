//
//  IAPTableViewCell.swift
//  Muzoma
//
//  Created by Matthew Hopkins on 08/08/2016.
//  Copyright © 2016 Muzoma.com. All rights reserved.
//
//  Each In App product is a row in the table
//

import UIKit
import StoreKit

class IAPTableViewCell: UITableViewCell {

    @IBOutlet weak var labProductName: UILabel!
    @IBOutlet weak var edDescription: UITextView!
    @IBOutlet weak var butBuy: UIButton!
    @IBOutlet weak var labProductPrice: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    @IBAction func buyClicked(_ sender: AnyObject) {
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    static let priceFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        
        formatter.formatterBehavior = .behavior10_4
        formatter.numberStyle = .currency
        
        return formatter
    }()

    var product: SKProduct? {
        didSet {
            guard let product = product else { return }
            butBuy.isHidden = true
            labProductPrice.isHidden = true
            
            edDescription.isEditable = false
            edDescription.isUserInteractionEnabled = false
            labProductName.text = "\(product.localizedTitle)"
            edDescription.text = "\(product.localizedDescription)"

            if MuzomaProducts.store.isProductPurchased(product.productIdentifier) {
                accessoryType = .checkmark
                accessoryView = nil
            } else if IAPHelper.canMakePayments() {
                butBuy.isHidden = false
                labProductPrice.isHidden = false
                
                IAPTableViewCell.priceFormatter.locale = product.priceLocale
                let priceString = IAPTableViewCell.priceFormatter.string(from: product.price)
                labProductPrice.text = "\(priceString!)"
                butBuy.isEnabled = true
            } else {
                labProductName.text! += " (Not available at present)"
                labProductName.isEnabled = false
            }
        }
    }
    
    var buyButtonHandler: ((_ product: SKProduct) -> ())?
    
    @IBAction func butBuyClicked(_ sender: AnyObject) {
        buyButtonHandler?(product!)
    }
}
