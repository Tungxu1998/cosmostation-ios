//
//  ChainCoreum.swift
//  Cosmostation
//
//  Created by yongjoo jung on 2023/10/01.
//  Copyright © 2023 wannabit. All rights reserved.
//

import Foundation

class ChainCoreum: BaseChain  {
    
    override init() {
        super.init()
        
        name = "Coreum"
        tag = "coreum990"
        chainImg = "chainCoreum"
        apiName = "coreum"
        accountKeyType = AccountKeyType(.COSMOS_Secp256k1, "m/44'/990'/0'/0/X")
        
        
        cosmosEndPointType = .UseGRPC
        stakeDenom = "ucore"
        bechAccountPrefix = "core"
        validatorPrefix = "corevaloper"
        grpcHost = "grpc-coreum.cosmostation.io"  
        lcdUrl = "https://lcd-coreum.cosmostation.io/"
    }
    
}
