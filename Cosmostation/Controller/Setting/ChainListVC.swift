//
//  ChainListVC.swift
//  Cosmostation
//
//  Created by yongjoo jung on 2023/09/17.
//  Copyright © 2023 wannabit. All rights reserved.
//

import UIKit
import Lottie

class ChainListVC: BaseVC, BaseSheetDelegate {
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var searchEmptyLayer: UIView!
    @IBOutlet weak var addChainBtn: BaseButton!
    @IBOutlet weak var loadingView: LottieAnimationView!
    
    var searchBar: UISearchBar?
    
    var allCosmosChains = [CosmosClass]()
    var searchCosmosChains = [CosmosClass]()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        loadingView.isHidden = true
        loadingView.animation = LottieAnimation.named("loading")
        loadingView.contentMode = .scaleAspectFit
        loadingView.loopMode = .loop
        loadingView.animationSpeed = 1.3
        loadingView.play()
        
        tableView.delegate = self
        tableView.dataSource = self
        tableView.separatorStyle = .none
        tableView.register(UINib(nibName: "ManageChainCell", bundle: nil), forCellReuseIdentifier: "ManageChainCell")
        tableView.rowHeight = UITableView.automaticDimension
        tableView.sectionHeaderTopPadding = 0.0
        
        searchBar = UISearchBar(frame: CGRect(x: 0, y: 0, width: self.view.frame.size.width, height: 44))
        searchBar?.searchTextField.textColor = .color01
        searchBar?.tintColor = UIColor.white
        searchBar?.barTintColor = UIColor.clear
        searchBar?.searchTextField.font = .fontSize14Bold
        searchBar?.backgroundImage = UIImage()
        searchBar?.delegate = self
        tableView.tableHeaderView = searchBar
        
        let dismissTap = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        dismissTap.cancelsTouchesInView = false
        view.addGestureRecognizer(dismissTap)
        
        onUpdateView()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        var contentOffset: CGPoint = tableView.contentOffset
        contentOffset.y += (tableView.tableHeaderView?.frame)!.height
        tableView.contentOffset = contentOffset
        tableView.isHidden = false
//        addChainBtn.isHidden = false
    }
    
    override func setLocalizedString() {
        navigationItem.title = NSLocalizedString("setting_chain_title", comment: "")
        addChainBtn.setTitle(NSLocalizedString("str_add_custom_chain", comment: ""), for: .normal)
    }
    
    func onUpdateView() {
        allCosmosChains.removeAll()
        ALLCOSMOSCLASS().filter({ $0.isDefault == true }).forEach { chain in
            if (!allCosmosChains.contains { $0.name == chain.name }) {
                allCosmosChains.append(chain)
            }
        }
        searchCosmosChains = allCosmosChains
        tableView.reloadData()
    }
    
    @objc func dismissKeyboard() {
        searchBar?.endEditing(true)
    }
    
    func onDisplayEndPointSheet(_ position: Int) {
        loadingView.isHidden = true
        let chain = searchCosmosChains[position]
        let baseSheet = BaseSheet(nibName: "BaseSheet", bundle: nil)
        baseSheet.targetChain = chain
        baseSheet.sheetDelegate = self
        baseSheet.sheetType = .SwitchEndpoint
        onStartSheet(baseSheet)
    }
    
    func onSelectedSheet(_ sheetType: SheetType?, _ result: Dictionary<String, Any>) {
        if (sheetType == .SwitchEndpoint) {
            if let index = result["index"] as? Int,
               let chainName = result["chainName"] as? String {
                let chain = searchCosmosChains.filter { $0.name == chainName }.first!
                let endpoint = chain.getChainParam()["grpc_endpoint"].arrayValue[index]["url"].stringValue
                BaseData.instance.setGrpcEndpoint(chain, endpoint)
                DispatchQueue.main.async {
                    self.tableView.reloadData()
                }
            }
        }
    }

    @IBAction func onClickAddChain(_ sender: UIButton) {
    }

}

extension ChainListVC: UITableViewDelegate, UITableViewDataSource, UISearchBarDelegate {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let view = BaseHeader(frame: CGRect(x: 0, y: 0, width: 0, height: 0))
        if (section == 0) {
            view.titleLabel.text = "Cosmos Class"
            view.cntLabel.text = String(allCosmosChains.count)
        }
        return view
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 40
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return searchCosmosChains.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier:"ManageChainCell") as! ManageChainCell
        cell.bindCosmosClassChain(searchCosmosChains[indexPath.row])
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let chain = searchCosmosChains[indexPath.row]
        if (chain is ChainBinanceBeacon || chain is ChainOkt60Keccak) {
            return
        }
        loadingView.isHidden = false
        if (chain.getChainParam().isEmpty == true) {
            Task {
                if let rawParam = try? await chain.fetchChainParam() {
                    chain.mintscanChainParam = rawParam
                }
                DispatchQueue.main.async {
                    self.onDisplayEndPointSheet(indexPath.row)
                }
            }
        } else {
            self.onDisplayEndPointSheet(indexPath.row)
        }
    }
    
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        searchBar?.endEditing(true)
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        searchCosmosChains = searchText.isEmpty ? allCosmosChains : allCosmosChains.filter { cosmosChain in
            return cosmosChain.name.range(of: searchText, options: .caseInsensitive, range: nil, locale: nil) != nil
        }
        searchEmptyLayer.isHidden = searchCosmosChains.count > 0
        tableView.reloadData()
    }
}
