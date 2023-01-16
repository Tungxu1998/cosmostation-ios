//
//  NFTsDAppViewController.swift
//  Cosmostation
//
//  Created by yongjoo jung on 2021/12/19.
//  Copyright © 2021 wannabit. All rights reserved.
//

import UIKit
import GRPC
import NIO
import SwiftProtobuf

class NFTsDAppViewController: BaseViewController {
    
    @IBOutlet weak var dAppsSegment: UISegmentedControl!
    @IBOutlet weak var myDenomsView: UIView!
    @IBOutlet weak var myNFTsView: UIView!
    
    var mMyIrisCollections = Array<Irismod_Nft_IDCollection>()
    var mMyCroCollections = Array<Chainmain_Nft_V1_IDCollection>()
    var mCollectionsPageTotalCnt: UInt64 = 0;
    var mCollectionsPageKey: Data?

    override func viewDidLoad() {
        super.viewDidLoad()
        self.account = BaseData.instance.selectAccountById(id: BaseData.instance.getRecentAccountId())
        self.chainType = ChainFactory.getChainType(account!.account_base_chain)
        self.chainConfig = ChainFactory.getChainConfig(chainType)
        
        myDenomsView.alpha = 0
        myNFTsView.alpha = 1
        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(500)) {
            self.onFetchNFTData()
        }
    }
    
    @IBAction func switchView(_ sender: UISegmentedControl) {
        if sender.selectedSegmentIndex == 0 {
            myDenomsView.alpha = 1
            myNFTsView.alpha = 0
        } else if sender.selectedSegmentIndex == 1 {
            myDenomsView.alpha = 0
            myNFTsView.alpha = 1
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.setNavigationBarHidden(false, animated: animated)
        self.navigationController?.navigationBar.topItem?.title = NSLocalizedString("title_nft", comment: "");
        self.navigationItem.title = NSLocalizedString("title_nft", comment: "");
        self.navigationController?.navigationBar.setBackgroundImage(UIImage(), for: UIBarMetrics.default)
        self.navigationController?.navigationBar.shadowImage = UIImage()
    }
    
    func onFetchFinished() {
        NotificationCenter.default.post(name: Notification.Name("NftFetchDone"), object: nil, userInfo: nil)
    }
    
    @objc func onFetchNFTData() {
        if (chainType == ChainType.IRIS_MAIN) {
            self.onFetchIrisNFT(self.account!.account_address, mCollectionsPageKey)
        } else if (chainType == ChainType.CRYPTO_MAIN) {
            self.onFetchCroNFT(self.account!.account_address, mCollectionsPageKey)
        }
    }
    
    func onFetchIrisNFT(_ owner: String, _ nextKey: Data?) {
        DispatchQueue.global().async {
            do {
                let channel = BaseNetWork.getConnection(self.chainType!, MultiThreadedEventLoopGroup(numberOfThreads: 1))!
                let page = Cosmos_Base_Query_V1beta1_PageRequest.with {
                    $0.countTotal = true
                    $0.limit = 1000
                    if let pageKey = nextKey {
                        $0.key = pageKey
                    }
                }
                let req = Irismod_Nft_QueryOwnerRequest.with {
                    $0.owner = owner
                    $0.pagination = page
                }
                if let response = try? Irismod_Nft_QueryClient(channel: channel).owner(req, callOptions: BaseNetWork.getCallOptions()).response.wait() {
                    response.owner.idCollections.forEach { id_collection in
                        self.mMyIrisCollections.append(id_collection)
                    }
                    if (nextKey == nil) {
                        self.mCollectionsPageTotalCnt = response.pagination.total
                    }
                    self.mCollectionsPageKey = response.pagination.nextKey
                }
                try channel.close().wait()

            } catch {
                print("onFetchIrisNFT failed: \(error)")
            }
            DispatchQueue.main.async(execute: {
                if (self.mCollectionsPageKey?.count == 0) {
                    self.onFetchFinished()
                } else {
                    self.onFetchIrisNFT(self.account!.account_address, self.mCollectionsPageKey)
                }
            });
        }
    }
    
    func onFetchCroNFT(_ owner: String, _ nextKey: Data?) {
        DispatchQueue.global().async {
            do {
                let channel = BaseNetWork.getConnection(self.chainType!, MultiThreadedEventLoopGroup(numberOfThreads: 1))!
                let page = Cosmos_Base_Query_V1beta1_PageRequest.with {
                    $0.countTotal = true
                    $0.limit = 1000
                    if let pageKey = nextKey {
                        $0.key = pageKey
                    }
                }
                let req = Chainmain_Nft_V1_QueryOwnerRequest.with {
                    $0.owner = owner
                    $0.pagination = page
                }
                
                if let response = try? Chainmain_Nft_V1_QueryClient(channel: channel).owner(req, callOptions: BaseNetWork.getCallOptions()).response.wait() {
                    response.owner.idCollections.forEach { id_collection in
                        self.mMyCroCollections.append(id_collection)
                    }
                    if (nextKey == nil) {
                        self.mCollectionsPageTotalCnt = response.pagination.total
                    }
                    self.mCollectionsPageKey = response.pagination.nextKey
                }
                try channel.close().wait()

            } catch {
                print("onFetchCroNFT failed: \(error)")
            }
            
            DispatchQueue.main.async(execute: {
                if (self.mCollectionsPageKey?.count == 0) {
                    self.onFetchFinished()
                } else {
                    self.onFetchIrisNFT(self.account!.account_address, self.mCollectionsPageKey)
                }
            });
        }
    }
    
}

extension WUtils {
    static func getNftDescription(_ text: String?) -> String {
        if let data = text?.data(using: .utf8) {
            do {
                let json = try JSONSerialization.jsonObject(with: data, options: []) as? NSDictionary
                
                if let description = json?.object(forKey: "description") as? String {
                    return description
                }
                if let description = json?.value(forKeyPath: "body.description") as? String {
                    return description
                }
            } catch {
                print(error.localizedDescription)
            }
        }
        return ""
    }
    
    static func getNftIssuer(_ text: String?) -> String {
        if let data = text?.data(using: .utf8) {
            do {
                let json = try JSONSerialization.jsonObject(with: data, options: []) as? NSDictionary
                
                if let issuerAddr = json?.object(forKey: "issuerAddr") as? String {
                    return issuerAddr
                }
                if let issuerAddr = json?.value(forKeyPath: "body.issuerAddr") as? String {
                    return issuerAddr
                }
            } catch {
                print(error.localizedDescription)
            }
        }
        return ""
    }
    
    static func checkNftDenomId(_ denom: String) -> Bool {
        let denomRegEx = "[a-z0-9]{4,20}"
        let denomPred = NSPredicate(format:"SELF MATCHES %@", denomRegEx)
        return denomPred.evaluate(with: denom)
    }
    
}

extension Data {
    var prettyJson: String? {
        guard let object = try? JSONSerialization.jsonObject(with: self, options: .allowFragments),
              let data = try? JSONSerialization.data(withJSONObject: object, options: [.sortedKeys, .prettyPrinted]),
              let prettyPrintedString = String(data: data, encoding:.utf8) else { return nil }

        return prettyPrintedString
    }
}

extension UIImage {
    // Repair Picture Rotation
    func fixOrientation() -> UIImage {
        if self.imageOrientation == .up {
            return self
        }
        
        var transform = CGAffineTransform.identity
        
        switch self.imageOrientation {
        case .down, .downMirrored:
            transform = transform.translatedBy(x: self.size.width, y: self.size.height)
            transform = transform.rotated(by: .pi)
        case .left, .leftMirrored:
            transform = transform.translatedBy(x: self.size.width, y: 0)
            transform = transform.rotated(by: .pi / 2)
        case .right, .rightMirrored:
            transform = transform.translatedBy(x: 0, y: self.size.height)
            transform = transform.rotated(by: -.pi / 2)
        default:
            break
        }
        
        switch self.imageOrientation {
        case .upMirrored, .downMirrored:
            transform = transform.translatedBy(x: self.size.width, y: 0)
            transform = transform.scaledBy(x: -1, y: 1)
        case .leftMirrored, .rightMirrored:
            transform = transform.translatedBy(x: self.size.height, y: 0);
            transform = transform.scaledBy(x: -1, y: 1)
        default:
            break
        }
        
        let ctx = CGContext(data: nil, width: Int(self.size.width), height: Int(self.size.height), bitsPerComponent: self.cgImage!.bitsPerComponent, bytesPerRow: 0, space: self.cgImage!.colorSpace!, bitmapInfo: self.cgImage!.bitmapInfo.rawValue)
        ctx?.concatenate(transform)
        
        switch self.imageOrientation {
        case .left, .leftMirrored, .right, .rightMirrored:
            ctx?.draw(self.cgImage!, in: CGRect(x: CGFloat(0), y: CGFloat(0), width: CGFloat(size.height), height: CGFloat(size.width)))
        default:
            ctx?.draw(self.cgImage!, in: CGRect(x: CGFloat(0), y: CGFloat(0), width: CGFloat(size.width), height: CGFloat(size.height)))
        }
        
        let cgimg: CGImage = (ctx?.makeImage())!
        let img = UIImage(cgImage: cgimg)
        
        return img
    }
}
