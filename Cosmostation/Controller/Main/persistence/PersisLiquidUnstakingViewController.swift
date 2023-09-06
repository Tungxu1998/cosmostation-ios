//
//  PersisLiquidUnstakingViewController.swift
//  Cosmostation
//
//  Created by 권혁준 on 2023/02/28.
//  Copyright © 2023 wannabit. All rights reserved.
//

import UIKit

class PersisLiquidUnstakingViewController: BaseViewController {
    
    @IBOutlet weak var inputCoinImg: UIImageView!
    @IBOutlet weak var inputCoinName: UILabel!
    @IBOutlet weak var inputCoinAmountLabel: UILabel!
    
    @IBOutlet weak var inputAmount: UILabel!
    @IBOutlet weak var inputDenom: UILabel!
    @IBOutlet weak var outputAmount: UILabel!
    @IBOutlet weak var outputDenom: UILabel!
    
    var pageHolderVC: PersisDappViewController!
    var cValue: String!
    var inputCoinDenom: String!
    var availableMaxAmount = NSDecimalNumber.zero
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.account = BaseData.instance.selectAccountById(id: BaseData.instance.getRecentAccountId())
        self.chainType = ChainFactory.getChainType(account!.account_base_chain)
        self.chainConfig = ChainFactory.getChainConfig(chainType)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        NotificationCenter.default.addObserver(self, selector: #selector(self.onCValueDone(_:)), name: Notification.Name("CValueDone"), object: nil)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        NotificationCenter.default.removeObserver(self, name: Notification.Name("CValueDone"), object: nil)
    }
    
    @objc func onCValueDone(_ notification: NSNotification) {
        self.pageHolderVC = self.parent as? PersisDappViewController
        self.cValue = pageHolderVC.cValue
        self.updateView()
    }
    
    func updateView() {
        self.inputCoinDenom = "stk/uatom"
        var outputCoinDenom = "ibc/C8A74ABBE2AF892E15680D916A7C22130585CE5704F9B17A10F184A90D53BECA"
        let inputCoinDecimal = BaseData.instance.mMintscanAssets.filter({ $0.denom == inputCoinDenom }).first?.decimals ?? 6
        
        WDP.dpSymbol(chainConfig, inputCoinDenom, inputCoinName)
        WDP.dpSymbolImg(chainConfig, inputCoinDenom, inputCoinImg)
        
        availableMaxAmount = BaseData.instance.getAvailableAmount_gRPC(inputCoinDenom!)
        inputCoinAmountLabel.attributedText = WDP.dpAmount(availableMaxAmount.stringValue, inputCoinAmountLabel.font!, inputCoinDecimal, inputCoinDecimal)
        
        inputAmount.attributedText = WDP.dpAmount(NSDecimalNumber.one.stringValue, inputAmount.font, 0, 6)
        WDP.dpSymbol(chainConfig, self.inputCoinDenom, inputDenom)
        let rate = NSDecimalNumber(string: self.cValue).multiplying(byPowerOf10: -18)
        let redeemFee = NSDecimalNumber.init(string: "0.01")
        let outAmount = NSDecimalNumber.one.dividing(by: rate, withBehavior: WUtils.handler12Down).subtracting(redeemFee)
        outputAmount.attributedText = WDP.dpAmount(outAmount.stringValue, outputAmount.font, 0, 6)
        WDP.dpSymbol(chainConfig, outputCoinDenom, outputDenom)
    }
    
    @IBAction func onClickRedeem(_ sender: UIButton) {
        if (!account!.account_has_private) {
            self.onShowAddMenomicDialog()
            return
        }
        
        if (availableMaxAmount.compare(NSDecimalNumber.zero).rawValue <= 0) {
            self.onShowToast(NSLocalizedString("error_not_enough_to_balance", comment: ""))
            return
        }
        
        let txVC = UIStoryboard(name: "GenTx", bundle: nil).instantiateViewController(withIdentifier: "TransactionViewController") as! TransactionViewController
        txVC.mType = TASK_TYPE_PERSIS_LIQUIDITY_REDEEM
        txVC.mSwapInDenom = self.inputCoinDenom
        self.navigationItem.title = ""
        self.navigationController?.pushViewController(txVC, animated: true)
    }
}
