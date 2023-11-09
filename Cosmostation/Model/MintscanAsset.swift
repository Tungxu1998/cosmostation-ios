//
//  MintscanAsset.swift
//  Cosmostation
//
//  Created by yongjoo jung on 2022/08/24.
//  Copyright © 2022 wannabit. All rights reserved.
//

import Foundation
import SwiftyJSON

public struct MintscanAssets: Codable {
    var assets: [MintscanAsset]?
}

public struct MintscanAsset: Codable {
    var chain: String?
    var denom: String?
    var type: String?
    var origin_chain: String?
    var origin_denom: String?
    var origin_type: String?
    var symbol: String?
    var decimals: Int16?
    var description: String?
    var image: String?
    var coinGeckoId: String?
    
    var enable: Bool?
    var path: String?
    var channel: String?
    var port: String?
    var counter_party: MintscanAssetCounterParty?
    
    func assetImg() -> URL {
        return URL(string: ResourceBase + image!) ?? URL(string: "")!
    }
    
    func beforeChain(_ chainApiName: String) -> String? {
        let chainPath = path?.components(separatedBy: ">")
        if let matched = chainPath?.lastIndex(of: chainApiName) {
            if (matched > 0) {
                return chainPath?[matched - 1]
            }
        }
        return nil
    }
}

public struct MintscanAssetCounterParty: Codable {
    var channel: String?
    var port: String?
    var denom: String?
}
