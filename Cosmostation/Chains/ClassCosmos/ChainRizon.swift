//
//  ChainRizon.swift
//  Cosmostation
//
//  Created by yongjoo jung on 2023/10/04.
//  Copyright © 2023 wannabit. All rights reserved.
//

import Foundation

class ChainRizon: BaseChain  {
    
    override init() {
        super.init()
        
        name = "Rizon"
        tag = "rizon118"
        logo1 = "chainRizon"
        apiName = "rizon"
        accountKeyType = AccountKeyType(.COSMOS_Secp256k1, "m/44'/118'/0'/0/X")
        
        
        cosmosEndPointType = .UseLCD
        stakeDenom = "uatolo"
        bechAccountPrefix = "rizon"
        validatorPrefix = "rizonvaloper"
        lcdUrl = "https://api.rizon.chaintools.tech/"
    }
}
