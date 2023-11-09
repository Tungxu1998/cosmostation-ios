//
//  SelectBepRecipientCell.swift
//  Cosmostation
//
//  Created by yongjoo jung on 2023/10/09.
//  Copyright © 2023 wannabit. All rights reserved.
//

import UIKit

class SelectBepRecipientCell: UITableViewCell {
    
    @IBOutlet weak var chainImg: UIImageView!
    @IBOutlet weak var addressLabel: UILabel!
    @IBOutlet weak var availableAmountLabel: UILabel!
    @IBOutlet weak var availableDenomLabel: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
        self.selectionStyle = .none
    }
    
    func onBindBepRecipient(_ chain: CosmosClass) {
        if let bnbChain = chain as? ChainBinanceBeacon {
            chainImg.image =  UIImage.init(named: bnbChain.logo1)
            addressLabel.text = chain.bechAddress
            
            let availableAmount = bnbChain.lcdBalanceAmount(bnbChain.stakeDenom)
            availableAmountLabel?.attributedText = WDP.dpAmount(availableAmount.stringValue, availableAmountLabel!.font, 8)
            availableDenomLabel.text = "BNB"
            
        } else {
            chainImg.image =  UIImage.init(named: chain.logo1)
            addressLabel.text = chain.bechAddress
            
            let availableAmount = chain.balanceAmount(chain.stakeDenom).multiplying(byPowerOf10: -6)
            availableAmountLabel?.attributedText = WDP.dpAmount(availableAmount.stringValue, availableAmountLabel!.font, 6)
            availableDenomLabel.text = "KAVA"
        }
    }
    
}
