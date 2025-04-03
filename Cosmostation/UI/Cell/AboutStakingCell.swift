//
//  AboutStakingCell.swift
//  Cosmostation
//
//  Created by yongjoo jung on 2023/10/26.
//  Copyright © 2023 wannabit. All rights reserved.
//

import UIKit
import SwiftyJSON

class AboutStakingCell: UITableViewCell {
    @IBOutlet weak var rootView: CardViewCell!
    @IBOutlet weak var stakingDenomTitle: UILabel!
    @IBOutlet weak var stakingDenomLabel: UILabel!
    @IBOutlet weak var unbondingTimeTitle: UILabel!
    @IBOutlet weak var unbondingTimeLabel: UILabel!
    @IBOutlet weak var inflationTitle: UILabel!
    @IBOutlet weak var inflationLabel: UILabel!
    @IBOutlet weak var stakingAprTitle: UILabel!
    @IBOutlet weak var stakingAprLabel: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
        selectionStyle = .none
        stakingDenomTitle.text = NSLocalizedString("str_staking_asset", comment: "")
        unbondingTimeTitle.text = NSLocalizedString("str_unstake_period", comment: "")
        inflationTitle.text = NSLocalizedString("str_inflation", comment: "")
        stakingAprTitle.text = NSLocalizedString("str_est_apr", comment: "")
        stakingDenomLabel.text = "-"
        unbondingTimeLabel.text = "-" + " " + NSLocalizedString("str_days", comment: "")
        inflationLabel.text = "-"
        stakingAprLabel.text = "-"
    }
    
    override func prepareForReuse() {
        stakingDenomLabel.text = "-"
        unbondingTimeLabel.text = "-" + " " + NSLocalizedString("str_days", comment: "")
        inflationLabel.text = "-"
        stakingAprLabel.text = "-"
    }
    
    func onBindStakingInfo(_ chain: BaseChain, _ json: JSON) {
        if let symbol = json["params"]["chainlist_params"]["staking_asset_symbol"].string, chain.supportStaking {
            stakingDenomLabel.text = symbol
        }
        
        if chain is ChainZenrock {
            let unbondingSec = json["params"]["staking_params"]["Params"]["unbonding_time"].stringValue.filter({ $0.isNumber })
            if let time = UInt64(unbondingSec) {
                let unbondingDay = UInt16(time / 24 / 60 / 60)
                unbondingTimeLabel.text = String(unbondingDay) + " " + NSLocalizedString("str_days", comment: "")
            }
        } else if chain is ChainBabylon {
            unbondingTimeLabel.text = "Est." + "1 " + NSLocalizedString("str_days", comment: "")

        } else {
            let unbondingSec = json["params"]["staking_params"]["params"]["unbonding_time"].stringValue.filter({ $0.isNumber })
            if let time = UInt64(unbondingSec) {
                let unbondingDay = UInt16(time / 24 / 60 / 60)
                unbondingTimeLabel.text = String(unbondingDay) + " " + NSLocalizedString("str_days", comment: "")
            }
        }
        
        let nf = WUtils.getNumberFormatter(2)
        if let inflation = json["params"]["minting_inflation"]["inflation"].string {
            let formatInflation = nf.string(from: NSDecimalNumber(string: inflation).multiplying(byPowerOf10: 2))!
            inflationLabel.attributedText = WUtils.getDpAttributedString(formatInflation, 2, inflationLabel.font)
        }
        
        if let apr = json["params"]["apr"].string, apr != "0" {
            let formatApr = nf.string(from: NSDecimalNumber(string: apr).multiplying(byPowerOf10: 2))!
            stakingAprLabel.attributedText = WUtils.getDpAttributedString(formatApr, 2, stakingAprLabel.font)
        }
    }
    
    
    func onBindMajorInfo(_ chain: BaseChain, _ json: JSON) {
        if let suiChain = chain as? ChainSui {
            onBindSuiStakingInfo(suiChain, json)
        }
    }
    
    func onBindSuiStakingInfo(_ suiChain: ChainSui, _ json: JSON) {
        if let symbol = json["params"]["chainlist_params"]["main_asset_symbol"].string, suiChain.supportStaking {
            stakingDenomLabel.text = symbol
        }
        
        unbondingTimeLabel.text = NSLocalizedString("str_instant", comment: "")
        
        if let apy = suiChain.suiFetcher?.suiApys[0]["apy"].stringValue {
            let nf = WUtils.getNumberFormatter(2)
            let formatApr = nf.string(from: NSDecimalNumber(string: apy).multiplying(byPowerOf10: 2))!
            stakingAprLabel.attributedText = WUtils.getDpAttributedString(formatApr, 2, stakingAprLabel.font)
        }
    }
}
