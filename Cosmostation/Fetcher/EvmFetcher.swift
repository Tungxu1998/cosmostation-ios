//
//  EvmFetcher.swift
//  Cosmostation
//
//  Created by yongjoo jung on 6/15/24.
//  Copyright © 2024 wannabit. All rights reserved.
//

import Foundation
import Alamofire
import SwiftyJSON
import BigInt

class EvmFetcher {
    
    var chain: BaseChain!
    
    var evmBalances = NSDecimalNumber.zero
    var mintscanErc20Tokens = [MintscanToken]()
    
    init(_ chain: BaseChain) {
        self.chain = chain
    }
    
    
    func fetchEvmBalances() async -> Bool {
        evmBalances = NSDecimalNumber.zero
        if let balanceJson = try? await fetchEvmBalance(chain.evmAddress!),
           let balance = balanceJson?["result"].string?.hexToNSDecimal() {
            self.evmBalances = balance
        } else {
            return false
        }
        return true
    }
    
    func fetchEvmData(_ id: Int64) async -> Bool {
        mintscanErc20Tokens.removeAll()
        
        do {
            let erc20Tokens = try await self.fetchErc20Info()
            let balanceJson = try await fetchEvmBalance(self.chain.evmAddress!)
            if let erc20Tokens = erc20Tokens {
                self.mintscanErc20Tokens = erc20Tokens
            }
            if let balance = balanceJson?["result"].string?.hexToNSDecimal() {
                self.evmBalances = balance
            } else {
                return false
            }
            
            let userDisplaytoken = BaseData.instance.getDisplayErc20s(id, self.chain.tag)
            await mintscanErc20Tokens.concurrentForEach { erc20 in
                if (userDisplaytoken == nil) {
                    if (erc20.wallet_preload == true) {
                        await self.fetchErc20Balance(erc20)
                    }
                } else {
                    if (userDisplaytoken?.contains(erc20.contract!) == true) {
                        await self.fetchErc20Balance(erc20)
                    }
                }
            }
            return true
            
        } catch {
            print("evm error \(error) ", chain.tag)
            return false
        }
    }
    
    func allCoinValue(_ usd: Bool? = false) -> NSDecimalNumber {
        if let msAsset = BaseData.instance.getAsset(chain.apiName, chain.coinSymbol) {
            let msPrice = BaseData.instance.getPrice(msAsset.coinGeckoId, usd)
            return evmBalances.multiplying(by: msPrice).multiplying(byPowerOf10: -18, withBehavior: handler6)
        }
        return NSDecimalNumber.zero
    }
    
    func tokenValue(_ address: String, _ usd: Bool? = false) -> NSDecimalNumber {
        if let tokenInfo = mintscanErc20Tokens.filter({ $0.contract == address }).first {
            let msPrice = BaseData.instance.getPrice(tokenInfo.coinGeckoId, usd)
            return msPrice.multiplying(by: tokenInfo.getAmount()).multiplying(byPowerOf10: -tokenInfo.decimals!, withBehavior: handler6)
        }
        return NSDecimalNumber.zero
    }
    
    func allTokenValue(_ usd: Bool? = false) -> NSDecimalNumber {
        var result = NSDecimalNumber.zero
        mintscanErc20Tokens.forEach { tokenInfo in
            let msPrice = BaseData.instance.getPrice(tokenInfo.coinGeckoId, usd)
            let value = msPrice.multiplying(by: tokenInfo.getAmount()).multiplying(byPowerOf10: -tokenInfo.decimals!, withBehavior: handler6)
            result = result.adding(value)
        }
        return result
    }
    
    func valueCoinCnt() -> Int {
        return evmBalances != NSDecimalNumber.zero ? 1 : 0
    }
    
    func valueTokenCnt() -> Int {
        return mintscanErc20Tokens.filter {  $0.getAmount() != NSDecimalNumber.zero }.count
    }
    
}

//about mintscan api
extension EvmFetcher {
    
    func fetchErc20Info() async throws -> [MintscanToken]?  {
        if chain.isSupportErc20() {
            return try await AF.request(BaseNetWork.msErc20InfoUrl(chain.apiName), method: .get).serializingDecodable([MintscanToken].self).value
        }
        return []
    }
    
    func fetchEvmBalance(_ address: String) async throws -> JSON? {
        let param: Parameters = ["method": "eth_getBalance", "params": [address, "latest"], "id" : 1, "jsonrpc" : "2.0"]
        return try await AF.request(getEvmRpc(), method: .post, parameters: param, encoding: JSONEncoding.default).serializingDecodable(JSON.self).value
    }
    
    func fetchAllErc20Balance(_ id: Int64) async {
        let userDisplaytoken = BaseData.instance.getDisplayErc20s(id, self.chain.tag)
        Task {
            await mintscanErc20Tokens.concurrentForEach { erc20 in
                if (userDisplaytoken == nil) {
                    if (erc20.wallet_preload == true) {
                        await self.fetchErc20Balance(erc20)
                    }
                } else {
                    if (userDisplaytoken?.contains(erc20.contract!) == true) {
                        await self.fetchErc20Balance(erc20)
                    }
                }
            }
        }
    }
    
    func fetchErc20Balance(_ tokenInfo: MintscanToken) async {
        var data = ""
        if tokenInfo.symbol == "BGT" {
            data = "0x9203ad5d000000000000000000000000" + self.chain.evmAddress!.stripHexPrefix()
        } else {
            data = "0x70a08231000000000000000000000000" + self.chain.evmAddress!.stripHexPrefix()
        }
        let param: Parameters = ["method": "eth_call", "id" : 1, "jsonrpc" : "2.0",
                                 "params": [["data": data, "to" : tokenInfo.contract], "latest"]]
        if let erc20BalanceJson = try? await AF.request(getEvmRpc(), method: .post, parameters: param, encoding: JSONEncoding.default).serializingDecodable(JSON.self).value {
            let erc20Balance = erc20BalanceJson["result"].stringValue.hexToNSDecimal()
//            print("fetchErc20Balance ", tokenInfo.symbol, "  ", erc20Balance().stringValue)
            tokenInfo.setAmount(erc20Balance.stringValue)
        }
    }
    
    func fetchErc20BalanceAmount(_ contractAddress: String) async throws -> NSDecimalNumber? {
        let data = "0x70a08231000000000000000000000000" + self.chain.evmAddress!.stripHexPrefix()
        let param: Parameters = ["method": "eth_call", "id" : 1, "jsonrpc" : "2.0",
                                 "params": [["data": data, "to" : contractAddress], "latest"]]
        if let erc20BalanceJson = try? await AF.request(getEvmRpc(), method: .post, parameters: param, encoding: JSONEncoding.default).serializingDecodable(JSON.self).value {
            return erc20BalanceJson["result"].stringValue.hexToNSDecimal()
        }
        return nil
    }
    
    func fetchEvmTxReceipt(_ txHash: String) async throws -> JSON? {
        let param: Parameters = ["method": "eth_getTransactionReceipt", "params": [txHash], "id" : 1, "jsonrpc" : "2.0"]
        return try await AF.request(getEvmRpc(), method: .post, parameters: param, encoding: JSONEncoding.default).serializingDecodable(JSON.self).value
    }
    
    func fetchEvmTxByHash(_ txHash: String) async throws -> JSON? {
        let param: Parameters = ["method": "eth_getTransactionByHash", "params": [txHash], "id" : 1, "jsonrpc" : "2.0"]
        return try await AF.request(getEvmRpc(), method: .post, parameters: param, encoding: JSONEncoding.default).serializingDecodable(JSON.self).value
    }
    
    func fetchEvmEstimateGas(_ reqParam: JSON) async throws -> JSON? {
        let param: Parameters = ["method": "eth_estimateGas", "params": [reqParam.dictionaryObject], "id" : 1, "jsonrpc" : "2.0"]
        let response = try await AF.request(getEvmRpc(), method: .post, parameters: param, encoding: JSONEncoding.default).serializingDecodable(JSON.self).value
        return response
    }
    
    func fetchEvmBlockNumbers() async throws -> JSON? {
        let param: Parameters = ["method": "eth_blockNumber", "params": [], "id" : 1, "jsonrpc" : "2.0"]
        return try await AF.request(getEvmRpc(), method: .post, parameters: param, encoding: JSONEncoding.default).serializingDecodable(JSON.self).value
    }
     
    func fetchEvmEthCall(_ reqParam: JSON) async throws -> JSON? {
        let param: Parameters = ["method": "eth_call", "params": [reqParam.dictionaryObject, "latest"], "id" : 1, "jsonrpc" : "2.0"]
        return try await AF.request(getEvmRpc(), method: .post, parameters: param, encoding: JSONEncoding.default).serializingDecodable(JSON.self).value
    }
    
    func fetchEvmBlockByNumber() async throws -> JSON? {
        let param: Parameters = ["method": "eth_getBlockByNumber", "params": ["latest", false], "id" : 1, "jsonrpc" : "2.0"]
        return try await AF.request(getEvmRpc(), method: .post, parameters: param, encoding: JSONEncoding.default).serializingDecodable(JSON.self).value
    }
    
    func fetchEvmGasPrice() async throws -> JSON? {
        let param: Parameters = ["method": "eth_gasPrice", "params": [], "id" : 1, "jsonrpc" : "2.0"]
        return try await AF.request(getEvmRpc(), method: .post, parameters: param, encoding: JSONEncoding.default).serializingDecodable(JSON.self).value
    }
    
    func fetchEvmMaxPriorityFeePerGas() async throws -> JSON? {
        let param: Parameters = ["method": "eth_maxPriorityFeePerGas", "params": [], "id" : 1, "jsonrpc" : "2.0"]
        return try await AF.request(getEvmRpc(), method: .post, parameters: param, encoding: JSONEncoding.default).serializingDecodable(JSON.self).value
    }
    
    func getEvmRpc() -> String {
        if let endpoint = UserDefaults.standard.string(forKey: KEY_CHAIN_EVM_RPC_ENDPOINT +  " : " + chain.name) {
            return endpoint.trimmingCharacters(in: .whitespaces)
        }
        return chain.evmRpcURL
    }
    
}



let EVM_BASE_FEE = NSDecimalNumber.init(string: "588000000000000")
