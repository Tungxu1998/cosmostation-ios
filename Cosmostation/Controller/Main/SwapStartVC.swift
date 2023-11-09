//
//  SwapStartVC.swift
//  Cosmostation
//
//  Created by yongjoo jung on 2023/09/13.
//  Copyright © 2023 wannabit. All rights reserved.
//

import UIKit
import Lottie
import Alamofire
import AlamofireImage
import SwiftyJSON
import GRPC
import NIO
import SwiftProtobuf

class SwapStartVC: BaseVC, UITextFieldDelegate {
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var slippageBtn: UIButton!
    @IBOutlet weak var midGapConstraint1: NSLayoutConstraint!
    @IBOutlet weak var midGapConstraint2: NSLayoutConstraint!
    
    @IBOutlet weak var rootScrollView: UIScrollView!
    @IBOutlet weak var inputCardView: FixCardView!
    @IBOutlet weak var fromAddressLabel: UILabel!
    @IBOutlet weak var inputChainView: DropDownView!
    @IBOutlet weak var inputChainImg: UIImageView!
    @IBOutlet weak var inputChainLabel: UILabel!
    @IBOutlet weak var inputAssetView: DropDownView!
    @IBOutlet weak var inputAssetImg: UIImageView!
    @IBOutlet weak var inputAssetLabel: UILabel!
    @IBOutlet weak var inputAmountTextField: UITextField!
    @IBOutlet weak var inputInvalidLabel: UILabel!
    @IBOutlet weak var inputValueCurrency: UILabel!
    @IBOutlet weak var inputValueLabel: UILabel!
    @IBOutlet weak var inputAvailableLabel: UILabel!
    
    @IBOutlet weak var outputCardView: FixCardView!
    @IBOutlet weak var toAddressLabel: UILabel!
    @IBOutlet weak var outputChainView: DropDownView!
    @IBOutlet weak var outputChainImg: UIImageView!
    @IBOutlet weak var outputChainLabel: UILabel!
    @IBOutlet weak var outputAssetView: DropDownView!
    @IBOutlet weak var outputAssetImg: UIImageView!
    @IBOutlet weak var outputAssetLabel: UILabel!
    @IBOutlet weak var outputAmountLabel: UILabel!
    @IBOutlet weak var outputValueCurrency: UILabel!
    @IBOutlet weak var outputValueLabel: UILabel!
    @IBOutlet weak var outputBalanceLabel: UILabel!
    
    @IBOutlet weak var toggleBtn: UIButton!
    
    @IBOutlet weak var errorCardView: RedFixCardView!
    @IBOutlet weak var errorMsgLabel: UILabel!
    
    @IBOutlet weak var descriptionCardView: FixCardView!
    @IBOutlet weak var slippageLabel: UILabel!
    @IBOutlet weak var rateInputAmountLanel: UILabel!
    @IBOutlet weak var rateInputDenomLabel: UILabel!
    @IBOutlet weak var rateOutputAmountLanel: UILabel!
    @IBOutlet weak var rateOutputDenomLabel: UILabel!
    @IBOutlet weak var feeAmountLanel: UILabel!
    @IBOutlet weak var feeDenomLabel: UILabel!
    @IBOutlet weak var venueLabel: UILabel!
    
    @IBOutlet weak var loadingView: LottieAnimationView!
    @IBOutlet weak var swapBtn: BaseButton!
    
    var allCosmosChains = Array<CosmosClass>()
    var skipChains = Array<CosmosClass>()       //inapp support chain for skip
    var skipAssets: JSON?
    var skipSlippage = "1"
    
    var inputCosmosChain: CosmosClass!
    var inputAssetList = Array<JSON>()
    var inputAssetSelected: JSON!
    var inputMsAsset: MintscanAsset!
    
    var outputCosmosChain: CosmosClass!
    var outputAssetList = Array<JSON>()
    var outputAssetSelected: JSON!
    var outputMsAsset: MintscanAsset!
    
    var availableAmount = NSDecimalNumber.zero
    var toActionAmount = NSDecimalNumber.zero
    
    var txFee: Cosmos_Tx_V1beta1_Fee!
    var toMsg: JSON?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        baseAccount = BaseData.instance.baseAccount
        
        titleLabel.isHidden = true
        slippageBtn.isHidden = true
        rootScrollView.isHidden = true
        swapBtn.isHidden = true
        loadingView.isHidden = false
        loadingView.animation = LottieAnimation.named("loading")
        loadingView.contentMode = .scaleAspectFit
        loadingView.loopMode = .loop
        loadingView.animationSpeed = 1.3
        loadingView.play()
        
        
        Task {
            allCosmosChains = await baseAccount.initOnyKeyData()
            
            var sChains: JSON!
            if (BaseData.instance.skipChains == nil) {
                sChains = try? await fetchSkipChains()
                BaseData.instance.skipChains = sChains
            } else {
                sChains = BaseData.instance.skipChains
            }
//            print("sChains ", sChains)
            sChains?["chains"].arrayValue.forEach({ sChain in
                if let skipChain = allCosmosChains.filter({ $0.chainId == sChain["chain_id"].stringValue && $0.isDefault == true }).first {
                    skipChains.append(skipChain)
                }
            })
            
            if (BaseData.instance.skipAssets == nil) {
                skipAssets = try? await fetchSkipAssets()
                BaseData.instance.skipAssets = skipAssets
            } else {
                skipAssets = BaseData.instance.skipAssets
            }
//            print("skipChains ", skipChains.count)
//            print("skipAssets ", skipAssets?["chain_to_assets_map"].count)
            
            // $0.isDefault 예외처리 확인 카바
            inputCosmosChain = skipChains.filter({ $0.tag == "cosmos118" }).first!
            skipAssets?["chain_to_assets_map"][inputCosmosChain.chainId]["assets"].arrayValue.forEach({ json in
                if BaseData.instance.getAsset(inputCosmosChain.apiName, json["denom"].stringValue) != nil {
                    inputAssetList.append(json)
                }
            })
            inputAssetSelected = inputAssetList.filter { $0["denom"].stringValue == inputCosmosChain.stakeDenom }.first!
            
            outputCosmosChain = skipChains.filter({ $0.tag == "neutron118" }).first!
            skipAssets?["chain_to_assets_map"][outputCosmosChain.chainId]["assets"].arrayValue.forEach({ json in
                if BaseData.instance.getAsset(outputCosmosChain.apiName, json["denom"].stringValue) != nil {
                    outputAssetList.append(json)
                }
            })
            outputAssetSelected = outputAssetList.filter { $0["denom"].stringValue == outputCosmosChain.stakeDenom }.first!
            
            let inputChannel = getConnection(inputCosmosChain)
            if let inputAuth = try? await fetchAuth(inputChannel, inputCosmosChain.bechAddress),
               let inputBal = try? await fetchBalances(inputChannel, inputCosmosChain.bechAddress),
               let inputParam = try? await inputCosmosChain.fetchChainParam() {
                inputCosmosChain.mintscanChainParam = inputParam
                inputCosmosChain.cosmosAuth = inputAuth?.account ?? Google_Protobuf_Any()
                inputCosmosChain.cosmosBalances = inputBal!
                WUtils.onParseVestingAccount(inputCosmosChain)
            }
            
            let outputChannel = getConnection(outputCosmosChain)
            if let outputAuth = try? await fetchAuth(outputChannel, outputCosmosChain.bechAddress),
               let outputBal = try? await fetchBalances(outputChannel, outputCosmosChain.bechAddress),
               let outputParam = try? await outputCosmosChain.fetchChainParam() {
                outputCosmosChain.mintscanChainParam = outputParam
                outputCosmosChain.cosmosAuth = outputAuth?.account ?? Google_Protobuf_Any()
                outputCosmosChain.cosmosBalances = outputBal!
                WUtils.onParseVestingAccount(outputCosmosChain)
            }
            
            DispatchQueue.main.async {
                self.onInitView()
            }
        }
        
        
        inputChainView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(onInputChain)))
        inputAssetView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(onInputAsset)))
        outputChainView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(onOutputChain)))
        outputAssetView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(onOutputAsset)))
        view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard)))

        inputAmountTextField.delegate = self
        inputAmountTextField.addTarget(self, action: #selector(textFieldDidChange(_:)), for: .editingChanged)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        let gap = UIScreen.main.bounds.size.height - 740
        if (gap > 0) {
            midGapConstraint1.constant = gap
            midGapConstraint2.constant = gap + 40
        } else {
            midGapConstraint1.constant = 60
            midGapConstraint2.constant = 70
        }
    }
    
    func onInitView() {
        titleLabel.isHidden = false
        slippageBtn.isHidden = false
        rootScrollView.isHidden = false
        swapBtn.isHidden = false
        onReadyToUserInsert()
    }
    
    func onReadyToUserInsert() {
        toMsg = nil
        swapBtn.isEnabled = false
        toggleBtn.isEnabled = true
        
        loadingView.isHidden = true
        txFee = getBaseFee()
//        print("txFee ", txFee)
        
        //From UI update
        fromAddressLabel.text = inputCosmosChain.bechAddress
        inputChainImg.image = UIImage(named: inputCosmosChain.logo1)
        inputChainLabel.text = inputCosmosChain.name.uppercased()
//        print("fromAddress ", inputCosmosChain.address)
        
        let inputDenom = inputAssetSelected["denom"].stringValue
//        print("inputDenom ", inputDenom)
        inputMsAsset = BaseData.instance.getAsset(inputCosmosChain.apiName, inputDenom)!
        inputAssetImg.af.setImage(withURL: inputMsAsset.assetImg())
        inputAssetLabel.text = inputMsAsset.symbol
        
        let inputBlance = inputCosmosChain.balanceAmount(inputDenom)
        if (txFee.amount[0].denom == inputDenom) {
            let feeAmount = NSDecimalNumber.init(string: txFee.amount[0].amount)
            if (feeAmount.compare(inputBlance).rawValue >= 0) {
                availableAmount = NSDecimalNumber.zero
            } else {
                availableAmount = inputBlance.subtracting(feeAmount)
            }
        } else {
            availableAmount = inputBlance
        }
        WDP.dpCoin(inputMsAsset, availableAmount, nil, nil, inputAvailableLabel, inputMsAsset.decimals)
        
        
        //To UI update
        toAddressLabel.text = outputCosmosChain.bechAddress
        outputChainImg.image = UIImage(named: outputCosmosChain.logo1)
        outputChainLabel.text = outputCosmosChain.name.uppercased()
//        print("toAddress ", outputCosmosChain.address)
        
        let outputDenom = outputAssetSelected["denom"].stringValue
//        print("outputDenom ", outputDenom)
        outputMsAsset = BaseData.instance.getAsset(outputCosmosChain.apiName, outputDenom)!
        outputAssetImg.af.setImage(withURL: outputMsAsset.assetImg())
        outputAssetLabel.text = outputMsAsset.symbol
        
        let outputBalance = outputCosmosChain.balanceAmount(outputDenom)
        WDP.dpCoin(outputMsAsset, outputBalance, nil, nil, outputBalanceLabel, outputMsAsset.decimals)
        
        inputAmountTextField.text = ""
        inputValueCurrency.text = ""
        inputValueLabel.text = ""
        outputAmountLabel.text = ""
        outputValueCurrency.text = ""
        outputValueLabel.text = ""
        errorCardView.isHidden = true
        descriptionCardView.isHidden = true
    }
    
    @objc func onInputChain() {
        dismissKeyboard()
        let baseSheet = BaseSheet(nibName: "BaseSheet", bundle: nil)
        baseSheet.swapChains = skipChains
        baseSheet.sheetDelegate = self
        baseSheet.sheetType = .SelectSwapInputChain
        onStartSheet(baseSheet, 680)
    }
    
    @objc func onInputAsset() {
        dismissKeyboard()
        let baseSheet = BaseSheet(nibName: "BaseSheet", bundle: nil)
        baseSheet.swapAssets = inputAssetList
        baseSheet.swapBalance = inputCosmosChain.cosmosBalances
        baseSheet.targetChain = inputCosmosChain
        baseSheet.sheetDelegate = self
        baseSheet.sheetType = .SelectSwapInputAsset
        onStartSheet(baseSheet, 680)
    }
    
    @objc func onOutputChain() {
        dismissKeyboard()
        let baseSheet = BaseSheet(nibName: "BaseSheet", bundle: nil)
        baseSheet.swapChains = skipChains
        baseSheet.sheetDelegate = self
        baseSheet.sheetType = .SelectSwapOutputChain
        onStartSheet(baseSheet, 680)
    }
    
    @objc func onOutputAsset() {
        dismissKeyboard()
        let baseSheet = BaseSheet(nibName: "BaseSheet", bundle: nil)
        baseSheet.swapAssets = outputAssetList
        baseSheet.swapBalance = outputCosmosChain.cosmosBalances
        baseSheet.targetChain = outputCosmosChain
        baseSheet.sheetDelegate = self
        baseSheet.sheetType = .SelectSwapOutputAsset
        onStartSheet(baseSheet, 680)
    }
    
    
    @IBAction func onClickSlippage(_ sender: UIButton) {
        toMsg = nil
        dismissKeyboard()
        let baseSheet = BaseSheet(nibName: "BaseSheet", bundle: nil)
        baseSheet.sheetDelegate = self
        baseSheet.sheetType = .SelectSwapSlippage
        onStartSheet(baseSheet)
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        textField.shouldChange(charactersIn: range, replacementString: string, displayDecimal: inputMsAsset.decimals!)
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    @objc func textFieldDidChange(_ textField: UITextField) {
        onUpdateAmountView()
    }
    
    @objc func dismissKeyboard() {
        view.endEditing(true)
    }
    
    @IBAction func onClickHalf(_ sender: UIButton) {
        let halfAmount = availableAmount.dividing(by: NSDecimalNumber(2)).multiplying(byPowerOf10: -inputMsAsset.decimals!, withBehavior: getDivideHandler(inputMsAsset.decimals!))
        inputAmountTextField.text = halfAmount.stringValue
        onUpdateAmountView()
    }
    
    @IBAction func onClickMax(_ sender: UIButton) {
        let maxAmount = availableAmount.multiplying(byPowerOf10: -inputMsAsset.decimals!, withBehavior: getDivideHandler(inputMsAsset.decimals!))
        inputAmountTextField.text = maxAmount.stringValue
        onUpdateAmountView()
    }
    
    func onUpdateAmountView() {
        toMsg = nil
        if let text = inputAmountTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines).replacingOccurrences(of: ",", with: ".")  {
            swapBtn.isEnabled = false
            toggleBtn.isEnabled = false
            if (text.isEmpty) {
                outputAmountLabel.text = ""
                inputInvalidLabel.isHidden = false
                descriptionCardView.isHidden = true
                return
            }
            let userInput = NSDecimalNumber(string: text)
            if (NSDecimalNumber.notANumber == userInput) {
                outputAmountLabel.text = ""
                inputInvalidLabel.isHidden = false
                descriptionCardView.isHidden = true
                return
            }
            let inputAmount = userInput.multiplying(byPowerOf10: inputMsAsset.decimals!)
            if (inputAmount == NSDecimalNumber.zero || (availableAmount.compare(inputAmount).rawValue < 0)) {
                outputAmountLabel.text = ""
                inputInvalidLabel.isHidden = false
                descriptionCardView.isHidden = true
                return
            }
            inputInvalidLabel.isHidden = true
            Task {
                let route = try await fetchSkipRoute(inputAmount.stringValue)
//                print("route ", route)
                if (route["code"].int != nil) {
                    descriptionCardView.isHidden = true
                    errorCardView.isHidden = false
                    errorMsgLabel.text = route["message"].stringValue
                    return
                    
                } else if (route["amount_in"].stringValue == inputAmount.stringValue) {
                    let msg = try await fetchSkipMsg(route)
//                    print("msg ", msg)
                    if (msg["msgs"].arrayValue.count == 1) {
                        let slippage = NSDecimalNumber(string: "100").subtracting(NSDecimalNumber(string: skipSlippage))
                        let outputAmount = NSDecimalNumber(string: route["amount_out"].stringValue).multiplying(by: slippage).multiplying(byPowerOf10: -2, withBehavior: handler0Down)
                        WDP.dpCoin(outputMsAsset, outputAmount, nil, nil, outputAmountLabel, outputMsAsset.decimals)
                        
                        slippageLabel.text = skipSlippage + "%"
                        
                        let swapRate = outputAmount.dividing(by: inputAmount, withBehavior: handler6).multiplying(byPowerOf10: (inputMsAsset.decimals! - outputMsAsset.decimals!))
                        rateInputDenomLabel.text = inputMsAsset.symbol
                        rateInputAmountLanel.attributedText = WDP.dpAmount(NSDecimalNumber.one.stringValue, rateInputAmountLanel.font, 6)
                        rateOutputDenomLabel.text = outputMsAsset.symbol
                        rateOutputAmountLanel.attributedText = WDP.dpAmount(swapRate.stringValue, rateOutputAmountLanel.font, 6)
                        
                        if let feeMsAsset = BaseData.instance.getAsset(inputCosmosChain.apiName, txFee.amount[0].denom) {
                            WDP.dpCoin(feeMsAsset, txFee.amount[0], nil, feeDenomLabel, feeAmountLanel, feeMsAsset.decimals)
                        }
                        
                        venueLabel.text = route["swap_venue"]["name"].stringValue
                        
                        let inputMsPrice = BaseData.instance.getPrice(inputMsAsset.coinGeckoId)
                        let inputValue = inputMsPrice.multiplying(by: inputAmount).multiplying(byPowerOf10: -inputMsAsset.decimals!, withBehavior: handler6)
                        WDP.dpValue(inputValue, inputValueCurrency, inputValueLabel)
                        
                        let outputMsPrice = BaseData.instance.getPrice(outputMsAsset.coinGeckoId)
                        let outputValue = outputMsPrice.multiplying(by: outputAmount).multiplying(byPowerOf10: -outputMsAsset.decimals!, withBehavior: handler6)
                        WDP.dpValue(outputValue, outputValueCurrency, outputValueLabel)
                        
                        descriptionCardView.isHidden = false
                        onSimul(route, msg)
                        
                    } else {
                        //TODO msgs2개 이상일때 에러처리??
                        descriptionCardView.isHidden = true
                        errorCardView.isHidden = false
                        errorMsgLabel.text = "No Route"
                    }
                    
                }
            }
            
        }
    }
    
    @IBAction func onSwapToggle(_ sender: UIButton) {
        let tempChain = inputCosmosChain
        let tempAssetList = inputAssetList
        let tempAssetSelected = inputAssetSelected
        let tempMsAsset = inputMsAsset
        
        inputCosmosChain = outputCosmosChain
        inputAssetList = outputAssetList
        inputAssetSelected = outputAssetSelected
        inputMsAsset = outputMsAsset
        
        outputCosmosChain = tempChain
        outputAssetList = tempAssetList
        outputAssetSelected = tempAssetSelected
        outputMsAsset = tempMsAsset
        
        onReadyToUserInsert()
    }
    
    @IBAction func onClickSwap(_ sender: UIButton) {
        let pinVC = UIStoryboard.PincodeVC(self, .ForDataCheck)
        self.present(pinVC, animated: true)
    }
    
    
    func onBindSkipRouteReq(_ amount: String) -> JSON {
        var routeReq = JSON()
        routeReq["amount_in"].stringValue = amount
        routeReq["source_asset_chain_id"].stringValue = inputCosmosChain.chainId
        routeReq["source_asset_denom"].stringValue = inputMsAsset.denom!
        routeReq["dest_asset_chain_id"].stringValue = outputCosmosChain.chainId
        routeReq["dest_asset_denom"].stringValue = outputMsAsset.denom!
        routeReq["cumulative_affiliate_fee_bps"] = "100"
        routeReq["client_id"] = "cosmostation"
        return routeReq
    }
    
    func onBindSkipMsgReq(_ route: JSON) -> JSON {
        var msgReq = JSON()
        var address_list = [String]()
        route["chain_ids"].array?.forEach({ chain_Id in
            if let address = allCosmosChains.filter({ $0.chainId == chain_Id.stringValue && $0.isDefault == true }).first?.bechAddress {
                address_list.append(address)
            }
        })
        msgReq["address_list"].arrayObject = address_list
        msgReq["slippage_tolerance_percent"].stringValue = skipSlippage
        msgReq["amount_in"] = route["amount_in"]
        msgReq["source_asset_chain_id"] = route["source_asset_chain_id"]
        msgReq["source_asset_denom"] = route["source_asset_denom"]
        msgReq["amount_out"] = route["amount_out"]
        msgReq["dest_asset_chain_id"] = route["dest_asset_chain_id"]
        msgReq["dest_asset_denom"] = route["dest_asset_denom"]
        msgReq["operations"] = route["operations"]
        msgReq["client_id"] = "cosmostation"
        if let affiliate = getAffiliate(route["swap_venue"])  {
            msgReq["affiliates"].arrayObject = affiliate
        }
        return msgReq
    }
    
    func getBaseFee() -> Cosmos_Tx_V1beta1_Fee {
        let minFee = inputCosmosChain.getDefaultFeeCoins()[0]
        let feeCoin = Cosmos_Base_V1beta1_Coin.with {  $0.denom = minFee.denom; $0.amount = minFee.amount }
        return Cosmos_Tx_V1beta1_Fee.with {
            $0.gasLimit = UInt64(BASE_GAS_AMOUNT)!
            $0.amount = [feeCoin]
        }
    }
    
    func getAffiliate(_ venue: JSON) -> [JSON]? {
        if (venue["chain_id"].stringValue.contains("osmosis")) {
            var affiliate = JSON()
            affiliate["address"].stringValue = "osmo1clpqr4nrk4khgkxj78fcwwh6dl3uw4epasmvnj"
            affiliate["basis_points_fee"].stringValue = "100"
            return [affiliate]
        } else if (venue["chain_id"].stringValue.contains("neutron")) {
            var affiliate = JSON()
            affiliate["address"].stringValue = "neutron1clpqr4nrk4khgkxj78fcwwh6dl3uw4ep35p7l8"
            affiliate["basis_points_fee"].stringValue = "100"
            return [affiliate]
        }
        return nil
    }
    
    func onUpdateWithSimul(_ simul: Cosmos_Tx_V1beta1_SimulateResponse?, _ msg: JSON) {
        if let toGas = simul?.gasInfo.gasUsed {
            txFee.gasLimit = UInt64(Double(toGas) * inputCosmosChain.gasMultiply())
            let baseFeePosition = inputCosmosChain.getFeeBasePosition()
            if let gasRate = inputCosmosChain.getFeeInfos()[baseFeePosition].FeeDatas.filter({ $0.denom == txFee.amount[0].denom }).first {
                let gasLimit = NSDecimalNumber.init(value: txFee.gasLimit)
                let feeCoinAmount = gasRate.gasRate?.multiplying(by: gasLimit, withBehavior: handler0Up)
                txFee.amount[0].amount = feeCoinAmount!.stringValue
            }
        }
        if let feeMsAsset = BaseData.instance.getAsset(inputCosmosChain.apiName, txFee.amount[0].denom) {
            WDP.dpCoin(feeMsAsset, txFee.amount[0], nil, feeDenomLabel, feeAmountLanel, feeMsAsset.decimals)
        }
        toMsg = msg
        swapBtn.isEnabled = true
        toggleBtn.isEnabled = true
    }
    
    func onSimul(_ route: JSON, _ msg: JSON) {
        swapBtn.isEnabled = false
        toggleBtn.isEnabled = false
        let msgs = msg["msgs"].arrayValue[0]
        if (msgs["msg_type_url"].stringValue == "/ibc.applications.transfer.v1.MsgTransfer") {
            let inner_mag = try? JSON(data: Data(msgs["msg"].stringValue.utf8))
//            print("inner_mag ", inner_mag)
            Task {
                let channel = getConnection(inputCosmosChain)
                if let auth = try? await fetchAuth(channel, inputCosmosChain.bechAddress) {
                    do {
                        let simul = try await simulIbcSendTx(channel, auth!, onBindIbcSend(inner_mag!))
                        DispatchQueue.main.async {
                            self.onUpdateWithSimul(simul, msg)
                        }
                        
                    } catch {
                        DispatchQueue.main.async {
                            self.view.isUserInteractionEnabled = true
                            self.loadingView.isHidden = true
                            self.onShowToast("Error : " + "\n" + "\(error)")
                            self.toMsg = nil
                            self.swapBtn.isEnabled = false
                            self.toggleBtn.isEnabled = true
                            return
                        }
                    }
                }
            }
            
        } else if (msgs["msg_type_url"].stringValue == "/cosmwasm.wasm.v1.MsgExecuteContract") {
            let inner_mag = try? JSON(data: Data(msgs["msg"].stringValue.utf8))
//            print("inner_mag ", inner_mag)
            Task {
                let channel = getConnection(inputCosmosChain)
                if let auth = try? await fetchAuth(channel, inputCosmosChain.bechAddress) {
                    do {
                        let simul = try await simulWasmTx(channel, auth!, onBindWasm(inner_mag!))
                        DispatchQueue.main.async {
                            self.onUpdateWithSimul(simul, msg)
                        }
                        
                    } catch {
                        DispatchQueue.main.async {
                            self.view.isUserInteractionEnabled = true
                            self.loadingView.isHidden = true
                            self.onShowToast("Error : " + "\n" + "\(error)")
                            self.toMsg = nil
                            self.swapBtn.isEnabled = false
                            self.toggleBtn.isEnabled = true
                            return
                        }
                    }
                }
            }
        }
    }
    
    func onBindIbcSend(_ innerMsg: JSON) -> Ibc_Applications_Transfer_V1_MsgTransfer {
        let sendCoin = Cosmos_Base_V1beta1_Coin.with {
            $0.denom = innerMsg["token"]["denom"].stringValue
            $0.amount = innerMsg["token"]["amount"].stringValue
        }
        return Ibc_Applications_Transfer_V1_MsgTransfer.with {
            $0.sender = innerMsg["sender"].stringValue
            $0.receiver = innerMsg["receiver"].stringValue
            $0.sourceChannel = innerMsg["source_channel"].stringValue
            $0.sourcePort = innerMsg["source_port"].stringValue
            $0.timeoutTimestamp = innerMsg["timeout_timestamp"].uInt64Value
            $0.token = sendCoin
            $0.memo = innerMsg["memo"].stringValue
        }
    }
    
    func onBindWasm(_ innerMsg: JSON) -> Cosmwasm_Wasm_V1_MsgExecuteContract {
        let jsonMsgBase64 = try! innerMsg["msg"].rawData(options: [.sortedKeys, .withoutEscapingSlashes]).base64EncodedString()
        let fundCoin = Cosmos_Base_V1beta1_Coin.init(innerMsg["funds"].arrayValue[0]["denom"].stringValue, innerMsg["funds"].arrayValue[0]["amount"].stringValue)
        
        return Cosmwasm_Wasm_V1_MsgExecuteContract.with {
            $0.sender = innerMsg["sender"].stringValue
            $0.contract = innerMsg["contract"].stringValue
            $0.msg = Data(base64Encoded: jsonMsgBase64)!
            $0.funds = [fundCoin]
        }
    }
    
}

extension SwapStartVC: BaseSheetDelegate, PinDelegate {
    
    func onSelectedSheet(_ sheetType: SheetType?, _ result: Dictionary<String, Any>) {
        if (sheetType == .SelectSwapInputChain) {
            if let chainId = result["chainId"] as? String {
                if (inputCosmosChain.chainId != chainId) {
                    loadingView.isHidden = false
                    Task {
                        inputCosmosChain = skipChains.filter({ $0.chainId == chainId }).first!
                        inputAssetList.removeAll()
                        skipAssets?["chain_to_assets_map"][inputCosmosChain.chainId]["assets"].arrayValue.forEach({ json in
                            if BaseData.instance.getAsset(inputCosmosChain.apiName, json["denom"].stringValue) != nil {
                                inputAssetList.append(json)
                            }
                        })
                        inputAssetSelected = inputAssetList.filter { $0["denom"].stringValue == inputCosmosChain.stakeDenom }.first ?? inputAssetList[0]
                        
                        let inputChannel = getConnection(inputCosmosChain)
                        if let inputAuth = try? await fetchAuth(inputChannel, inputCosmosChain.bechAddress),
                           let inputBal = try? await fetchBalances(inputChannel, inputCosmosChain.bechAddress),
                           let inputParam = try? await inputCosmosChain.fetchChainParam() {
                            inputCosmosChain.mintscanChainParam = inputParam
                            inputCosmosChain.cosmosAuth = inputAuth?.account ?? Google_Protobuf_Any()
                            inputCosmosChain.cosmosBalances = inputBal!
                            WUtils.onParseVestingAccount(inputCosmosChain)
                        }
                        
                        DispatchQueue.main.async {
                            self.onReadyToUserInsert()
                        }
                    }
                }
            }
            
        } else if (sheetType == .SelectSwapOutputChain) {
            if let chainId = result["chainId"] as? String {
                if (outputCosmosChain.chainId != chainId) {
                    loadingView.isHidden = false
                    Task {
                        outputCosmosChain = skipChains.filter({ $0.chainId == chainId }).first!
                        outputAssetList.removeAll()
                        skipAssets?["chain_to_assets_map"][outputCosmosChain.chainId]["assets"].arrayValue.forEach({ json in
                            if BaseData.instance.getAsset(outputCosmosChain.apiName, json["denom"].stringValue) != nil {
                                outputAssetList.append(json)
                            }
                        })
                        outputAssetSelected = outputAssetList.filter { $0["denom"].stringValue == outputCosmosChain.stakeDenom }.first ?? outputAssetList[0]
                        
                        let outputChannel = getConnection(outputCosmosChain)
                        if let outputAuth = try? await fetchAuth(outputChannel, outputCosmosChain.bechAddress),
                           let outputBal = try? await fetchBalances(outputChannel, outputCosmosChain.bechAddress),
                           let outputParam = try? await outputCosmosChain.fetchChainParam() {
                            outputCosmosChain.mintscanChainParam = outputParam
                            outputCosmosChain.cosmosAuth = outputAuth?.account ?? Google_Protobuf_Any()
                            outputCosmosChain.cosmosBalances = outputBal!
                            WUtils.onParseVestingAccount(outputCosmosChain)
                        }
                        
                        DispatchQueue.main.async {
                            self.onReadyToUserInsert()
                        }
                    }
                }
            }
            
        } else if (sheetType == .SelectSwapInputAsset) {
            if let denom = result["denom"] as? String {
                if (inputAssetSelected["denom"].stringValue != denom) {
                    inputAssetSelected = inputAssetList.filter { $0["denom"].stringValue == denom }.first!
                    onReadyToUserInsert()
                }
            }
            
            
        } else if (sheetType == .SelectSwapOutputAsset) {
            if let denom = result["denom"] as? String {
                if (outputAssetSelected["denom"].stringValue != denom) {
                    outputAssetSelected = outputAssetList.filter { $0["denom"].stringValue == denom }.first!
                    onReadyToUserInsert()
                }
            }
            
        } else if (sheetType == .SelectSwapSlippage) {
            if let index = result["index"] as? Int {
                if (index == 0) {
                    skipSlippage = "1"
                } else if (index == 1) {
                    skipSlippage = "2"
                } else if (index == 2) {
                    skipSlippage = "5"
                }
                onUpdateAmountView()
            }
        }
    }
    
    func onPinResponse(_ request: LockType, _ result: UnLockResult) {
        if (result == .success) {
            view.isUserInteractionEnabled = false
            swapBtn.isEnabled = false
            loadingView.isHidden = false
            
            let msgs = toMsg!["msgs"].arrayValue[0]
            if (msgs["msg_type_url"].stringValue == "/ibc.applications.transfer.v1.MsgTransfer") {
                let inner_mag = try? JSON(data: Data(msgs["msg"].stringValue.utf8))
                Task {
                    let channel = getConnection(inputCosmosChain)
                    if let auth = try? await fetchAuth(channel, inputCosmosChain.bechAddress),
                       let response = try await broadcastIbcSendTx(channel, auth!, onBindIbcSend(inner_mag!)) {
                        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(500), execute: {
                            self.loadingView.isHidden = true
                            
                            let txResult = CosmosTxResult(nibName: "CosmosTxResult", bundle: nil)
                            txResult.selectedChain = self.inputCosmosChain
                            txResult.broadcastTxResponse = response
                            txResult.modalPresentationStyle = .fullScreen
                            self.present(txResult, animated: true)
                        })
                    }
                }
                
            } else if (msgs["msg_type_url"].stringValue == "/cosmwasm.wasm.v1.MsgExecuteContract") {
                let inner_mag = try? JSON(data: Data(msgs["msg"].stringValue.utf8))
                Task {
                    let channel = getConnection(inputCosmosChain)
                    if let auth = try? await fetchAuth(channel, inputCosmosChain.bechAddress),
                       let response = try await broadcastWasmTx(channel, auth!, onBindWasm(inner_mag!)) {
                        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(500), execute: {
                            self.loadingView.isHidden = true
                            
                            let txResult = CosmosTxResult(nibName: "CosmosTxResult", bundle: nil)
                            txResult.selectedChain = self.inputCosmosChain
                            txResult.broadcastTxResponse = response
                            txResult.modalPresentationStyle = .fullScreen
                            self.present(txResult, animated: true)
                        })
                    }
                }
            }
            
        }
    }
}


extension SwapStartVC {
    
    func fetchSkipChains() async throws -> JSON {
//        print("fetchSkipChains ", BaseNetWork.SkipChains())
        return try await AF.request(BaseNetWork.SkipChains(), method: .get).serializingDecodable(JSON.self).value
    }
    
    func fetchSkipAssets() async throws -> JSON {
//        print("fetchSkipAssets ", BaseNetWork.SkipAssets())
        return try await AF.request(BaseNetWork.SkipAssets(), method: .get).serializingDecodable(JSON.self).value
    }
    
    func fetchSkipRoute(_ amount: String) async throws -> JSON {
        let json = onBindSkipRouteReq(amount)
        return try await AF.request(BaseNetWork.SkipRoutes(), method: .post, parameters: json.dictionaryObject!, encoding: JSONEncoding.default, headers: [:]).serializingDecodable(JSON.self).value
    }
    
    func fetchSkipMsg(_ route: JSON) async throws -> JSON {
        let json = onBindSkipMsgReq(route)
        return try await AF.request(BaseNetWork.SkipMsg(), method: .post, parameters: json.dictionaryObject!, encoding: JSONEncoding.default, headers: [:]).serializingDecodable(JSON.self).value
    }
    
    
    func fetchAuth(_ channel: ClientConnection, _ address: String) async throws -> Cosmos_Auth_V1beta1_QueryAccountResponse? {
        let req = Cosmos_Auth_V1beta1_QueryAccountRequest.with { $0.address = address }
        return try? await Cosmos_Auth_V1beta1_QueryNIOClient(channel: channel).account(req, callOptions: getCallOptions()).response.get()
    }
    
    func fetchBalances(_ channel: ClientConnection, _ address: String) async throws -> [Cosmos_Base_V1beta1_Coin]? {
        let page = Cosmos_Base_Query_V1beta1_PageRequest.with { $0.limit = 2000 }
        let req = Cosmos_Bank_V1beta1_QueryAllBalancesRequest.with { $0.address = address; $0.pagination = page }
        return try? await Cosmos_Bank_V1beta1_QueryNIOClient(channel: channel).allBalances(req, callOptions: getCallOptions()).response.get().balances
    }
    
    //ibc Send
    func simulIbcSendTx(_ channel: ClientConnection, _ auth: Cosmos_Auth_V1beta1_QueryAccountResponse, _ ibcTransfer: Ibc_Applications_Transfer_V1_MsgTransfer) async throws -> Cosmos_Tx_V1beta1_SimulateResponse? {
        let simulTx = Signer.genIbcSendSimul(auth, ibcTransfer, txFee, "", inputCosmosChain)
        do {
            return try await Cosmos_Tx_V1beta1_ServiceNIOClient(channel: channel).simulate(simulTx, callOptions: getCallOptions()).response.get()
        } catch {
            throw error
        }
    }
    
    func broadcastIbcSendTx(_ channel: ClientConnection, _ auth: Cosmos_Auth_V1beta1_QueryAccountResponse, _ ibcTransfer: Ibc_Applications_Transfer_V1_MsgTransfer) async throws -> Cosmos_Base_Abci_V1beta1_TxResponse? {
        let reqTx = Signer.genIbcSendTx(auth, ibcTransfer, txFee, "", inputCosmosChain)
        return try? await Cosmos_Tx_V1beta1_ServiceNIOClient(channel: channel).broadcastTx(reqTx, callOptions: getCallOptions()).response.get().txResponse
    }
    
    //Wasm
    func simulWasmTx(_ channel: ClientConnection, _ auth: Cosmos_Auth_V1beta1_QueryAccountResponse, _ toWasm: Cosmwasm_Wasm_V1_MsgExecuteContract) async throws -> Cosmos_Tx_V1beta1_SimulateResponse? {
        let simulTx = Signer.genWasmSimul(auth, [toWasm], txFee, "", inputCosmosChain)
        do {
            return try await Cosmos_Tx_V1beta1_ServiceNIOClient(channel: channel).simulate(simulTx, callOptions: getCallOptions()).response.get()
        } catch {
            throw error
        }
    }
    
    func broadcastWasmTx(_ channel: ClientConnection, _ auth: Cosmos_Auth_V1beta1_QueryAccountResponse, _ toWasm: Cosmwasm_Wasm_V1_MsgExecuteContract) async throws -> Cosmos_Base_Abci_V1beta1_TxResponse? {
        let reqTx = Signer.genWasmTx(auth, [toWasm], txFee, "", inputCosmosChain)
        return try? await Cosmos_Tx_V1beta1_ServiceNIOClient(channel: channel).broadcastTx(reqTx, callOptions: getCallOptions()).response.get().txResponse
    }
    
    func getConnection(_ chain: CosmosClass) -> ClientConnection {
        let group = PlatformSupport.makeEventLoopGroup(loopCount: 1)
        return ClientConnection.usingPlatformAppropriateTLS(for: group).connect(host: chain.getGrpc().0, port: chain.getGrpc().1)
    }
    
    func getCallOptions() -> CallOptions {
        var callOptions = CallOptions()
        callOptions.timeLimit = TimeLimit.timeout(TimeAmount.milliseconds(5000))
        return callOptions
    }
}
