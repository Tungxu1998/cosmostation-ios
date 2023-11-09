//
//  ChainOkt60Keccak.swift
//  Cosmostation
//
//  Created by yongjoo jung on 2023/10/07.
//  Copyright © 2023 wannabit. All rights reserved.
//

import Foundation
import Alamofire
import SwiftyJSON

class ChainOkt60Keccak: CosmosClass  {
    
    //For Legacy Lcd chains
    lazy var lcdNodeInfo = JSON()
    lazy var lcdAccountInfo = JSON()
    lazy var lcdOktDeposits = JSON()
    lazy var lcdOktWithdaws = JSON()
    lazy var lcdOktTokens = Array<JSON>()
    
    override init() {
        super.init()
        
        name = "OKT"
        chainId = "exchain-66"
        tag = "okt60_Keccak"
        logo1 = "chainOkt"
        logo2 = "chainOkt2"
        apiName = ""
        stakeDenom = "okt"
        
        accountKeyType = AccountKeyType(.ETH_Keccak256, "m/44'/60'/0'/0/X")
        bechAccountPrefix = "ex"
        supportStaking = false
        evmCompatible = true
    }
    
    override func setInfoWithSeed(_ seed: Data, _ lastPath: String) {
        privateKey = KeyFac.getPriKeyFromSeed(accountKeyType.pubkeyType, seed, getHDPath(lastPath))
        publicKey = KeyFac.getPubKeyFromPrivateKey(privateKey!, accountKeyType.pubkeyType)
        evmAddress = KeyFac.getAddressFromPubKey(publicKey!, accountKeyType.pubkeyType, nil)
        bechAddress = KeyFac.convertEvmToBech32(evmAddress, bechAccountPrefix!)
//        print("", tag, " ", bechAddress, "  ", evmAddress)
    }
    
    override func setInfoWithPrivateKey(_ priKey: Data) {
        privateKey = priKey
        publicKey = KeyFac.getPubKeyFromPrivateKey(privateKey!, accountKeyType.pubkeyType)
        evmAddress = KeyFac.getAddressFromPubKey(publicKey!, accountKeyType.pubkeyType, nil)
        bechAddress = KeyFac.convertEvmToBech32(evmAddress, bechAccountPrefix!)
    }
    
    override func fetchData(_ id: Int64) {
        fetchLcdData(id)
    }
    
    override func isTxFeePayable() -> Bool {
        let availableAmount = lcdBalanceAmount(stakeDenom)
        return availableAmount.compare(NSDecimalNumber(string: OKT_BASE_FEE)).rawValue > 0
    }
    
    override func allCoinValue(_ usd: Bool? = false) -> NSDecimalNumber {
        return lcdBalanceValue(stakeDenom, usd).adding(lcdOktDepositValue(usd)).adding(lcdOktWithdrawValue(usd))
    }
    
    
    static func assetImg(_ original_symbol: String) -> URL {
        return URL(string: ResourceBase + "okc/asset/" + original_symbol.lowercased() + ".png") ?? URL(string: "")!
    }
}

extension ChainOkt60Keccak {
    
    func fetchLcdData(_ id: Int64) {
        let group = DispatchGroup()
        
        fetchNodeInfo(group)
        fetchAccountInfo(group, bechAddress)
        fetchOktDeposited(group, bechAddress)
        fetchOktWithdraw(group, bechAddress)
        fetchOktTokens(group)
        
        group.notify(queue: .main) {
            self.fetched = true
            self.allCoinValue = self.allCoinValue()
            self.allCoinUSDValue = self.allCoinValue(true)
            
            let refAddress =
            BaseData.instance.updateRefAddressesMain(
                RefAddress(id, self.tag, self.bechAddress, self.evmAddress,
                           self.lcdAllStakingDenomAmount().stringValue, self.allCoinUSDValue.stringValue,
                           nil, self.lcdAccountInfo.oktCoins?.count))
            NotificationCenter.default.post(name: Notification.Name("FetchData"), object: self.tag, userInfo: nil)
        }
    }
    
    func fetchNodeInfo(_ group: DispatchGroup) {
//        print("fetchNodeInfo Start ", BaseNetWork.lcdNodeInfoUrl(self))
        group.enter()
        AF.request(BaseNetWork.lcdNodeInfoUrl(self), method: .get)
            .responseDecodable(of: JSON.self) { response in
                switch response.result {
                case .success(let value):
                    self.lcdNodeInfo = value
//                    print("fetchNodeInfo ", value)
                case .failure:
                    print("fetchNodeInfo error")
                }
                group.leave()
            }
    }
    
    func fetchAccountInfo(_ group: DispatchGroup, _ address: String) {
//        print("fetchAccountInfo Start ", BaseNetWork.lcdAccountInfoUrl(self, address))
        group.enter()
        AF.request(BaseNetWork.lcdAccountInfoUrl(self, address), method: .get)
            .responseDecodable(of: JSON.self) { response in
                switch response.result {
                case .success(let value):
                    self.lcdAccountInfo = value
//                    print("fetchAccountInfo ", value)
                case .failure:
                    print("fetchAccountInfo error")
                }
                group.leave()
            }
    }
    
    func fetchOktDeposited(_ group: DispatchGroup, _ address: String) {
//        print("fetchOktDeposited Start ", BaseNetWork.lcdOktDepositUrl(address))
        group.enter()
        AF.request(BaseNetWork.lcdOktDepositUrl(address), method: .get)
            .responseDecodable(of: JSON.self) { response in
                switch response.result {
                case .success(let value):
                    self.lcdOktDeposits = value
//                    print("fetchOktDeposited ", value)
                case .failure:
                    print("fetchOktDeposited error")
                }
                group.leave()
            }
    }
    
    func fetchOktWithdraw(_ group: DispatchGroup, _ address: String) {
//        print("fetchOktWithdraw Start ", BaseNetWork.lcdOktWithdrawUrl(address))
        group.enter()
        AF.request(BaseNetWork.lcdOktWithdrawUrl( address), method: .get)
            .responseDecodable(of: JSON.self) { response in
                switch response.result {
                case .success(let value):
                    self.lcdOktWithdaws = value
//                    print("fetchOktWithdraw ", value)
                case .failure:
                    print("fetchOktWithdraw error")
                }
                group.leave()
            }
    }
    
    func fetchOktTokens(_ group: DispatchGroup) {
//        print("fetchOktTokens Start ", BaseNetWork.lcdOktTokenUrl())
        group.enter()
        AF.request(BaseNetWork.lcdOktTokenUrl(), method: .get)
            .responseDecodable(of: JSON.self) { response in
                switch response.result {
                case .success(let values):
                    values["data"].array?.forEach({ value in
                        self.lcdOktTokens.append(value)
                    })
//                    print("lcdOktTokens : ", self.lcdOktTokens.count)
                    
                case .failure:
                    print("fetchOktTokens error")
                }
                group.leave()
            }
    }
    
    
    
    func lcdAllStakingDenomAmount() -> NSDecimalNumber {
        return lcdBalanceAmount(stakeDenom).adding(lcdOktDepositAmount()).adding(lcdOktWithdrawAmount())
    }
    
    func lcdBalanceAmount(_ denom: String) -> NSDecimalNumber {
        if let balance = lcdAccountInfo.oktCoins?.filter({ $0["denom"].string == denom }).first {
            return NSDecimalNumber.init(string: balance["amount"].string ?? "0")
        }
        return NSDecimalNumber.zero
        
    }
    
    func lcdBalanceValue(_ denom: String, _ usd: Bool? = false) -> NSDecimalNumber {
        if (denom == stakeDenom) {
            let amount = lcdBalanceAmount(denom)
            var msPrice = BaseData.instance.getPrice(OKT_GECKO_ID, usd)
            return msPrice.multiplying(by: amount, withBehavior: handler6)
        }
        return NSDecimalNumber.zero
    }
    
    func lcdOktDepositAmount() -> NSDecimalNumber {
        return NSDecimalNumber(string: lcdOktDeposits["tokens"].string ?? "0")
    }
    
    func lcdOktDepositValue(_ usd: Bool? = false) -> NSDecimalNumber {
        let msPrice = BaseData.instance.getPrice(OKT_GECKO_ID, usd)
        let amount = lcdOktDepositAmount()
        return msPrice.multiplying(by: amount, withBehavior: handler6)
    }
    
    func lcdOktWithdrawAmount() -> NSDecimalNumber {
        return NSDecimalNumber(string: lcdOktWithdaws["quantity"].string ?? "0")
    }
    
    func lcdOktWithdrawValue(_ usd: Bool? = false) -> NSDecimalNumber {
        let msPrice = BaseData.instance.getPrice(OKT_GECKO_ID, usd)
        let amount = lcdOktWithdrawAmount()
        return msPrice.multiplying(by: amount, withBehavior: handler6)
    }
}

let OKT_LCD = "https://exchainrpc.okex.org/okexchain/v1/"
let OKT_EXPLORER = "https://www.oklink.com/oktc/"
let OKT_BASE_FEE = "0.00008"
let OKT_GECKO_ID = "oec-token"
