//
//  BaseSheetCell.swift
//  Cosmostation
//
//  Created by yongjoo jung on 2023/09/12.
//  Copyright © 2023 wannabit. All rights reserved.
//

import UIKit

class BaseSheetCell: UITableViewCell {
    
    @IBOutlet weak var rootView: UIView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var checkedImg: UIImageView!

    override func awakeFromNib() {
        super.awakeFromNib()
        self.selectionStyle = .none
    }
    
    func onBindLanguage(_ position: Int) {
        titleLabel.text = Language.getLanguages()[position].description
        if (BaseData.instance.getLanguage() == position) {
            checkedImg.isHidden = false
        } else {
            checkedImg.isHidden = true
        }
    }
    
    func onBindAutoPass(_ position: Int) {
        titleLabel.text = AutoPass.getAutoPasses()[position].description
        if (BaseData.instance.getAutoPass() == position) {
            checkedImg.isHidden = false
        } else {
            checkedImg.isHidden = true
        }
    }
    
    func onBindVault(_ position: Int) {
        if (position == 0) {
            titleLabel.text = NSLocalizedString("title_vaults_deposit", comment: "")
        } else {
            titleLabel.text = NSLocalizedString("title_vaults_withdraw", comment: "")
        }
    }
    
    func onBindHard(_ position: Int, _ denom: String?) {
        if let symbol = BaseData.instance.mintscanAssets?.filter({ $0.denom == denom }).first?.symbol {
            if (position == 0) {
                titleLabel.text = String(format: NSLocalizedString("str_deposit_denom", comment: ""), symbol)
            } else if (position == 1) {
                titleLabel.text = String(format: NSLocalizedString("str_withdraw_denom", comment: ""), symbol)
            } else if (position == 2) {
                titleLabel.text = String(format: NSLocalizedString("str_borrow_denom", comment: ""), symbol)
            } else if (position == 3) {
                titleLabel.text = String(format: NSLocalizedString("str_repay_denom", comment: ""), symbol)
            }
        }
        
    }
    
    func onBindSwp(_ position: Int) {
        if (position == 0) {
            titleLabel.text = NSLocalizedString("title_pool_join", comment: "")
        } else if (position == 1) {
            titleLabel.text = NSLocalizedString("title_pool_exit", comment: "")
        }
    }
    
    func onBindMint(_ position: Int, _ type: String) {
        if (position == 0) {
            titleLabel.text = String(format: NSLocalizedString("str_deposit_denom", comment: ""), type.components(separatedBy: "-").first?.uppercased() ?? "")
        } else if (position == 1) {
            titleLabel.text = String(format: NSLocalizedString("str_withdraw_denom", comment: ""), type.components(separatedBy: "-").first?.uppercased() ?? "")
        } else if (position == 2) {
            titleLabel.text = String(format: NSLocalizedString("str_draw_debt_denom", comment: ""), "USDX")
        } else if (position == 3) {
            titleLabel.text = String(format: NSLocalizedString("str_repay_denom", comment: ""), "USDX")
        }
    }
    
    func onBindEarn(_ position: Int) {
        if (position == 0) {
            titleLabel.text = NSLocalizedString("title_add_liquidity", comment: "")
        } else {
            titleLabel.text = NSLocalizedString("title_remove_liquidity", comment: "")
        }
    }
    
    func onSkipSwapSlippage(_ position: Int, _ slippage: String?) {

        if (position == 0) {
            titleLabel.text = "1%"
        } else if (position == 1) {
            titleLabel.text = "3%"
        } else if (position == 2) {
            titleLabel.text = "5%"
        }
        
        if let slippage, slippage == titleLabel.text?.filter({ $0.isNumber }) {
            checkedImg.isHidden = false
        } else {
            checkedImg.isHidden = true
        }
    }
    
}
