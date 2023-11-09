//
//  ChainTerra.swift
//  Cosmostation
//
//  Created by yongjoo jung on 2023/10/04.
//  Copyright © 2023 wannabit. All rights reserved.
//

import Foundation

class ChainTerra: CosmosClass  {
    
    override init() {
        super.init()
        
        name = "Terra"
        tag = "terra330"
        logo1 = "chainTerra"
        logo2 = "chainTerra2"
        apiName = "terra"
        stakeDenom = "uluna"
        
        accountKeyType = AccountKeyType(.COSMOS_Secp256k1, "m/44'/330'/0'/0/X")
        bechAccountPrefix = "terra"
        
        grpcHost = "grpc-terra.cosmostation.io"
    }
}
