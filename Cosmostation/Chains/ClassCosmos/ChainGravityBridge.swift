//
//  ChainGravityBridge.swift
//  Cosmostation
//
//  Created by yongjoo jung on 2023/10/04.
//  Copyright © 2023 wannabit. All rights reserved.
//

import Foundation

class ChainGravityBridge: CosmosClass  {
    
    override init() {
        super.init()
        
        name = "G-Bridge"
        tag = "gravity-bridge118"
        logo1 = "chainGravityBridge"
        logo2 = "chainGravityBridge2"
        apiName = "gravity-bridge"
        stakeDenom = "ugraviton"
        
        accountKeyType = AccountKeyType(.COSMOS_Secp256k1, "m/44'/118'/0'/0/X")
        bechAccountPrefix = "gravity"
        
        grpcHost = "grpc-gravity-bridge.cosmostation.io"
    }
}
