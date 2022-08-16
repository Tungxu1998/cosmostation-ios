//
//  CKey.swift
//  Cosmostation
//
//  Created by 정용주 on 2021/10/31.
//  Copyright © 2021 wannabit. All rights reserved.
//

import Foundation
import CryptoSwift
import HDWalletKit


class CKey {
    
    static func getPrivateKeyDataFromSeed(_ seed: Data, _ fullpath: String) -> Data {
        var currentKey = PrivateKey(seed: seed, coin: .bitcoin)
        let components = fullpath.components(separatedBy: "/")
        var firstComponent = 0
        if fullpath.hasPrefix("m") {
            firstComponent = 1
        }
        for component in components[firstComponent ..< components.count] {
            var hardened = false
            if component.hasSuffix("'") {
                hardened = true
            }
            let index = UInt32(component.trimmingCharacters(in: CharacterSet(charactersIn: "'")))!
            currentKey = cDerived(currentKey, index, hardened)
        }
        let hexData = checkZeroStartKey(currentKey.raw.hexEncodedString())
        return Data(hex: hexData)
    }
    
    
    static func getMasterKeyFromWords(_ m: [String]) -> PrivateKey {
        return PrivateKey(seed: Mnemonic.createSeed(mnemonic: m.joined(separator: " ")), coin: .bitcoin)
    }
    
    static func getHDKeyFromWords(_ m: [String], _ account:Account) -> PrivateKey {
        let masterKey = getMasterKeyFromWords(m)
        let chainType = ChainFactory.getChainType(account.account_base_chain)
        
        if (chainType == ChainType.COSMOS_MAIN || chainType == ChainType.IRIS_MAIN || chainType == ChainType.CERTIK_MAIN || chainType == ChainType.AKASH_MAIN ||
            chainType == ChainType.SENTINEL_MAIN || chainType == ChainType.SIF_MAIN || chainType == ChainType.KI_MAIN || chainType == ChainType.OSMOSIS_MAIN ||
            chainType == ChainType.EMONEY_MAIN || chainType == ChainType.RIZON_MAIN || chainType == ChainType.JUNO_MAIN || chainType == ChainType.REGEN_MAIN ||
            chainType == ChainType.BITCANA_MAIN || chainType == ChainType.ALTHEA_MAIN || chainType == ChainType.GRAVITY_BRIDGE_MAIN || chainType == ChainType.STARGAZE_MAIN ||
            chainType == ChainType.COMDEX_MAIN || chainType == ChainType.CHIHUAHUA_MAIN || chainType == ChainType.AXELAR_MAIN || chainType == ChainType.KONSTELLATION_MAIN ||
            chainType == ChainType.UMEE_MAIN || chainType == ChainType.CUDOS_MAIN || chainType == ChainType.CERBERUS_MAIN || chainType == ChainType.OMNIFLIX_MAIN ||
            chainType == ChainType.CRESCENT_MAIN || chainType == ChainType.MANTLE_MAIN || chainType == ChainType.NYX_MAIN || chainType == ChainType.PASSAGE_MAIN ||
            chainType == ChainType.COSMOS_TEST || chainType == ChainType.IRIS_TEST || chainType == ChainType.ALTHEA_TEST || chainType == ChainType.CRESCENT_TEST || chainType == ChainType.STATION_TEST) {
            return cDerived(cDerived(cDerived(cDerived(cDerived(masterKey, 44, true), 118, true), 0, true), 0, false), UInt32(account.account_path)!, false)
            
        } else if (chainType == ChainType.BINANCE_MAIN) {
            return cDerived(cDerived(cDerived(cDerived(cDerived(masterKey, 44, true), 714, true), 0, true), 0, false), UInt32(account.account_path)!, false)
            
        } else if (chainType == ChainType.BAND_MAIN) {
            return cDerived(cDerived(cDerived(cDerived(cDerived(masterKey, 44, true), 494, true), 0, true), 0, false), UInt32(account.account_path)!, false)
            
        } else if (chainType == ChainType.IOV_MAIN) {
            return cDerived(cDerived(cDerived(cDerived(cDerived(masterKey, 44, true), 234, true), 0, true), 0, false), UInt32(account.account_path)!, false)
            
        } else if (chainType == ChainType.PERSIS_MAIN) {
            return cDerived(cDerived(cDerived(cDerived(cDerived(masterKey, 44, true), 750, true), 0, true), 0, false), UInt32(account.account_path)!, false)
            
        } else if (chainType == ChainType.CRYPTO_MAIN) {
            return cDerived(cDerived(cDerived(cDerived(cDerived(masterKey, 44, true), 394, true), 0, true), 0, false), UInt32(account.account_path)!, false)

        } else if (chainType == ChainType.MEDI_MAIN) {
            return cDerived(cDerived(cDerived(cDerived(cDerived(masterKey, 44, true), 371, true), 0, true), 0, false), UInt32(account.account_path)!, false)

        } else if (chainType == ChainType.INJECTIVE_MAIN || chainType == ChainType.EVMOS_MAIN) {
            return cDerived(cDerived(cDerived(cDerived(cDerived(masterKey, 44, true), 60, true), 0, true), 0, false), UInt32(account.account_path)!, false)

        } else if (chainType == ChainType.BITSONG_MAIN) {
            return cDerived(cDerived(cDerived(cDerived(cDerived(masterKey, 44, true), 639, true), 0, true), 0, false), UInt32(account.account_path)!, false)

        } else if (chainType == ChainType.DESMOS_MAIN) {
            return cDerived(cDerived(cDerived(cDerived(cDerived(masterKey, 44, true), 852, true), 0, true), 0, false), UInt32(account.account_path)!, false)

        } else if (chainType == ChainType.PROVENANCE_MAIN) {
            return cDerived(cDerived(cDerived(cDerived(cDerived(masterKey, 44, true), 505, true), 0, true), 0, false), UInt32(account.account_path)!, false)

        }
        
        else if (chainType == ChainType.KAVA_MAIN) {
            if (account.account_custom_path == 0) {
                return cDerived(cDerived(cDerived(cDerived(cDerived(masterKey, 44, true), 118, true), 0, true), 0, false), UInt32(account.account_path)!, false)
            } else {
                return cDerived(cDerived(cDerived(cDerived(cDerived(masterKey, 44, true), 459, true), 0, true), 0, false), UInt32(account.account_path)!, false)
            }
            
        } else if (chainType == ChainType.SECRET_MAIN) {
            if (account.account_custom_path == 0) {
                return cDerived(cDerived(cDerived(cDerived(cDerived(masterKey, 44, true), 118, true), 0, true), 0, false), UInt32(account.account_path)!, false)
            } else {
                return cDerived(cDerived(cDerived(cDerived(cDerived(masterKey, 44, true), 529, true), 0, true), 0, false), UInt32(account.account_path)!, false)
            }
            
        } else if (chainType == ChainType.LUM_MAIN) {
            if (account.account_custom_path == 0) {
                return cDerived(cDerived(cDerived(cDerived(cDerived(masterKey, 44, true), 118, true), 0, true), 0, false), UInt32(account.account_path)!, false)
            } else {
                return cDerived(cDerived(cDerived(cDerived(cDerived(masterKey, 44, true), 880, true), 0, true), 0, false), UInt32(account.account_path)!, false)
            }
            
        } else if (chainType == ChainType.FETCH_MAIN) {
            if (account.account_custom_path == 0) {
                return cDerived(cDerived(cDerived(cDerived(cDerived(masterKey, 44, true), 118, true), 0, true), 0, false), UInt32(account.account_path)!, false)
            } else if (account.account_custom_path == 1) {
                return cDerived(cDerived(cDerived(cDerived(cDerived(masterKey, 44, true), 60, true), 0, true), 0, false), UInt32(account.account_path)!, false)
            } else if (account.account_custom_path == 2) {
                return cDerived(cDerived(cDerived(cDerived(cDerived(masterKey, 44, true), 60, true), UInt32(account.account_path)!, true), 0, false), 0, false)
            } else {
                return cDerived(cDerived(cDerived(cDerived(masterKey, 44, true), 60, true), 0, true), UInt32(account.account_path)!, false)
            }
            
        } else if (chainType == ChainType.OKEX_MAIN) {
            return cDerived(cDerived(cDerived(cDerived(cDerived(masterKey, 44, true), 996, true), 0, true), 0, false), UInt32(account.account_path)!, false)

        }
        
        else {
            return masterKey.derived(at: .hardened(44)).derived(at: .hardened(118)).derived(at: .hardened(0)).derived(at: .notHardened(0)).derived(at: .notHardened(UInt32(account.account_path)!))
        }
    }
    
    
    static func getPrivateRaw(_ mnemonic: [String], _ account: Account) -> Data {
        return getHDKeyFromWords(mnemonic, account).raw
    }
    
    static func getPublicRaw(_ mnemonic: [String], _ account: Account) -> Data {
        return getHDKeyFromWords(mnemonic, account).publicKey.data
    }
    
    static func getStdTx(_ privateKey: Data, _ publicKey: Data, _ msgList: Array<Msg>, _ stdMsg: StdSignMsg, _ account: Account, _ fee: Fee, _ memo: String) -> StdTx {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .sortedKeys
        let data = try? encoder.encode(stdMsg)
        let rawResult = String(data:data!, encoding:.utf8)?.replacingOccurrences(of: "\\/", with: "/")
        let rawData: Data? = rawResult!.data(using: .utf8)
        let hash = rawData!.sha256()
        let signedData = try! ECDSA.compactsign(hash, privateKey: privateKey)
        
        var genedSignature = Signature.init()
        var genPubkey =  PublicKey.init()
        genPubkey.type = COSMOS_KEY_TYPE_PUBLIC
        genPubkey.value = publicKey.base64EncodedString()
        genedSignature.pub_key = genPubkey
        genedSignature.signature = signedData.base64EncodedString()
        genedSignature.account_number = String(account.account_account_numner)
        genedSignature.sequence = String(account.account_sequence_number)
        
        var signatures: Array<Signature> = Array<Signature>()
        signatures.append(genedSignature)
        
        return MsgGenerator.genSignedTx(msgList, fee, memo, signatures)
    }
    
    
    static func cDerived(_ pKey: PrivateKey, _ path: UInt32, _ hardended: Bool) -> PrivateKey {
        var result: PrivateKey
        if (hardended) {
            result = pKey.derived(at: .hardened(path))
        } else {
            result = pKey.derived(at: .notHardened(path))
        }
        let hexData = checkZeroStartKey(result.raw.hexEncodedString())
        return WKey.getPrivateKey(hexData, result.chainCode.hexEncodedString())
    }
    
    static func checkZeroStartKey(_ raw: String) -> String {
        if (raw.starts(with: "00")) {
            return checkZeroStartKey(String(raw.dropFirst(2)))
        } else {
            return raw
        }
    }
    
    static func cPublicKey(_ pKey: PrivateKey) -> HDWalletKit.PublicKey? {
        let hexData = check64Count(pKey.raw.hexEncodedString())
        return WKey.getPrivateKey(hexData, pKey.chainCode.hexEncodedString()).publicKey
    }
    
    static func check64Count(_ raw: String) -> String {
        if (raw.count < 64) {
            return check64Count("00" + raw)
        } else {
            return raw
        }
    }
}
