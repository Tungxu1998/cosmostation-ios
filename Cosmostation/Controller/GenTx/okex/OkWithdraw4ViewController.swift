//
//  OkWithdraw4ViewController.swift
//  Cosmostation
//
//  Created by yongjoo jung on 2022/06/23.
//  Copyright © 2022 wannabit. All rights reserved.
//

import UIKit
import Alamofire
import HDWalletKit

class OkWithdraw4ViewController: BaseViewController, PasswordViewDelegate {
    @IBOutlet weak var toWithdrawAmountLabel: UILabel!
    @IBOutlet weak var toWithdrawAmountDenom: UILabel!
    @IBOutlet weak var feeAmountLabel: UILabel!
    @IBOutlet weak var feeAmountDenom: UILabel!
    @IBOutlet weak var memoLabel: UILabel!
    @IBOutlet weak var beforeBtn: UIButton!
    @IBOutlet weak var confirmBtn: UIButton!
    
    var pageHolderVC: StepGenTxViewController!
    

    override func viewDidLoad() {
        super.viewDidLoad()
        self.account = BaseData.instance.selectAccountById(id: BaseData.instance.getRecentAccountId())
        self.chainType = ChainFactory.getChainType(account!.account_base_chain)
        self.chainConfig = ChainFactory.getChainConfig(chainType)
        self.pageHolderVC = self.parent as? StepGenTxViewController
        WDP.dpMainSymbol(chainConfig, toWithdrawAmountDenom)
        WDP.dpMainSymbol(chainConfig, feeAmountDenom)
    }
    
    @IBAction func onClickConfirm(_ sender: Any) {
        if (BaseData.instance.isAutoPass()) {
            self.onFetchAccountInfo(pageHolderVC.mAccount!)
        } else {
            self.navigationItem.title = ""
            self.navigationController!.view.layer.add(WUtils.getPasswordAni(), forKey: kCATransition)
            self.navigationController?.pushViewController(UIStoryboard.passwordViewController(delegate: self, target: PASSWORD_ACTION_CHECK_TX), animated: false)
        }
    }
    
    @IBAction func onClickBack(_ sender: Any) {
        self.beforeBtn.isUserInteractionEnabled = false
        self.confirmBtn.isUserInteractionEnabled = false
        pageHolderVC.onBeforePage()
    }
    
    override func enableUserInteraction() {
        self.onUpdateView()
        self.beforeBtn.isUserInteractionEnabled = true
        self.confirmBtn.isUserInteractionEnabled = true
    }
    
    func onUpdateView() {
        toWithdrawAmountLabel.attributedText = WDP.dpAmount(pageHolderVC.mOkToWithdraw.amount, toWithdrawAmountLabel.font, 0, 18)
        feeAmountLabel.attributedText = WDP.dpAmount((pageHolderVC.mFee?.amount[0].amount)!, feeAmountLabel.font, 0, 18)
        memoLabel.text = pageHolderVC.mMemo
    }
    
    func passwordResponse(result: Int) {
        if (result == PASSWORD_RESUKT_OK) {
            self.onFetchAccountInfo(pageHolderVC.mAccount!)
        }
    }

    func onFetchAccountInfo(_ account: Account) {
        self.showWaittingAlert()
        let request = Alamofire.request(BaseNetWork.accountInfoUrl(chainType, account.account_address), method: .get, parameters: [:], encoding: URLEncoding.default, headers: [:])
        request.responseJSON { (response) in
            switch response.result {
            case .success(let res):
                guard let info = res as? NSDictionary else {
                    _ = BaseData.instance.deleteBalance(account: account)
                    self.hideWaittingAlert()
                    self.onShowToast(NSLocalizedString("error_network", comment: ""))
                    return
                }
                let okAccountInfo = OkAccountInfo.init(info)
                _ = BaseData.instance.updateAccount(WUtils.getAccountWithOkAccountInfo(account, okAccountInfo))
                BaseData.instance.mOkAccountInfo = okAccountInfo
                self.onGenOkWithdrawTx()
                
            case .failure(let error):
                self.hideWaittingAlert()
                self.onShowToast(NSLocalizedString("error_network", comment: ""))
                print("onFetchAccountInfo ", error)
            }
        }
    }
    
    func onGenOkWithdrawTx() {
        DispatchQueue.global().async {
            let msg = MsgGenerator.genOkWithdarwMsg(self.account!.account_address,self.pageHolderVC.mOkToWithdraw)
            let postData = MsgGenerator.getPostData(self.chainConfig!, self.account!,
                                                    [msg],
                                                    self.pageHolderVC.privateKey!, self.pageHolderVC.publicKey!,
                                                    self.pageHolderVC.mFee!, self.pageHolderVC.mMemo!)
            
            DispatchQueue.main.async(execute: {
                let params = try! JSONSerialization.jsonObject(with: postData, options: .allowFragments) as? [String: Any]
                let request = Alamofire.request(BaseNetWork.broadcastUrl(self.chainType), method: .post, parameters: params, encoding: JSONEncoding.default, headers: [:])
                request.responseJSON { response in
                    var txResult = [String:Any]()
                    switch response.result {
                    case .success(let res):
                        if let result = res as? [String : Any]  {
                            txResult = result
                        }
                    case .failure(let error):
                        print("Withdraw error ", error)
                        if (response.response?.statusCode == 500) {
                            txResult["net_error"] = 500
                        }
                    }
                    if (self.waitAlert != nil) {
                        self.waitAlert?.dismiss(animated: true, completion: {
                            self.onStartTxDetail(txResult)
                        })
                    }
                }
            });
        }
    }

}

