//
//  ChainLum.swift
//  Cosmostation
//
//  Created by yongjoo jung on 2023/08/23.
//  Copyright © 2023 wannabit. All rights reserved.
//

import Foundation

class ChainLum880: CosmosClass  {
    
    override init() {
        super.init()
        
        name = "Lum"
        tag = "lum880"
        logo1 = "chainLum"
        logo2 = "chainLum2"
        apiName = "lum"
        stakeDenom = "ulum"
        
        accountKeyType = AccountKeyType(.COSMOS_Secp256k1, "m/44'/880'/0'/0/X")
        bechAccountPrefix = "lum"
        
        grpcHost = "grpc-lum.cosmostation.io"
    }
    
}
