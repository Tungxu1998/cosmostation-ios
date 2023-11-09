//
//  ChainEmoney.swift
//  Cosmostation
//
//  Created by yongjoo jung on 2023/10/04.
//  Copyright © 2023 wannabit. All rights reserved.
//

import Foundation

class ChainEmoney: CosmosClass  {
    
    override init() {
        super.init()
        
        name = "E-Money"
        tag = "emoney118"
        logo1 = "chainEmoney"
        logo2 = "chainEmoney2"
        apiName = "emoney"
        stakeDenom = "ungm"
        
        accountKeyType = AccountKeyType(.COSMOS_Secp256k1, "m/44'/118'/0'/0/X")
        bechAccountPrefix = "emoney"
        
        grpcHost = "grpc-emoney.cosmostation.io"
    }
    
}

