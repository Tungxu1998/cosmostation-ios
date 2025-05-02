//
//  ChainNoble.swift
//  Cosmostation
//
//  Created by yongjoo jung on 2023/10/04.
//  Copyright © 2023 wannabit. All rights reserved.
//

import Foundation

class ChainNoble: BaseChain  {
    
    override init() {
        super.init()
        
        name = "Noble"
        tag = "noble118"
        chainImg = "chainNoble"
        apiName = "noble"
        accountKeyType = AccountKeyType(.COSMOS_Secp256k1, "m/44'/118'/0'/0/X")
        
        
        cosmosEndPointType = .UseGRPC
        stakeDenom = "ustake"
        bechAccountPrefix = "noble"
        validatorPrefix = "noblevaloper"
        supportStaking = false
        grpcHost = "grpc-noble.cosmostation.io"
        lcdUrl = "https://lcd-noble.cosmostation.io/"
    }
}
