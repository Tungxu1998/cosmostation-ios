//
//  ChainAlthea118.swift
//  Cosmostation
//
//  Created by yongjoo jung on 2024/02/05.
//  Copyright © 2024 wannabit. All rights reserved.
//

import Foundation

class ChainAlthea118: BaseChain {
    
    override init() {
        super.init()
        
        name = "Althea"
        tag = "althea118"
        chainImg = "chainAlthea"
        isDefault = false
        apiName = "althea"
        accountKeyType = AccountKeyType(.COSMOS_Secp256k1, "m/44'/118'/0'/0/X")
        isOtherChainImage = true

        
        cosmosEndPointType = .UseGRPC
        stakeDenom = "aalthea"
        bechAccountPrefix = "althea"
        validatorPrefix = "altheavaloper"
        grpcHost = "grpc-althea.cosmostation.io"
        lcdUrl = "https://lcd-althea.cosmostation.io/"
    }
}
