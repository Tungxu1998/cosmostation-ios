//
//  ChainIxo.swift
//  Cosmostation
//
//  Created by yongjoo jung on 2023/10/04.
//  Copyright © 2023 wannabit. All rights reserved.
//

import Foundation

class ChainIxo: CosmosClass  {
    
    override init() {
        super.init()
        
        name = "Ixo"
        tag = "ixo118"
        logo1 = "chainIxo"
        logo2 = "chainIxo2"
        apiName = "ixo"
        stakeDenom = "uixo"
        
        accountKeyType = AccountKeyType(.COSMOS_Secp256k1, "m/44'/118'/0'/0/X")
        bechAccountPrefix = "ixo"
        
        grpcHost = "grpc-ixo.cosmostation.io"
    }
}
