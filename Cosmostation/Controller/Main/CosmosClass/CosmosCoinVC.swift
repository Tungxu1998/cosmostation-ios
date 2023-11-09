//
//  CosmosCoinVC.swift
//  Cosmostation
//
//  Created by yongjoo jung on 2023/08/22.
//  Copyright © 2023 wannabit. All rights reserved.
//

import UIKit
import SwiftyJSON

class CosmosCoinVC: BaseVC {
    
    @IBOutlet weak var tableView: UITableView!
    var refresher: UIRefreshControl!
    
    var selectedChain: CosmosClass!
    var nativeCoins = Array<Cosmos_Base_V1beta1_Coin>()                 // section 1
    var ibcCoins = Array<Cosmos_Base_V1beta1_Coin>()                    // section 2
    var bridgedCoins = Array<Cosmos_Base_V1beta1_Coin>()                // section 3
    
    var lcdBalances = Array<JSON>()                                     // section 1 for legacy lcd
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        baseAccount = BaseData.instance.baseAccount
        
        tableView.delegate = self
        tableView.dataSource = self
        tableView.separatorStyle = .none
        tableView.register(UINib(nibName: "AssetCosmosClassCell", bundle: nil), forCellReuseIdentifier: "AssetCosmosClassCell")
        tableView.register(UINib(nibName: "AssetCell", bundle: nil), forCellReuseIdentifier: "AssetCell")
        tableView.rowHeight = UITableView.automaticDimension
        tableView.sectionHeaderTopPadding = 0.0
        
        refresher = UIRefreshControl()
        refresher.addTarget(self, action: #selector(onRequestFetch), for: .valueChanged)
        refresher.tintColor = .color01
        tableView.addSubview(refresher)
        
        onSortAssets()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        NotificationCenter.default.addObserver(self, selector: #selector(self.onFetchDone(_:)), name: Notification.Name("FetchData"), object: nil)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        refresher.endRefreshing()
        NotificationCenter.default.removeObserver(self, name: Notification.Name("FetchData"), object: nil)
    } 
    
    @objc func onFetchDone(_ notification: NSNotification) {
        let tag = notification.object as! String
        if (selectedChain != nil && selectedChain.tag == tag) {
            refresher.endRefreshing()
            nativeCoins.removeAll()
            ibcCoins.removeAll()
            bridgedCoins.removeAll()
            lcdBalances.removeAll()
            onSortAssets()
        }
    }
    
    @objc func onRequestFetch() {
        if (selectedChain.fetched == false) {
            refresher.endRefreshing()
        } else {
            DispatchQueue.global().async {
                self.selectedChain.fetchData(self.baseAccount.id)
            }
        }
    }
    
    func onSortAssets() {
        Task {
            if let bnbChain = selectedChain as? ChainBinanceBeacon {
                bnbChain.lcdAccountInfo.bnbCoins?.forEach { balance in
                    lcdBalances.append(balance)
                }
                if (lcdBalances.filter { $0["symbol"].string == bnbChain.stakeDenom }.first == nil) {
                    lcdBalances.append(JSON(["symbol":"BNB", "free": "0"]))
                }
                lcdBalances.sort {
                    if ($0["symbol"].string == bnbChain.stakeDenom) { return true }
                    if ($1["symbol"].string == bnbChain.stakeDenom) { return false }
                    return false
                }
                
            } else if let oktChain = selectedChain as? ChainOkt60Keccak {
                oktChain.lcdAccountInfo.oktCoins?.forEach { balance in
                    lcdBalances.append(balance)
                }
                if (lcdBalances.filter { $0["denom"].string == oktChain.stakeDenom }.first == nil) {
                    lcdBalances.append(JSON(["denom":"okt", "amount": "0"]))
                }
                lcdBalances.sort {
                    if ($0["denom"].string == oktChain.stakeDenom) { return true }
                    if ($1["denom"].string == oktChain.stakeDenom) { return false }
                    return false
                }
                
            } else {
                selectedChain.cosmosBalances.forEach { coin in
                    let coinType = BaseData.instance.getAsset(selectedChain.apiName, coin.denom)?.type
                    if (coinType == "staking" || coinType == "native") {
                        nativeCoins.append(coin)
                    } else if (coinType == "bep" || coinType == "bridge") {
                        bridgedCoins.append(coin)
                    } else if (coinType == "ibc") {
                        ibcCoins.append(coin)
                    }
                }
                
                if (nativeCoins.filter { $0.denom == selectedChain.stakeDenom }.first == nil) {
                    nativeCoins.append(Cosmos_Base_V1beta1_Coin.with { $0.denom = selectedChain.stakeDenom; $0.amount = "0" })
                }
                nativeCoins.sort {
                    if ($0.denom == selectedChain.stakeDenom) { return true }
                    if ($1.denom == selectedChain.stakeDenom) { return false }
                    let value0 = selectedChain.balanceValue($0.denom)
                    let value1 = selectedChain.balanceValue($1.denom)
                    return value0.compare(value1).rawValue > 0 ? true : false
                }
                
                ibcCoins.sort {
                    let value0 = selectedChain.balanceValue($0.denom)
                    let value1 = selectedChain.balanceValue($1.denom)
                    return value0.compare(value1).rawValue > 0 ? true : false
                }
                
                bridgedCoins.sort {
                    let value0 = selectedChain.balanceValue($0.denom)
                    let value1 = selectedChain.balanceValue($1.denom)
                    return value0.compare(value1).rawValue > 0 ? true : false
                }
            }
            tableView.reloadData()
        }
    }
    
    func onBepSelectDialog(_ denom: String) {
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        alert.addAction(UIAlertAction(title: NSLocalizedString("cancel", comment: ""), style: UIAlertAction.Style.cancel, handler: nil))
        alert.addAction(UIAlertAction(title: NSLocalizedString("bep3_tranfser", comment: ""), style: UIAlertAction.Style.default, handler: { _ in
            self.onStartBep3TransferVC(denom)
        }))
        alert.addAction(UIAlertAction(title: NSLocalizedString("simple_tranfser", comment: ""), style: UIAlertAction.Style.default, handler: { _ in
            if (self.selectedChain is ChainBinanceBeacon) {
                self.onStartLegacyTransferVC(denom)
            } else {
                self.onStartTransferVC(denom)
            }
        }))
        self.present(alert, animated: true, completion: nil)
    }
    
    func onStartBep3TransferVC(_ denom: String) {
        let transfer = Bep3Transfer(nibName: "Bep3Transfer", bundle: nil)
        transfer.fromChain = selectedChain
        transfer.toSendDenom = denom
        transfer.modalTransitionStyle = .coverVertical
        self.present(transfer, animated: true)
    }
    
    func onStartTransferVC(_ denom: String) {
        let transfer = CosmosTransfer(nibName: "CosmosTransfer", bundle: nil)
        transfer.selectedChain = selectedChain
        transfer.toSendDenom = denom
        transfer.modalTransitionStyle = .coverVertical
        self.present(transfer, animated: true)
    }
    
    func onStartLegacyTransferVC(_ denom: String) {
        print("onStartLegacyTransferVC")
        let transfer = LegacyTransfer(nibName: "LegacyTransfer", bundle: nil)
        transfer.selectedChain = selectedChain
        transfer.toSendDenom = denom
        transfer.modalTransitionStyle = .coverVertical
        self.present(transfer, animated: true)
    }

}


extension CosmosCoinVC: UITableViewDelegate, UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        if (selectedChain is ChainBinanceBeacon || selectedChain is ChainOkt60Keccak) {
            return 1
        } else {
            return 3
        }
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let view = BaseHeader(frame: CGRect(x: 0, y: 0, width: 0, height: 0))
        if (selectedChain is ChainBinanceBeacon || selectedChain is ChainOkt60Keccak) {
            view.titleLabel.text = "Native Coins"
            view.cntLabel.text = String(lcdBalances.count)
            
        } else {
            if (section == 0 && nativeCoins.count > 0) {
                view.titleLabel.text = "Native Coins"
                view.cntLabel.text = String(nativeCoins.count)
                
            } else if (section == 1 && ibcCoins.count > 0) {
                view.titleLabel.text = "IBC Coins"
                view.cntLabel.text = String(ibcCoins.count)

            } else if (section == 2 && bridgedCoins.count > 0) {
                view.titleLabel.text = "Bridged Coins"
                view.cntLabel.text = String(bridgedCoins.count)
            }
        }
        return view
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if (selectedChain is ChainBinanceBeacon || selectedChain is ChainOkt60Keccak) {
            return 40
            
        } else {
            if (section == 0) {
                return (nativeCoins.count > 0) ? 40 : 0
            } else if (section == 1) {
                return (ibcCoins.count > 0) ? 40 : 0
            } else if (section == 2) {
                return (bridgedCoins.count > 0) ? 40 : 0
            }
        }
        return 0
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if (selectedChain is ChainBinanceBeacon || selectedChain is ChainOkt60Keccak) {
            return lcdBalances.count
            
        } else {
            if (section == 0) {
                return nativeCoins.count
            } else if (section == 1) {
                return ibcCoins.count
            } else if (section == 2) {
                return bridgedCoins.count
            }
        }
        return 0
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if (indexPath.section == 0 && indexPath.row == 0) {
            let cell = tableView.dequeueReusableCell(withIdentifier:"AssetCosmosClassCell") as! AssetCosmosClassCell
            cell.bindCosmosStakeAsset(selectedChain)
            return cell
            
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier:"AssetCell") as! AssetCell
            if (selectedChain is ChainBinanceBeacon) {
                cell.bindBeaconAsset(selectedChain, lcdBalances[indexPath.row])
            } else if (selectedChain is ChainOkt60Keccak) {
                cell.bindOktAsset(selectedChain, lcdBalances[indexPath.row])
            } else {
                cell.bindCosmosClassAsset(selectedChain, getCoinBySection(indexPath)!)
            }
            return cell
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if (selectedChain.isTxFeePayable() == false) {
            onShowToast(NSLocalizedString("error_not_enough_fee", comment: ""))
            return
        }
        if (selectedChain is ChainBinanceBeacon) {
            let sendDenom = lcdBalances[indexPath.row]["symbol"].stringValue
            if (WUtils.isHtlcSwappableCoin(selectedChain, sendDenom)) {
                onBepSelectDialog(sendDenom)
            } else{
                onStartLegacyTransferVC(lcdBalances[indexPath.row]["symbol"].stringValue)
            }
            return
            
        } else if (selectedChain is ChainOkt60Keccak) {
            onStartLegacyTransferVC(lcdBalances[indexPath.row]["denom"].stringValue)
            return
            
        } else {
            if (indexPath.section == 0) {
                onStartTransferVC(selectedChain.stakeDenom)
            } else if (indexPath.section == 1) {
                onStartTransferVC(ibcCoins[indexPath.row].denom)
            } else if (indexPath.section == 2) {
                if (selectedChain is ChainKava60) {
                    let sendDenom = bridgedCoins[indexPath.row].denom
                    if (WUtils.isHtlcSwappableCoin(selectedChain, sendDenom)) {
                        onBepSelectDialog(sendDenom)
                    } else {
                        onStartTransferVC(sendDenom)
                    }
                    
                } else {
                    onStartTransferVC(bridgedCoins[indexPath.row].denom)
                }
            }
        }
    }
    
    func getCoinBySection(_ indexPath: IndexPath) -> Cosmos_Base_V1beta1_Coin? {
        if (indexPath.section == 0) {
            return nativeCoins[indexPath.row]
        } else if (indexPath.section == 1) {
            return ibcCoins[indexPath.row]
        } else if (indexPath.section == 2) {
            return bridgedCoins[indexPath.row]
        }
        return nil
    }
    
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        for cell in tableView.visibleCells {
            let hiddenFrameHeight = scrollView.contentOffset.y + (navigationController?.navigationBar.frame.size.height ?? 44) - cell.frame.origin.y
            if (hiddenFrameHeight >= 0 || hiddenFrameHeight <= cell.frame.size.height) {
                maskCell(cell: cell, margin: Float(hiddenFrameHeight))
            }
        }
    }

    func maskCell(cell: UITableViewCell, margin: Float) {
        cell.layer.mask = visibilityMaskForCell(cell: cell, location: (margin / Float(cell.frame.size.height) ))
        cell.layer.masksToBounds = true
    }

    func visibilityMaskForCell(cell: UITableViewCell, location: Float) -> CAGradientLayer {
        let mask = CAGradientLayer()
        mask.frame = cell.bounds
        mask.colors = [UIColor(white: 1, alpha: 0).cgColor, UIColor(white: 1, alpha: 1).cgColor]
        mask.locations = [NSNumber(value: location), NSNumber(value: location)]
        return mask;
    }
}



extension JSON {
    var bnbCoins: [JSON]? {
        return self["balances"].array
    }
    
    func bnbCoin(_ position: Int) -> JSON? {
        return bnbCoins?[position]
    }
    
    var oktCoins: [JSON]? {
        return self["value","coins"].array
    }
    
    func oktCoin(_ position: Int) -> JSON? {
        return oktCoins?[position]
    }
    
}
