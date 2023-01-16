//
//  AccountDetailViewController.swift
//  Cosmostation
//
//  Created by 정용주 on 2020/10/28.
//  Copyright © 2020 wannabit. All rights reserved.
//

import UIKit
import GRPC
import NIO
import SwiftProtobuf

class AccountDetailViewController: BaseViewController, UITableViewDelegate, UITableViewDataSource {
    
    @IBOutlet weak var myAccountNameLabel: UILabel!
    @IBOutlet weak var myAccountAddressCntLabel: UILabel!
    @IBOutlet weak var myAccountExpireTimeLabel: UILabel!
    @IBOutlet weak var myAccountResourceTableView: UITableView!
    @IBOutlet weak var myAccountEmptyView: UIView!
    
    var mMyDomain: String?
    var mMyAccount: String?
    var mMyDomainInfo_gRPC: Starnamed_X_Starname_V1beta1_Domain?
    var mMyAccountResolve_gRPC: Starnamed_X_Starname_V1beta1_QueryStarnameResponse?

    override func viewDidLoad() {
        super.viewDidLoad()
        self.account = BaseData.instance.selectAccountById(id: BaseData.instance.getRecentAccountId())
        self.chainType = ChainFactory.getChainType(account!.account_base_chain)
        self.chainConfig = ChainFactory.getChainConfig(chainType)
        self.balances = account!.account_balances
        
        self.myAccountResourceTableView.delegate = self
        self.myAccountResourceTableView.dataSource = self
        self.myAccountResourceTableView.register(UINib(nibName: "ResourceCell", bundle: nil), forCellReuseIdentifier: "ResourceCell")
        self.myAccountResourceTableView.separatorStyle = UITableViewCell.SeparatorStyle.none
        self.myAccountResourceTableView.rowHeight = UITableView.automaticDimension
        self.myAccountResourceTableView.estimatedRowHeight = UITableView.automaticDimension
        self.myAccountEmptyView.isHidden = true
        
        myAccountNameLabel.text = mMyAccount! + "*" + mMyDomain!
        self.onFetchData()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.setNavigationBarHidden(false, animated: animated)
        self.navigationController?.navigationBar.topItem?.title = NSLocalizedString("title_starname_account_detail", comment: "")
        self.navigationItem.title = NSLocalizedString("title_starname_account_detail", comment: "")
        self.navigationController?.navigationBar.setBackgroundImage(UIImage(), for: UIBarMetrics.default)
        self.navigationController?.navigationBar.shadowImage = UIImage()
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return mMyAccountResolve_gRPC?.account.resources.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell:ResourceCell? = tableView.dequeueReusableCell(withIdentifier:"ResourceCell") as? ResourceCell
        let resource = mMyAccountResolve_gRPC?.account.resources[indexPath.row]
        cell?.chainImg.af_setImage(withURL: getStarNameChainImgUrl(resource?.uri))
        cell?.chainName.text = getStarNameChainName(resource?.uri)
        cell?.chainAddress.text = resource?.resource
        return cell!
    }
    
    
    @IBAction func onClickDelete(_ sender: UIButton) {
        if (!account!.account_has_private) {
            self.onShowAddMenomicDialog()
            return
        }
        if (!BaseData.instance.isTxFeePayable(chainConfig)) {
            self.onShowToast(NSLocalizedString("error_not_enough_fee", comment: ""))
            return
        }
        
        let txVC = UIStoryboard(name: "GenTx", bundle: nil).instantiateViewController(withIdentifier: "TransactionViewController") as! TransactionViewController
        txVC.mType = TASK_TYPE_STARNAME_DELETE_ACCOUNT
        txVC.mStarnameDomain = mMyDomain
        txVC.mStarnameAccount = mMyAccount
        txVC.mStarnameTime = mMyAccountResolve_gRPC!.account.validUntil
        self.navigationItem.title = ""
        self.navigationController?.pushViewController(txVC, animated: true)
    }
    
    @IBAction func onClickRenew(_ sender: UIButton) {
        if (!account!.account_has_private) {
            self.onShowAddMenomicDialog()
            return
        }
        
        if (!BaseData.instance.isTxFeePayable(chainConfig)) {
            self.onShowToast(NSLocalizedString("error_not_enough_fee", comment: ""))
            return
        }
        let userAvailable = BaseData.instance.getAvailableAmount_gRPC(chainConfig!.stakeDenom)
        let starnameFee = WUtils.getStarNameRenewAccountFee(mMyDomainInfo_gRPC!.type)
        if (userAvailable.compare(starnameFee).rawValue < 0) {
            self.onShowToast(NSLocalizedString("error_not_enough_starname_fee", comment: ""))
            return
        }
        
        let txVC = UIStoryboard(name: "GenTx", bundle: nil).instantiateViewController(withIdentifier: "TransactionViewController") as! TransactionViewController
        txVC.mType = TASK_TYPE_STARNAME_RENEW_ACCOUNT
        txVC.mStarnameDomain = mMyDomain
        txVC.mStarnameAccount = mMyAccount
        txVC.mStarnameTime = mMyAccountResolve_gRPC?.account.validUntil
        txVC.mStarnameDomainType = mMyDomainInfo_gRPC?.type
        self.navigationItem.title = ""
        self.navigationController?.pushViewController(txVC, animated: true)
    }
    
    @IBAction func onClickReplace(_ sender: UIButton) {
        if (!account!.account_has_private) {
            self.onShowAddMenomicDialog()
            return
        }
        
        if (!BaseData.instance.isTxFeePayable(chainConfig)) {
            self.onShowToast(NSLocalizedString("error_not_enough_fee", comment: ""))
            return
        }
        let userAvailable = BaseData.instance.getAvailableAmount_gRPC(chainConfig!.stakeDenom)
        let starnameFee = WUtils.getReplaceFee()
        if (userAvailable.compare(starnameFee).rawValue < 0) {
            self.onShowToast(NSLocalizedString("error_not_enough_starname_fee", comment: ""))
            return
        }
        
        let txVC = UIStoryboard(name: "GenTx", bundle: nil).instantiateViewController(withIdentifier: "TransactionViewController") as! TransactionViewController
        txVC.mType = TASK_TYPE_STARNAME_REPLACE_RESOURCE
        txVC.mStarnameDomain = mMyDomain
        txVC.mStarnameAccount = mMyAccount
        txVC.mStarnameTime = mMyAccountResolve_gRPC?.account.validUntil
        txVC.mStarnameDomainType = mMyDomainInfo_gRPC?.type
        txVC.mStarnameResources_gRPC = mMyAccountResolve_gRPC?.account.resources ?? Array<Starnamed_X_Starname_V1beta1_Resource>()
        self.navigationItem.title = ""
        self.navigationController?.pushViewController(txVC, animated: true)
    }
    
    @IBAction func onClickProfile(_ sender: UIButton) {
        guard let url = URL(string: "https://starname.me/" + mMyAccount! + "*" + mMyDomain!) else { return }
        self.onShowSafariWeb(url)
    }
    
    var mFetchCnt = 0
    @objc func onFetchData() {
        if (self.mFetchCnt > 0)  {
            return
        }
        self.mFetchCnt = 2
        self.onFetchgRPCDomainInfo(mMyDomain!)
        self.onFetchgRPCResolve(mMyAccount!, mMyDomain!)
    }
    
    func onFetchFinished() {
        self.mFetchCnt = self.mFetchCnt - 1
        if (mFetchCnt <= 0) {
            if (mMyAccountResolve_gRPC?.hasAccount ?? false &&  mMyAccountResolve_gRPC?.account.resources.count ?? 0 > 0) {
                self.myAccountResourceTableView.reloadData()
                self.myAccountEmptyView.isHidden = true
                self.myAccountAddressCntLabel.text = String(mMyAccountResolve_gRPC!.account.resources.count)
            } else {
                self.myAccountResourceTableView.isHidden = true
                self.myAccountEmptyView.isHidden = false
                self.myAccountAddressCntLabel.text = "0"
            }
            let expireTime = mMyAccountResolve_gRPC!.account.validUntil * 1000
            myAccountExpireTimeLabel.text = WDP.dpTime(expireTime)
        }
    }
    
    func onFetchgRPCDomainInfo(_ domain: String) {
        DispatchQueue.global().async {
            do {
                let channel = BaseNetWork.getConnection(self.chainType!, MultiThreadedEventLoopGroup(numberOfThreads: 1))!
                let req = Starnamed_X_Starname_V1beta1_QueryDomainRequest.with { $0.name = domain }
                if let response = try? Starnamed_X_Starname_V1beta1_QueryClient(channel: channel).domain(req, callOptions:BaseNetWork.getCallOptions()).response.wait() {
                    self.mMyDomainInfo_gRPC = response.domain
                }
                try channel.close().wait()
                
            } catch {
                print("onFetchDomainInfo_gRPC failed: \(error)")
            }
            DispatchQueue.main.async(execute: { self.onFetchFinished() });
        }
    }
    
    func onFetchgRPCResolve(_ account: String, _ doamin: String) {
        DispatchQueue.global().async {
            do {
                let channel = BaseNetWork.getConnection(self.chainType!, MultiThreadedEventLoopGroup(numberOfThreads: 1))!
                let req = Starnamed_X_Starname_V1beta1_QueryStarnameRequest.with { $0.starname = account + "*" + doamin }
                if let response = try? Starnamed_X_Starname_V1beta1_QueryClient(channel: channel).starname(req, callOptions:BaseNetWork.getCallOptions()).response.wait() {
                    self.mMyAccountResolve_gRPC = response
                }
                try channel.close().wait()
                
            } catch {
                print("onFetchgRPCResolve failed: \(error)")
            }
            DispatchQueue.main.async(execute: { self.onFetchFinished() });
        }
    }
}
