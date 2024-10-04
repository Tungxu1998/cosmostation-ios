//
//  SettingsVC.swift
//  Cosmostation
//
//  Created by yongjoo jung on 2023/08/09.
//  Copyright © 2023 wannabit. All rights reserved.
//

import UIKit
import Web3Core
import Lottie

class SettingsVC: BaseVC {
    
    @IBOutlet weak var tableView: UITableView!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.delegate = self
        tableView.dataSource = self
        tableView.separatorStyle = .none
        tableView.register(UINib(nibName: "SettingBaseCell", bundle: nil), forCellReuseIdentifier: "SettingBaseCell")
        tableView.register(UINib(nibName: "SettingPriceCell", bundle: nil), forCellReuseIdentifier: "SettingPriceCell")
        tableView.register(UINib(nibName: "SettingSwitchCell", bundle: nil), forCellReuseIdentifier: "SettingSwitchCell")
        tableView.rowHeight = UITableView.automaticDimension
        tableView.sectionHeaderTopPadding = 0.0
        
        baseAccount = BaseData.instance.baseAccount
        
        if (BaseData.instance.needPushRefresh()) {
            let request = BaseData.instance.getPushNoti()
            PushUtils().updateStatus(enable: request) { _, _ in }
        }
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        reloadRows(IndexPath(row: 0, section: 0))
        reloadRows(IndexPath(row: 5, section: 0))
        navigationItem.leftBarButtonItem = leftBarButton(baseAccount?.getRefreshName())
    }
    
    
}


extension SettingsVC: UITableViewDelegate, UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 4
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let view = BaseHeader(frame: CGRect(x: 0, y: 0, width: 0, height: 0))
        if (section == 0) {
            view.titleLabel.text = NSLocalizedString("setting_section_wallet", comment: "")
        } else if (section == 1) {
            view.titleLabel.text = NSLocalizedString("setting_section_general", comment: "")
        } else if (section == 2) {
            view.titleLabel.text = NSLocalizedString("setting_section_support", comment: "")
        } else if (section == 3) {
            view.titleLabel.text = NSLocalizedString("setting_section_about", comment: "")
        }
        view.cntLabel.text = ""
        return view
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 40
    }
    
    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        return UIView(frame: CGRect(origin: .zero, size: CGSize(width: CGFloat.leastNormalMagnitude, height: CGFloat.leastNormalMagnitude)))
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return .leastNormalMagnitude
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if (indexPath.section == 1 && indexPath.row == 7) {
            return 0
        } else if (indexPath.section == 3 && indexPath.row == 4 && !BaseData.instance.showEvenReview()) {
            return 0
        }
        return UITableView.automaticDimension
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if (section == 0) {
            return 6
        } else if (section == 1) {
            return 8
        } else if (section == 2) {
            return 3
        } else if (section == 3) {
            return 5
        }
        return 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let baseCell = tableView.dequeueReusableCell(withIdentifier:"SettingBaseCell") as! SettingBaseCell
        let priceCell = tableView.dequeueReusableCell(withIdentifier:"SettingPriceCell") as! SettingPriceCell
        let switchCell = tableView.dequeueReusableCell(withIdentifier:"SettingSwitchCell") as! SettingSwitchCell
        
        if (indexPath.section == 0) {
            if (indexPath.row == 0) {
                baseCell.onBindSetAccount()
                return baseCell
                
            } else if (indexPath.row == 1) {
                baseCell.onBindImportQR()
                return baseCell
                
            } else if (indexPath.row == 2) {
                switchCell.onBindHideLegacy()
                switchCell.actionToggle = { request in
                    if (request == BaseData.instance.getHideLegacy()) {
                        self.showWait()
                        BaseData.instance.setHideLegacy(!request)
                        DispatchQueue.main.async(execute: {
                            self.hideWait()
                            self.onStartMainTab()
                        });
                    }
                }
                return switchCell
                
            } else if (indexPath.row == 3) {
                switchCell.onBindTestnet()
                switchCell.actionToggle = { request in
                    if (request != BaseData.instance.getShowTestnet()) {
                        self.showWait()
                        BaseData.instance.setShowTestnet(request)
                        DispatchQueue.main.async(execute: {
                            self.hideWait()
                            self.onStartMainTab()
                        });
                    }
                }
                return switchCell
                
            } else if (indexPath.row == 4) {
                baseCell.onBindSetChain()
                return baseCell
                
            } else if (indexPath.row == 5) {
                baseCell.onBindSetAddressBook()
                return baseCell
            }
            
        } else if (indexPath.section == 1) {
            if (indexPath.row == 0) {
                baseCell.onBindSetLaungaue()
                return baseCell
                
            } else if (indexPath.row == 1) {
                baseCell.onBindSetCurrency()
                return baseCell
                
            } else if (indexPath.row == 2) {
                baseCell.onBindSetStyle()
                return baseCell
                
            } else if (indexPath.row == 3) {
                priceCell.onBindSetDpPrice()
                return priceCell
                
            } else if (indexPath.row == 4) {
                switchCell.onBindSetNotification()
                switchCell.actionToggle = { request in
                    self.showWait()
                    PushUtils().updateStatus(enable: request) { result, msg in
                        self.reloadRows(IndexPath(row: 4, section: 1))
                        self.hideWait()
                        self.onShowToast(msg)
                    }
                }
                return switchCell
                
            } else if (indexPath.row == 5) {
                switchCell.onBindSetAppLock()
                switchCell.actionToggle = { request in
                    if (request == false) {
                        let pinVC = UIStoryboard.PincodeVC(self, .ForDisableAppLock)
                        self.present(pinVC, animated: true)
                    } else {
                        BaseData.instance.setUsingAppLock(request)
                    }
                }
                return switchCell
                
            } else if (indexPath.row == 6) {
                switchCell.onBindSetBioAuth()
                switchCell.actionToggle = { request in
                    BaseData.instance.setUsingBioAuth(request)
                }
                return switchCell
                
            } else if (indexPath.row == 7) {
                baseCell.onBindSetAutoPass()
                return baseCell
            }
            
            
        } else if (indexPath.section == 2) {
            if (indexPath.row == 0) {
                baseCell.onBindSetGuide()
                return baseCell
                
            } else if (indexPath.row == 1) {
                baseCell.onBindSetHomePage()
                return baseCell
            } else if (indexPath.row == 2) {
                baseCell.onBindSetNotice()
                return baseCell
            }
            
        } else if (indexPath.section == 3) {
            if (indexPath.row == 0) {
                baseCell.onBindSetTerm()
                return baseCell
                
            } else if (indexPath.row == 1) {
                baseCell.onBindSetPrivacy()
                return baseCell
                
            } else if (indexPath.row == 2) {
                baseCell.onBindSetGithub()
                return baseCell
                
            } else if (indexPath.row == 3) {
                baseCell.onBindSetVersion()
                return baseCell
                
            } else if (indexPath.row == 4) {
                baseCell.onBindLabs()
                return baseCell
            }
        }
        return UITableViewCell()
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if (indexPath.section == 0) {
            if (indexPath.row == 0) {
                let accountListVC = AccountListVC(nibName: "AccountListVC", bundle: nil)
                accountListVC.hidesBottomBarWhenPushed = true
                self.navigationItem.title = ""
                self.navigationController?.pushViewController(accountListVC, animated: true)
                
            } else if (indexPath.row == 1) {
                let qrScanVC = QrScanVC(nibName: "QrScanVC", bundle: nil)
                qrScanVC.scanDelegate = self
                present(qrScanVC, animated: true)
                
            } else if (indexPath.row == 4) {
                let chainListVC = ChainListVC(nibName: "ChainListVC", bundle: nil)
                chainListVC.hidesBottomBarWhenPushed = true
                self.navigationItem.title = ""
                self.navigationController?.pushViewController(chainListVC, animated: true)
                
            } else if (indexPath.row == 5) {
                let addressBookVC = AddressBookListVC(nibName: "AddressBookListVC", bundle: nil)
                addressBookVC.hidesBottomBarWhenPushed = true
                self.navigationItem.title = ""
                self.navigationController?.pushViewController(addressBookVC, animated: true)
            }
            
        } else if (indexPath.section == 1) {
            if (indexPath.row == 0) {
                let baseSheet = BaseSheet(nibName: "BaseSheet", bundle: nil)
                baseSheet.sheetDelegate = self
                baseSheet.sheetType = .SwitchLanguage
                onStartSheet(baseSheet, 320, 0.6)
                
            } else if (indexPath.row == 1) {
                let baseSheet = BaseSheet(nibName: "BaseSheet", bundle: nil)
                baseSheet.sheetDelegate = self
                baseSheet.sheetType = .SwitchCurrency
                onStartSheet(baseSheet, 320, 0.9)
                
            } else if (indexPath.row == 2) {
                let baseSheet = BaseSheet(nibName: "BaseSheet", bundle: nil)
                baseSheet.sheetDelegate = self
                baseSheet.sheetType = .SwitchStyle
                guard let sheet = baseSheet.presentationController as? UISheetPresentationController else {
                    return
                }
                sheet.largestUndimmedDetentIdentifier = .large
                sheet.prefersGrabberVisible = true
                present(baseSheet, animated: true)
                
            } else if (indexPath.row == 3) {
                let baseSheet = BaseSheet(nibName: "BaseSheet", bundle: nil)
                baseSheet.sheetDelegate = self
                baseSheet.sheetType = .SwitchPriceColor
                onStartSheet(baseSheet, 240, 0.6)
                
            } else if (indexPath.row == 7) {
                let baseSheet = BaseSheet(nibName: "BaseSheet", bundle: nil)
                baseSheet.sheetDelegate = self
                baseSheet.sheetType = .SwitchAutoPass
                onStartSheet(baseSheet, 320, 0.6)
            }
            
        } else if (indexPath.section == 2) {
            if (indexPath.row == 0) {
                if (BaseData.instance.getLanguage() == 2) {
                    guard let url = URL(string: "https://www.cosmostation.io/kr/support/mobile") else { return }
                    onShowSafariWeb(url)
                } else if (BaseData.instance.getLanguage() == 3) {
                    guard let url = URL(string: "https://www.cosmostation.io/jp/support/mobile") else { return }
                    onShowSafariWeb(url)
                } else {
                    guard let url = URL(string: "https://www.cosmostation.io/en/support/mobile") else { return }
                    onShowSafariWeb(url)
                }
                
            } else if (indexPath.row == 1) {
                guard let url = URL(string: "https://www.cosmostation.io") else { return }
                onShowSafariWeb(url)
                
            } else if (indexPath.row == 2) {
                let vc = NoticeVC(nibName: "NoticeVC", bundle: nil)
                vc.hidesBottomBarWhenPushed = true
                navigationController?.pushViewController(vc, animated: true)
            }
            
        } else if (indexPath.section == 3) {
            if (indexPath.row == 0) {
                if (BaseData.instance.getLanguage() == 2) {
                    guard let url = URL(string: "https://cosmostation.io/service_kr") else { return }
                    onShowSafariWeb(url)
                } else {
                    guard let url = URL(string: "https://cosmostation.io/service_en") else { return }
                    onShowSafariWeb(url)
                }
                
            } else if (indexPath.row == 1) {
                guard let url = URL(string: "https://cosmostation.io/privacy-policy") else { return }
                onShowSafariWeb(url)
                
            } else if (indexPath.row == 2) {
                guard let url = URL(string: "https://github.com/cosmostation/cosmostation-ios") else { return }
                onShowSafariWeb(url)
                
            } else if (indexPath.row == 3) {
                let urlAppStore = URL(string: "itms-apps://itunes.apple.com/app/id1459830339")
                if (UIApplication.shared.canOpenURL(urlAppStore!)) {
                    UIApplication.shared.open(urlAppStore!, options: [:], completionHandler: nil)
                }
                
            } else if (indexPath.row == 4) {
                let labAlert = UIAlertController(title: "Lab", message: nil, preferredStyle: .alert)
                labAlert.addTextField { (textField) in
                    textField.placeholder = "insert"
                }
                labAlert.addAction(UIAlertAction(title: NSLocalizedString("cancel", comment: ""), style: .cancel, handler: { _ in
                    self.dismiss(animated: true, completion: nil)
                }))
                labAlert.addAction(UIAlertAction(title: NSLocalizedString("ok", comment: ""), style: .default, handler: { _ in
                    let text = labAlert.textFields![0].text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
                    guard let url = URL.init(string: text), UIApplication.shared.canOpenURL(url) else {
                        self.onShowToast(text)
                        return
                    }
                    
                    let dappDetail = DappDetailVC(nibName: "DappDetailVC", bundle: nil)
                    dappDetail.dappType = .INTERNAL_URL
                    dappDetail.dappUrl = url
                    dappDetail.modalPresentationStyle = .fullScreen
                    self.present(dappDetail, animated: true)
                }))
                present(labAlert, animated: true)
            }
        }
    }
}


extension SettingsVC: BaseSheetDelegate, QrScanDelegate, QrImportCheckKeyDelegate, PinDelegate {
    
    func leftBarButton(_ name: String?, _ imge: UIImage? = nil) -> UIBarButtonItem {
        let button = UIButton(type: .system)
        
        var title = AttributedString(name == nil ? "Account" : name!)
        title.font = .fontSize16Bold
        
        var config = UIButton.Configuration.plain()
        config.attributedTitle = title
        config.image = UIImage(named: "naviCon")
        config.imagePadding = 8
        config.contentInsets = .init(top: 0, leading: 0, bottom: 0, trailing: 0)
        config.titleLineBreakMode = .byTruncatingMiddle
        
        button.configuration = config
        button.addTarget(self, action: #selector(onClickSwitchAccount(_:)), for: .touchUpInside)

        return UIBarButtonItem(customView: button)
    }

    @objc func onClickSwitchAccount(_ sender: UIButton) {
        let baseSheet = BaseSheet(nibName: "BaseSheet", bundle: nil)
        baseSheet.sheetDelegate = self
        baseSheet.sheetType = .SwitchAccount
        onStartSheet(baseSheet, 320, 0.6)
    }

    public func onSelectedSheet(_ sheetType: SheetType?, _ result: Dictionary<String, Any>) {
        if (sheetType == .SwitchAccount) {
            if let toAddcountId = result["accountId"] as? Int64 {
                if (BaseData.instance.baseAccount?.id != toAddcountId) {
                    showWait()
                    DispatchQueue.global().async {
                        let toAccount = BaseData.instance.selectAccount(toAddcountId)
                        BaseData.instance.setLastAccount(toAccount!.id)
                        BaseData.instance.baseAccount = toAccount
                        
                        DispatchQueue.main.async(execute: {
                            self.hideWait()
                            self.onStartMainTab()
                        });
                    }
                }
            }
            
        } else if (sheetType == .SwitchLanguage) {
            if let index = result["index"] as? Int {
                if (BaseData.instance.getLanguage() != index) {
                    BaseData.instance.setLanguage(index)
                    DispatchQueue.main.async {
                        self.onStartMainTab()
                    }
                }
            }
            
        } else if (sheetType == .SwitchCurrency) {
            if let index = result["index"] as? Int {
                if (BaseData.instance.getCurrency() != index) {
                    BaseData.instance.setCurrency(index)
                    BaseNetWork().fetchPrices(true)
                    reloadRows(IndexPath(row: 1, section: 1))
                }
            }
            
        } else if (sheetType == .SwitchStyle) {
            if let index = result["index"] as? Int {
                if (BaseData.instance.getStyle() != index) {
                    showWaitDelay()
                    DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(2000), execute: {
                        BaseData.instance.setStyle(index)
                        BaseNetWork().fetchPrices(true)
                        self.reloadRows(IndexPath(row: 2, section: 1))
                        self.hideWait()
                    })
                }
            }
            
        } else if (sheetType == .SwitchPriceColor) {
            if let index = result["index"] as? Int {
                if (BaseData.instance.getPriceChaingColor() != index) {
                    BaseData.instance.setPriceChaingColor(index)
                    reloadRows(IndexPath(row: 3, section: 1))
                }
            }
            
        } else if (sheetType == .SwitchAutoPass) {
            if let index = result["index"] as? Int {
                if (BaseData.instance.getAutoPass() != index) {
                    BaseData.instance.setAutoPass(index)
                    reloadRows(IndexPath(row: 8, section: 1))
                }
            }
        }
    }
    
    
    func onPinResponse(_ request: LockType, _ result: UnLockResult) {
        if (request == .ForDisableAppLock) {
            if (result == .success) {
                BaseData.instance.setUsingAppLock(false)
            }
            reloadRows(IndexPath(row: 5, section: 1))
        }
    }
    
    func onScanned(_ result: String) {
        let scanedStr = result.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
        if let rawWords = BIP39.seedFromMmemonics(scanedStr, password: "", language: .english) {
            let importMnemonicCheckVC = ImportMnemonicCheckVC(nibName: "ImportMnemonicCheckVC", bundle: nil)
            importMnemonicCheckVC.mnemonic = scanedStr
            self.navigationItem.title = ""
            self.navigationController?.pushViewController(importMnemonicCheckVC, animated: true)
            return
        }
        
        let data = Data(base64Encoded: scanedStr.data(using: .utf8)!)
        if (data?.toHexString().starts(with: "53616c74") == true) {
//            if (data?.dataToHexString().starts(with: "53616c74") == true) {
            //start with salted
            let qrImportCheckKeySheet = QrImportCheckKeySheet(nibName: "QrImportCheckKeySheet", bundle: nil)
            qrImportCheckKeySheet.toDecryptString = scanedStr
            qrImportCheckKeySheet.qrImportCheckKeyDelegate = self
            onStartSheet(qrImportCheckKeySheet, 240, 0.6)
            return
        }
        onShowToast(NSLocalizedString("error_unknown_qr_code", comment: ""))
    }
    
    func onQrImportConfirmed(_ mnemonic: String) {
        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(1000), execute: {
            let importMnemonicCheckVC = ImportMnemonicCheckVC(nibName: "ImportMnemonicCheckVC", bundle: nil)
            importMnemonicCheckVC.mnemonic = mnemonic
            importMnemonicCheckVC.hidesBottomBarWhenPushed = true
            self.navigationItem.title = ""
            self.navigationController?.pushViewController(importMnemonicCheckVC, animated: true)
        });
    }
     
    func reloadRows(_ indexPath : IndexPath) {
        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(300), execute: {
            self.tableView.beginUpdates()
            self.tableView.reloadRows(at: [indexPath], with: .none)
            self.tableView.endUpdates()
        })
    }
}


