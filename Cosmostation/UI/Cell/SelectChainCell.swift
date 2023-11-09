//
//  SelectChainCell.swift
//  Cosmostation
//
//  Created by yongjoo jung on 2023/08/25.
//  Copyright © 2023 wannabit. All rights reserved.
//

import UIKit
import SkeletonView

class SelectChainCell: UITableViewCell {
    
    @IBOutlet weak var rootView: FixCardView!
    @IBOutlet weak var logoImg1: UIImageView!
    @IBOutlet weak var logoImg2: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var hdPathLabel: UILabel!
    @IBOutlet weak var deprecatedLabel: UILabel!
    @IBOutlet weak var evmLabel: UILabel!
    @IBOutlet weak var valueLayer: UIStackView!
    @IBOutlet weak var currencyLabel: UILabel!
    @IBOutlet weak var valueLabel: UILabel!
    @IBOutlet weak var assetCntLayer: UIStackView!
    @IBOutlet weak var assetCntLabel: UILabel!
    
    
    let skeletonAnimation = SkeletonAnimationBuilder().makeSlidingAnimation(withDirection: .leftRight)
    
    override func awakeFromNib() {
        super.awakeFromNib()
        selectionStyle = .none
        valueLayer.showAnimatedGradientSkeleton(usingGradient: .init(colors: [.color05, .color04]), animation: skeletonAnimation, transition: .none)
        assetCntLayer.showAnimatedGradientSkeleton(usingGradient: .init(colors: [.color06, .color05]), animation: skeletonAnimation, transition: .none)
    }
    
    override func prepareForReuse() {
        deprecatedLabel.isHidden = true
        evmLabel.isHidden = true
    }
    
    var actionToggle: ((Bool) -> Void)? = nil
    @IBAction func onToggle(_ sender: UISwitch) {
        actionToggle?(sender.isOn)
    }
    
    func bindCosmosClassChain(_ account: BaseAccount, _ chain: CosmosClass, _ selectedList: [String]) {
        logoImg1.image =  UIImage.init(named: chain.logo1)
        logoImg2.image =  UIImage.init(named: chain.logo2)
        nameLabel.text = chain.name.uppercased()
        
        if (selectedList.contains(chain.tag)) {
            rootView.layer.borderWidth = 1.0
            rootView.layer.borderColor = UIColor.white.cgColor
        } else {
            rootView.layer.borderWidth = 0.5
            rootView.layer.borderColor = UIColor.white.withAlphaComponent(0.2).cgColor
        }
        
        if (account.type == .withMnemonic) {
            hdPathLabel.text = chain.getHDPath(account.lastHDPath)
            
            if (chain.evmCompatible) {
                evmLabel.isHidden = false
            } else if (!chain.isDefault) {
                deprecatedLabel.isHidden = false
            }
            
        } else {
            hdPathLabel.text = ""
            
            if (chain.evmCompatible) {
                evmLabel.isHidden = false
            }
        }
//        print("chain ", chain.name, "  ", chain.address)
        
        if let refAddress = BaseData.instance.selectRefAddress(account.id, chain.tag) {
//            print("refAddress ", refAddress)
            WDP.dpUSDValue(refAddress.lastUsdValue(), currencyLabel, valueLabel)
            assetCntLabel.text = String(refAddress.lastCoinCnt) + " Coins"
            
            valueLayer.hideSkeleton(reloadDataAfter: true, transition: SkeletonTransitionStyle.none)
            assetCntLayer.hideSkeleton(reloadDataAfter: true, transition: SkeletonTransitionStyle.none)
            
            
        } else {
            valueLayer.showAnimatedGradientSkeleton(usingGradient: .init(colors: [.color05, .color04]), animation: skeletonAnimation, transition: .none)
            assetCntLayer.showAnimatedGradientSkeleton(usingGradient: .init(colors: [.color06, .color05]), animation: skeletonAnimation, transition: .none)
        }
    }
}
