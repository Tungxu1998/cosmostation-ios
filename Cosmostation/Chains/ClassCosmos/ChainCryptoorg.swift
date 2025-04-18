//
//  ChainCryptoorg.swift
//  Cosmostation
//
//  Created by yongjoo jung on 2023/10/01.
//  Copyright © 2023 wannabit. All rights reserved.
//

import Foundation

class ChainCryptoorg: BaseChain  {
    
    override init() {
        super.init()
        
        name = "Cronos POS"
        tag = "crypto-org394"
        apiName = "crypto-org"
        accountKeyType = AccountKeyType(.COSMOS_Secp256k1, "m/44'/394'/0'/0/X")
        
        
        cosmosEndPointType = .UseGRPC
        stakeDenom = "basecro"
        bechAccountPrefix = "cro"
        validatorPrefix = "crocncl"
        grpcHost = "grpc-crypto-org.cosmostation.io"
        lcdUrl = "https://lcd-crypto-org.cosmostation.io/"
    }
    
}

