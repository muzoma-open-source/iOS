//
//  MuzomaProducts
//  Muzoma
//
//  Created by Matthew Hopkins on 15/06/2016.
//  Copyright © 2016 Muzoma.com. All rights reserved.
//

import Foundation

public struct MuzomaProducts {
    public static let MuzomaProducer = /*Prefix +*/ "MuzomaProducer"
    
    fileprivate static let productIdentifiers: Set<ProductIdentifier> = [MuzomaProducts.MuzomaProducer]
    
    public static let store = IAPHelper(productIds: MuzomaProducts.productIdentifiers)
}

func resourceNameForProductIdentifier(_ productIdentifier: String) -> String? {
    return productIdentifier.components(separatedBy: ".").last
}
