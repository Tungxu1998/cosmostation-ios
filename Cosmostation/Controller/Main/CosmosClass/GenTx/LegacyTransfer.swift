//
//  LegacyTransfer.swift
//  Cosmostation
//
//  Created by yongjoo jung on 2023/10/07.
//  Copyright © 2023 wannabit. All rights reserved.
//

import UIKit
import Lottie
import SwiftyJSON
import Alamofire
import AlamofireImage
import web3swift

class LegacyTransfer: BaseVC {
    
    @IBOutlet weak var midGapConstraint: NSLayoutConstraint!
    @IBOutlet weak var titleLabel: UILabel!
    
    @IBOutlet weak var toAddressCardView: FixCardView!
    @IBOutlet weak var toAddressTitle: UILabel!
    @IBOutlet weak var toAddressHint: UILabel!
    @IBOutlet weak var toAddressMasterLabel: UILabel!
    @IBOutlet weak var toAddressSlaveLabel: UILabel!
    
    @IBOutlet weak var toSendAssetCard: FixCardView!
    @IBOutlet weak var toSendAssetTitle: UILabel!
    @IBOutlet weak var toSendAssetImg: UIImageView!
    @IBOutlet weak var toSendSymbolLabel: UILabel!
    @IBOutlet weak var toSendAssetHint: UILabel!
    @IBOutlet weak var toAssetAmountLabel: UILabel!
    @IBOutlet weak var toAssetDenomLabel: UILabel!
    @IBOutlet weak var toAssetCurrencyLabel: UILabel!
    @IBOutlet weak var toAssetValueLabel: UILabel!
    
    @IBOutlet weak var memoCardView: FixCardView!
    @IBOutlet weak var memoTitle: UILabel!
    @IBOutlet weak var memoLabel: UILabel!
    @IBOutlet weak var memoHintLabel: UILabel!
    
    @IBOutlet weak var feeSelectImg: UIImageView!
    @IBOutlet weak var feeSelectLabel: UILabel!
    @IBOutlet weak var feeAmountLabel: UILabel!
    @IBOutlet weak var feeDenomLabel: UILabel!
    @IBOutlet weak var feeCurrencyLabel: UILabel!
    @IBOutlet weak var feeValueLabel: UILabel!
    
    @IBOutlet weak var sendBtn: BaseButton!
    @IBOutlet weak var loadingView: LottieAnimationView!
    
    var selectedChain: CosmosClass!
    var toSendDenom: String!
    var stakeDenom: String!
    var availableAmount = NSDecimalNumber.zero
    var toSendAmount = NSDecimalNumber.zero
    var userInputAddress: String?
    var recipientBechAddress: String?
    var recipientEvmAddress: String?
    var txMemo = ""
    
    var tokenInfo: JSON!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        baseAccount = BaseData.instance.baseAccount
        stakeDenom = selectedChain.stakeDenom
        
        loadingView.isHidden = true
        loadingView.animation = LottieAnimation.named("loading")
        loadingView.contentMode = .scaleAspectFit
        loadingView.loopMode = .loop
        loadingView.animationSpeed = 1.3
        loadingView.play()
        
        //display to send asset info
        if let bnbChain = selectedChain as? ChainBinanceBeacon {
            tokenInfo = bnbChain.lcdBeaconTokens.filter({ $0["symbol"].string == toSendDenom }).first!
            let original_symbol = tokenInfo["original_symbol"].stringValue
            toSendAssetImg.af.setImage(withURL: ChainBinanceBeacon.assetImg(original_symbol))
            toSendSymbolLabel.text = original_symbol.uppercased()
            
            let available = bnbChain.lcdBalanceAmount(toSendDenom)
            if (toSendDenom == stakeDenom) {
                availableAmount = available.subtracting(NSDecimalNumber(string: BNB_BEACON_BASE_FEE))
            } else {
                availableAmount = available
            }
            print("availableAmount ", availableAmount)
            
        } else if let okChain = selectedChain as? ChainOkt60Keccak {
            tokenInfo = okChain.lcdOktTokens.filter({ $0["symbol"].string == toSendDenom }).first!
            let original_symbol = tokenInfo["original_symbol"].stringValue
            toSendAssetImg.af.setImage(withURL: ChainOkt60Keccak.assetImg(original_symbol))
            toSendSymbolLabel.text = original_symbol.uppercased()
            
            let available = okChain.lcdBalanceAmount(toSendDenom)
            if (toSendDenom == stakeDenom) {
                availableAmount = available.subtracting(NSDecimalNumber(string: OKT_BASE_FEE))
            } else {
                availableAmount = available
            }
            
        }
        
        toSendAssetCard.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(onClickAmount)))
        toAddressCardView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(onClickToAddress)))
        memoCardView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(onClickMemo)))
        
        onUpdateFeeView()
    }
    
    override func setLocalizedString() {
        titleLabel.text = NSLocalizedString("str_transfer_asset", comment: "")
        toAddressHint.text = NSLocalizedString("msg_tap_for_add_address", comment: "")
        toSendAssetHint.text = NSLocalizedString("msg_tap_for_add_amount", comment: "")
        memoHintLabel.text = NSLocalizedString("msg_tap_for_add_memo", comment: "")
        sendBtn.setTitle(NSLocalizedString("str_send", comment: ""), for: .normal)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        let gap = UIScreen.main.bounds.size.height - 600
        if (gap > 0) { midGapConstraint.constant = gap }
        else { midGapConstraint.constant = 60 }
    }
    
    @IBAction func onClickScan(_ sender: UIButton) {
        let qrScanVC = QrScanVC(nibName: "QrScanVC", bundle: nil)
        qrScanVC.scanDelegate = self
        present(qrScanVC, animated: true)
    }
    
    @objc func onClickAmount() {
        let amountSheet = TxAmountLegacySheet(nibName: "TxAmountLegacySheet", bundle: nil)
        amountSheet.selectedChain = selectedChain
        amountSheet.tokenInfo = tokenInfo
        amountSheet.availableAmount = availableAmount
        if (toSendAmount != NSDecimalNumber.zero) {
            amountSheet.existedAmount = toSendAmount
        }
        amountSheet.sheetDelegate = self
        self.onStartSheet(amountSheet)
    }
    
    func onUpdateAmountView(_ amount: String?) {
        toSendAssetHint.isHidden = false
        toAssetAmountLabel.isHidden = true
        toAssetDenomLabel.isHidden = true
        toAssetCurrencyLabel.isHidden = true
        toAssetValueLabel.isHidden = true
        
        if (amount?.isEmpty == true) {
            toSendAmount = NSDecimalNumber.zero
            
        } else {
            toSendAmount = NSDecimalNumber(string: amount)
            
            if (selectedChain is ChainBinanceBeacon) {
                toAssetDenomLabel.text = tokenInfo["original_symbol"].stringValue.uppercased()
                toAssetAmountLabel?.attributedText = WDP.dpAmount(toSendAmount.stringValue, toAssetAmountLabel!.font, 8)
                toSendAssetHint.isHidden = true
                toAssetAmountLabel.isHidden = false
                toAssetDenomLabel.isHidden = false
                
                if (toSendDenom == stakeDenom) {
                    let msPrice = BaseData.instance.getPrice(BNB_GECKO_ID)
                    let toSendValue = msPrice.multiplying(by: toSendAmount, withBehavior: handler6)
                    WDP.dpValue(toSendValue, toAssetCurrencyLabel, toAssetValueLabel)
                    toAssetCurrencyLabel.isHidden = false
                    toAssetValueLabel.isHidden = false
                }
                
            } else if (selectedChain is ChainOkt60Keccak) {
                toAssetDenomLabel.text = tokenInfo["original_symbol"].stringValue.uppercased()
                toAssetAmountLabel?.attributedText = WDP.dpAmount(toSendAmount.stringValue, toAssetAmountLabel!.font, 18)
                toSendAssetHint.isHidden = true
                toAssetAmountLabel.isHidden = false
                toAssetDenomLabel.isHidden = false
                
                if (toSendDenom == stakeDenom) {
                    let msPrice = BaseData.instance.getPrice(OKT_GECKO_ID)
                    let toSendValue = msPrice.multiplying(by: toSendAmount, withBehavior: handler6)
                    WDP.dpValue(toSendValue, toAssetCurrencyLabel, toAssetValueLabel)
                    toAssetCurrencyLabel.isHidden = false
                    toAssetValueLabel.isHidden = false
                }
            }
        }
        onValidate()
    }
    
    
    @objc func onClickToAddress() {
        let addressSheet = TxAddressSheet(nibName: "TxAddressSheet", bundle: nil)
        addressSheet.selectedChain = selectedChain
        if (userInputAddress?.isEmpty == false) {
            addressSheet.existedAddress = userInputAddress
        }
        addressSheet.recipientChain = selectedChain
        addressSheet.addressDelegate = self
        self.onStartSheet(addressSheet, 220)
    }
    
    func onUpdateToAddressView() {
        if (userInputAddress == nil ||
            userInputAddress?.isEmpty == true) {
            recipientBechAddress = nil
            recipientEvmAddress = nil
            toAddressHint.isHidden = false
            toAddressMasterLabel.isHidden = true
            toAddressSlaveLabel.isHidden = true
            
        } else {
            toAddressHint.isHidden = true
            if (selectedChain is ChainBinanceBeacon) {
                toAddressMasterLabel.text = recipientBechAddress
                toAddressMasterLabel.isHidden = false
                
            } else if (selectedChain is ChainOkt60Keccak) {
                toAddressMasterLabel.text = recipientEvmAddress
                toAddressMasterLabel.isHidden = false
                
                toAddressSlaveLabel.text = "(" + recipientBechAddress! + ")"
                toAddressSlaveLabel.isHidden = false
            }
            toAddressMasterLabel.adjustsFontSizeToFitWidth = true
            toAddressSlaveLabel.adjustsFontSizeToFitWidth = true
        }
        onValidate()
    }
    
    @objc func onClickMemo() {
        let memoSheet = TxMemoSheet(nibName: "TxMemoSheet", bundle: nil)
        memoSheet.existedMemo = txMemo
        memoSheet.memoDelegate = self
        self.onStartSheet(memoSheet, 260)
    }
    
    func onUpdateMemoView(_ memo: String) {
        txMemo = memo
        if (txMemo.isEmpty) {
            memoLabel.isHidden = true
            memoHintLabel.isHidden = false
        } else {
            memoLabel.text = txMemo
            memoLabel.isHidden = false
            memoHintLabel.isHidden = true
        }
    }
    
    func onUpdateFeeView() {
        if (selectedChain is ChainBinanceBeacon) {
            feeSelectImg.af.setImage(withURL: ChainBinanceBeacon.assetImg(stakeDenom))
            feeSelectLabel.text = stakeDenom.uppercased()
            
            let msPrice = BaseData.instance.getPrice(BNB_GECKO_ID)
            let feeAmount = NSDecimalNumber(string: BNB_BEACON_BASE_FEE)
            let feeValue = msPrice.multiplying(by: feeAmount, withBehavior: handler6)
            feeAmountLabel?.attributedText = WDP.dpAmount(feeAmount.stringValue, feeAmountLabel!.font, 8)
            feeDenomLabel.text = stakeDenom.uppercased()
            WDP.dpValue(feeValue, feeCurrencyLabel, feeValueLabel)
            
        } else if (selectedChain is ChainOkt60Keccak) {
            feeSelectImg.af.setImage(withURL: ChainOkt60Keccak.assetImg(stakeDenom))
            feeSelectLabel.text = stakeDenom.uppercased()
            
            let msPrice = BaseData.instance.getPrice(OKT_GECKO_ID)
            let feeAmount = NSDecimalNumber(string: OKT_BASE_FEE)
            let feeValue = msPrice.multiplying(by: feeAmount, withBehavior: handler6)
            feeAmountLabel?.attributedText = WDP.dpAmount(feeAmount.stringValue, feeAmountLabel!.font, 18)
            feeDenomLabel.text = stakeDenom.uppercased()
            WDP.dpValue(feeValue, feeCurrencyLabel, feeValueLabel)
        }
    }
    
    @IBAction func onClickSend(_ sender: BaseButton) {
        let pinVC = UIStoryboard.PincodeVC(self, .ForDataCheck)
        self.present(pinVC, animated: true)
    }
    
    func onValidate() {
        sendBtn.isEnabled = false
        if (toSendAmount == NSDecimalNumber.zero ) { return }
        if (recipientBechAddress == nil || recipientBechAddress?.isEmpty == true) { return }
        if (txMemo.count > 300) { return }
        sendBtn.isEnabled = true
    }
}


extension LegacyTransfer: LegacyAmountSheetDelegate, MemoDelegate, AddressDelegate , QrScanDelegate, PinDelegate {
    
    func onInputedAmount(_ amount: String) {
        onUpdateAmountView(amount)
    }
    
    func onInputedAddress(_ address: String, _ memo: String?) {
        recipientBechAddress = nil
        recipientEvmAddress = nil
        userInputAddress = address
        if (WUtils.isValidBechAddress(selectedChain, userInputAddress)) {
            recipientBechAddress = userInputAddress
            recipientEvmAddress = KeyFac.convertBech32ToEvm(userInputAddress!)
        }
        if (WUtils.isValidEvmAddress(userInputAddress)) {
            recipientBechAddress = KeyFac.convertEvmToBech32(userInputAddress!, selectedChain.bechAccountPrefix!)
            recipientEvmAddress = userInputAddress
        }
        onUpdateToAddressView()
        if (memo != nil && memo?.isEmpty == false) {
            onUpdateMemoView(memo!)
        }
        print("userInputAddress", userInputAddress)
        print("recipientBechAddress", recipientBechAddress)
        print("recipientEvmAddress", recipientEvmAddress)
    }
    
    func onInputedMemo(_ memo: String) {
        onUpdateMemoView(memo)
    }
    
    func onScanned(_ result: String) {
        recipientBechAddress = nil
        recipientEvmAddress = nil
        let scanedString = result.components(separatedBy: "(MEMO)")
        var addressScan = ""
        var memoScan = ""
        if (scanedString.count == 2) {
            addressScan = scanedString[0].trimmingCharacters(in: .whitespaces)
            memoScan = scanedString[1].trimmingCharacters(in: .whitespaces)
        } else {
            addressScan = scanedString[0].trimmingCharacters(in: .whitespaces)
        }
        
        if (addressScan.isEmpty == true || addressScan.count < 5) {
            self.onShowToast(NSLocalizedString("error_invalid_address", comment: ""))
            return;
        }
        if (addressScan == selectedChain.bechAddress || addressScan == selectedChain.evmAddress) {
            self.onShowToast(NSLocalizedString("error_self_send", comment: ""))
            return;
        }
        
        if (selectedChain is ChainBinanceBeacon) {
            if (WUtils.isValidBechAddress(selectedChain, addressScan)) {
                userInputAddress = addressScan
                recipientBechAddress = addressScan
                if (scanedString.count > 1) {
                    onUpdateMemoView(memoScan)
                }
                onUpdateToAddressView()
                return
            }
            
        } else if (selectedChain is ChainOkt60Keccak) {
            if (WUtils.isValidBechAddress(selectedChain, addressScan)) {
                userInputAddress = addressScan
                recipientBechAddress = userInputAddress
                recipientEvmAddress = KeyFac.convertBech32ToEvm(userInputAddress!)
                return
            }
            if (WUtils.isValidEvmAddress(addressScan)) {
                userInputAddress = addressScan
                recipientBechAddress = KeyFac.convertEvmToBech32(userInputAddress!, selectedChain.bechAccountPrefix!)
                recipientEvmAddress = userInputAddress
                if (scanedString.count > 1) {
                    onUpdateMemoView(memoScan)
                }
                onUpdateToAddressView()
                return
            }
        }
        self.onShowToast(NSLocalizedString("error_invalid_address", comment: ""))
    }
    
    func onPinResponse(_ request: LockType, _ result: UnLockResult) {
        if (result == .success) {
            view.isUserInteractionEnabled = false
            sendBtn.isEnabled = false
            loadingView.isHidden = false
            
            Task {
                if (selectedChain is ChainBinanceBeacon) {
                    if let response = try? await broadcastBnbSendTx() {
                        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(500), execute: {
                            self.loadingView.isHidden = true
                            
                            let txResult = CosmosTxResult(nibName: "CosmosTxResult", bundle: nil)
                            txResult.selectedChain = self.selectedChain
                            txResult.legacyResult = response?.arrayValue[0]
                            txResult.modalPresentationStyle = .fullScreen
                            self.present(txResult, animated: true)
                            
                        });
                    }
                    
                } else if (selectedChain is ChainOkt60Keccak) {
                    if let response = try? await broadcastOktSendTx() {
                        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(500), execute: {
                            print("response ", response)
                            self.loadingView.isHidden = true
                            
                            let txResult = CosmosTxResult(nibName: "CosmosTxResult", bundle: nil)
                            txResult.selectedChain = self.selectedChain
                            txResult.legacyResult = response
                            txResult.modalPresentationStyle = .fullScreen
                            self.present(txResult, animated: true)
                            
                        });
                    }
                }
            }
        }
    }
}

extension LegacyTransfer {
    
    func broadcastBnbSendTx() async throws -> JSON? {
        let bnbChain = selectedChain as! ChainBinanceBeacon
        let bnbMsg = BinanceMessage.transfer(symbol: self.toSendDenom,
                                             amount: (self.toSendAmount).doubleValue,
                                             toAddress: self.recipientBechAddress!,
                                             memo: self.txMemo,
                                             privateKey: self.selectedChain.privateKey!,
                                             signerAddress: self.selectedChain.bechAddress,
                                             sequence: bnbChain.lcdAccountInfo["sequence"].intValue,
                                             accountNumber: bnbChain.lcdAccountInfo["account_number"].intValue,
                                             chainId: self.selectedChain.chainId)
        
        var encoding: ParameterEncoding = URLEncoding.default
        encoding = HexEncoding(data: try bnbMsg.encode())
        let param: Parameters = ["address": self.selectedChain.bechAddress]
        
        return try? await AF.request(BaseNetWork.broadcastUrl(self.selectedChain), method: .post, parameters: param, encoding: encoding, headers: [:]).serializingDecodable(JSON.self).value
    }
    
    
    func broadcastOktSendTx() async throws -> JSON? {
        
        let sendCoin = L_Coin(toSendDenom, WUtils.getFormattedNumber(toSendAmount, 18))
        let gasCoin = L_Coin(stakeDenom, WUtils.getFormattedNumber(NSDecimalNumber(string: OKT_BASE_FEE), 18))
        let fee = L_Fee(BASE_GAS_AMOUNT, [gasCoin])
        
        let okMsg = L_Generator.oktSendMsg(selectedChain.bechAddress, recipientBechAddress!, [sendCoin])
        let postData = L_Generator.postData([okMsg], fee, txMemo, selectedChain)
        let param = try! JSONSerialization.jsonObject(with: postData, options: .allowFragments) as? [String: Any]
        
        return try? await AF.request(BaseNetWork.broadcastUrl(self.selectedChain), method: .post, parameters: param, encoding: JSONEncoding.default, headers: [:]).serializingDecodable(JSON.self).value
    }
    
}
