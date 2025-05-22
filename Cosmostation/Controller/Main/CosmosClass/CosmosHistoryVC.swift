//
//  CosmosHistoryVC.swift
//  Cosmostation
//
//  Created by yongjoo jung on 2023/08/22.
//  Copyright © 2023 wannabit. All rights reserved.
//

import UIKit
import Alamofire
import SwiftyJSON
import Lottie

class CosmosHistoryVC: BaseVC {
    
    @IBOutlet weak var loadingView: LottieAnimationView!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var emptyDataView: UIView!
    var refresher: UIRefreshControl!
    
    var selectedChain: BaseChain!
    var msHistoryGroup = Array<MintscanHistoryGroup>()
    var histoyID = ""
    var hasMore = false
    
    let BATCH_CNT = 30
    let EVM_BATCH_CNT = 20

    var evmHistoryGroup = Array<EvmHistoryGroup>()        //For EVM chain

    override func viewDidLoad() {
        super.viewDidLoad()
        
        baseAccount = BaseData.instance.baseAccount
        
        loadingView.isHidden = false
        loadingView.animation = LottieAnimation.named("loading")
        loadingView.contentMode = .scaleAspectFit
        loadingView.loopMode = .loop
        loadingView.animationSpeed = 1.3
        loadingView.play()
        
        tableView.delegate = self
        tableView.dataSource = self
        tableView.separatorStyle = .none
        tableView.register(UINib(nibName: "HistoryCell", bundle: nil), forCellReuseIdentifier: "HistoryCell")
        tableView.rowHeight = UITableView.automaticDimension
        tableView.sectionHeaderTopPadding = 0.0
        
        refresher = UIRefreshControl()
        refresher.addTarget(self, action: #selector(onRequestFetch), for: .valueChanged)
        refresher.tintColor = .color01
        tableView.addSubview(refresher)
        
        onRequestFetch()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        refresher.endRefreshing()
    }
    
    @objc func onRequestFetch() {
        histoyID = ""
        hasMore = false
        
        if selectedChain is ChainOktEVM {
            onFetchOktHistory(selectedChain.evmAddress!, histoyID)
        } else {
            if (!selectedChain.isSupportMintscan()) { return }
            onFetchMsHistory(selectedChain.bechAddress, histoyID)
        }
    }
    
    func onFetchMsHistory(_ address: String?, _ id: String) {
        let url = BaseNetWork.getAccountHistoryUrl(selectedChain!, address!)
        AF.request(url, method: .get, parameters: ["limit":String(BATCH_CNT), "search_after":id]).responseDecodable(of: [MintscanHistory].self, queue: .main, decoder: JSONDecoder()) { response in
            switch response.result {
            case .success(let value):
                if (id == "") { self.msHistoryGroup.removeAll() }
                if (value.count > 0) {
                    value.forEach { history in
                        let headerDate  = WDP.dpDate(history.header?.timestamp)
                        if let index = self.msHistoryGroup.firstIndex(where: { $0.date == headerDate }) {
                            self.msHistoryGroup[index].values.append(history)
                        } else {
                            self.msHistoryGroup.append(MintscanHistoryGroup.init(headerDate, [history]))
                        }
                    }
                    self.histoyID = value.last?.search_after ?? ""
                    self.hasMore = value.count >= self.BATCH_CNT
                    
                } else {
                    self.hasMore = false
                    self.histoyID = ""
                }
                
                self.loadingView.isHidden = true
                if (self.msHistoryGroup.count > 0) {
                    self.tableView.reloadData()
                    self.tableView.isHidden = false
                    self.emptyDataView.isHidden = true
                } else {
                    self.tableView.isHidden = true
                    self.emptyDataView.isHidden = false
                }
                
            case .failure:
                print("onFetchMsHistory error")
                self.loadingView.isHidden = true
                self.tableView.isHidden = true
                self.emptyDataView.isHidden = false
            }
            self.refresher.endRefreshing()
        }
    }
    
    func onFetchOktHistory(_ evmAddress: String, _ id: String) {
        let url = BaseNetWork.getAccountHistoryUrl(selectedChain!, evmAddress)
        AF.request(url, method: .get, parameters: ["search_after": histoyID, "limit" : "\(EVM_BATCH_CNT)"]).responseDecodable(of: JSON.self, queue: .main, decoder: JSONDecoder()) { response in
            if (id == "") { self.evmHistoryGroup.removeAll() }
            switch response.result {
            case .success(let value):
                if (value["txs"].count > 0) {
                    value["txs"].arrayValue.forEach { history in
                        let headerDate  = WDP.dpDate(history["txTime"].intValue)
                        if let index = self.evmHistoryGroup.firstIndex(where: { $0.date == headerDate }) {
                            self.evmHistoryGroup[index].values.append(history)
                        } else {
                            self.evmHistoryGroup.append(EvmHistoryGroup.init(headerDate, [history]))
                        }
                    }
                    self.histoyID = String(value["search_after"].intValue - 1)
                    self.hasMore = value["txs"].count >= self.EVM_BATCH_CNT
                    
                } else {
                    self.hasMore = false
                    self.histoyID = ""
                }
                self.loadingView.isHidden = true
                if (self.evmHistoryGroup.count > 0) {
                    self.tableView.reloadData()
                    self.tableView.isHidden = false
                    self.emptyDataView.isHidden = true
                } else {
                    self.tableView.isHidden = true
                    self.emptyDataView.isHidden = false
                }
                
            case .failure:
                print("onFetchOktHistory error")
                self.loadingView.isHidden = true
                self.tableView.isHidden = true
                self.emptyDataView.isHidden = false
            }
            self.refresher.endRefreshing()
        }
    }
    
}


extension CosmosHistoryVC: UITableViewDelegate, UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        if selectedChain is ChainOktEVM {
            return evmHistoryGroup.count
        } else {
            return msHistoryGroup.count
        }
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let view = BaseHeader(frame: CGRect(x: 0, y: 0, width: 0, height: 0))
        let today = WDP.dpDate(Int(Date().timeIntervalSince1970) * 1000)
        if selectedChain is ChainOktEVM {
            if (evmHistoryGroup[section].date == today) {
                view.titleLabel.text = "Today"
            } else {
                view.titleLabel.text = evmHistoryGroup[section].date
            }
            view.cntLabel.text = ""

        } else {
            if (msHistoryGroup[section].date == today) {
                view.titleLabel.text = "Today"
            } else {
                view.titleLabel.text = msHistoryGroup[section].date
            }
            view.cntLabel.text = ""
        }
        return view
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 40
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if selectedChain is ChainOktEVM {
            return evmHistoryGroup[section].values.count
            
        } else {
            return msHistoryGroup[section].values.count
        }
        
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier:"HistoryCell") as! HistoryCell
        if selectedChain is ChainOktEVM {
            let history = evmHistoryGroup[indexPath.section].values[indexPath.row]
            cell.bindEvmClassHistory(baseAccount, selectedChain, history)
            
        } else {
            let history = msHistoryGroup[indexPath.section].values[indexPath.row]
            cell.bindCosmosClassHistory(baseAccount, selectedChain, history)
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if selectedChain is ChainOktEVM {
            if (indexPath.section == self.evmHistoryGroup.count - 1
                && indexPath.row == self.evmHistoryGroup.last!.values.count - 1
                && hasMore == true) {
                hasMore = false
                onFetchOktHistory(selectedChain.evmAddress!, histoyID)
            }

        } else {
            if (indexPath.section == self.msHistoryGroup.count - 1
                && indexPath.row == self.msHistoryGroup.last!.values.count - 1
                && hasMore == true) {
                hasMore = false
                onFetchMsHistory(selectedChain.bechAddress, histoyID)
            }
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        var hash: String?
        if selectedChain is ChainOktEVM {
            hash = evmHistoryGroup[indexPath.section].values[indexPath.row]["txHash"].stringValue
        } else {
            if let cell = tableView.cellForRow(at: indexPath) as? HistoryCell {
                if (cell.msgsTitleLabel.text == NSLocalizedString("tx_send", comment: "")) {
                    let sendResultSheet = SendResultSheet(nibName: "SendResultSheet", bundle: nil)
                    sendResultSheet.selectedChain = selectedChain
                    sendResultSheet.selectedHistory = msHistoryGroup[indexPath.section].values[indexPath.row]
                    sendResultSheet.modalTransitionStyle = .coverVertical
                    self.present(sendResultSheet, animated: true)
                    return
                }
            }
            hash = msHistoryGroup[indexPath.section].values[indexPath.row].data?.txhash
        }
        guard let url = selectedChain.getExplorerTx(hash) else { return }
        self.onShowSafariWeb(url)
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

struct MintscanHistoryGroup {
    var date : String!
    var values = Array<MintscanHistory>()
    
    init(_ date: String!, _ values: Array<MintscanHistory>) {
        self.date = date
        self.values = values
    }
}
