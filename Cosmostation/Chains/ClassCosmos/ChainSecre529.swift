//
//  ChainSecre529.swift
//  Cosmostation
//
//  Created by yongjoo jung on 2023/10/04.
//  Copyright © 2023 wannabit. All rights reserved.
//

import Foundation

class ChainSecre529: CosmosClass  {
    
    override init() {
        super.init()
        
        name = "Secret"
        tag = "secret529"
        logo1 = "chainSecret"
        logo2 = "chainSecret2"
        apiName = "secret"
        stakeDenom = "uscrt"
        
        accountKeyType = AccountKeyType(.COSMOS_Secp256k1, "m/44'/529'/0'/0/X")
        bechAccountPrefix = "secret"
        
        grpcHost = "grpc-secret.cosmostation.io"
    }
}

