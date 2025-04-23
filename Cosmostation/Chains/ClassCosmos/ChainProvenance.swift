//
//  ChainProvenance.swift
//  Cosmostation
//
//  Created by yongjoo jung on 2023/10/04.
//  Copyright © 2023 wannabit. All rights reserved.
//

import Foundation

class ChainProvenance: BaseChain  {
    
    override init() {
        super.init()
        
        name = "Provenance"
        tag = "provenance505"
        apiName = "provenance"
        accountKeyType = AccountKeyType(.COSMOS_Secp256k1, "m/44'/505'/0'/0/X")
        
        
        cosmosEndPointType = .UseGRPC
        stakeDenom = "nhash"
        bechAccountPrefix = "pb"
        validatorPrefix = "pbvaloper"
        grpcHost = "grpc-provenance.cosmostation.io"
        lcdUrl = "https://lcd-provenance.cosmostation.io/"
    }
}
