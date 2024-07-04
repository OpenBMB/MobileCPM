/*
 * Licensed to the Apache Software Foundation (ASF) under one or more
 * contributor license agreements.  See the NOTICE file distributed with
 * this work for additional information regarding copyright ownership.
 * The ASF licenses this file to You under the Apache License, Version 2.0
 * (the "License"); you may not use this file except in compliance with
 * the License.  You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

import Foundation
import UIKit

@objc(MBHomeViewController)
public class MBHomeViewController: UIViewController, MBHomeCellEventDelegate {
    
    var data: [MBHomeSectionModel]?
    
    var collectionView: UICollectionView?
    
    lazy var viewModel: MBHomeViewModel = {
        let vm = MBHomeViewModel()
        return vm
    }()

    public override func viewDidLoad() {
        super.viewDidLoad()
        setupParamter()
        setupUI()
    }
    
    public override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
    }
    
    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

    }
    
    public override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    public override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
    }
    
    deinit {
        print(">>>>>>>>> \(self) is deinit <<<<<<<")
    }
    
    public override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    fileprivate func setupUI() {
        let layout = WaterfallMutiSectionFlowLayout()
        layout.delegate = self
        collectionView = UICollectionView(frame: self.view.bounds, collectionViewLayout: layout)
        collectionView?.backgroundColor = .white
        collectionView?.delegate = self
        collectionView?.dataSource = self
        
        // 分别注册 waterfall cell
        collectionView?.register(MBHomeWaterfallCollectionViewCell.self, forCellWithReuseIdentifier: MBHomeWaterfallCollectionViewCell.identifiers)
        
        collectionView?.register(MBHomeSectionSupplementView.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: MBHomeSectionSupplementView.header)
        collectionView?.register(MBHomeSectionSupplementView.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionFooter, withReuseIdentifier: MBHomeSectionSupplementView.footer)
        if let c = collectionView {
            view.addSubview(c)
            c.snp.makeConstraints { make in
                make.edges.equalTo(self.view)
            }
        }
    }
    
    public override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()

        fetchData()
    }
    
    fileprivate func setupParamter() {
        self.title = "首页"
        let titleDict: [NSAttributedString.Key : Any] = [NSAttributedString.Key.foregroundColor: UIColor.black]
        self.navigationController?.navigationBar.titleTextAttributes = titleDict
    }
    
    func fetchData() {
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {

            self.viewModel.fetchHomeCard(withLoadMore: false) { [weak self] resultArray in
                guard let self = self else { return }
                
                if let ra = resultArray as? [MBHomeSectionModel] {
                    self.data = ra
                    self.collectionView?.reloadData()
                }
            } failure: { errCode, errMsg in
                debugPrint("%@, %@", errCode, errMsg)
            }

        }
        
    }
    
    private func sectionName(section: Int) -> String {
        switch section {
        case 0:
            return "Waterfall"
        default:
            return ""
        }
    }
}

extension MBHomeViewController: UICollectionViewDelegate, UICollectionViewDataSource {
    
    /// 有几个 section
    public func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    /// 每个 section 里有多少 cell
    public func collectionView(_ collectionView: UICollectionView,
                               numberOfItemsInSection section: Int) -> Int {
        switch section {
        case 0:
            // waterfall
            return self.data?[0].data.count ?? 0
        default:
            return 0
        }
    }
    
    /// 依据不同的 section 和 index 实例化 cell
    public func collectionView(_ collectionView: UICollectionView,
                               cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        switch indexPath.section {
        case 0:
            // waterfall cell
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: MBHomeWaterfallCollectionViewCell.identifiers, for: indexPath) as! MBHomeWaterfallCollectionViewCell
            
            if let curModel = self.data?[indexPath.section] as? MBHomeSectionModel {
                if let it = curModel.data[indexPath.row] as? MBHomeCardModel {
                    cell.clickDelegate = self
                    cell.bindWidthData(data: it)
                }
            }

            return cell
            
        default:
            return UICollectionViewCell()
        }
    }
    
    /// 每个 section 的 header or footer view
    public func collectionView(_ collectionView: UICollectionView,
                               viewForSupplementaryElementOfKind kind: String,
                               at indexPath: IndexPath) -> UICollectionReusableView {
        if kind == UICollectionView.elementKindSectionHeader {
            let header = collectionView.dequeueReusableSupplementaryView(ofKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: MBHomeSectionSupplementView.header, for: indexPath) as! MBHomeSectionSupplementView
            return header
        } else if kind == UICollectionView.elementKindSectionFooter {
            let footer = collectionView.dequeueReusableSupplementaryView(ofKind: UICollectionView.elementKindSectionFooter, withReuseIdentifier: MBHomeSectionSupplementView.footer, for: indexPath) as! MBHomeSectionSupplementView
            footer.backgroundColor = .clear
            return footer
        }
        return UICollectionReusableView()
    }
    
}

extension MBHomeViewController: WaterfallMutiSectionDelegate {
    
    /// 每个不同的 section 里 cell 的高度
    public func heightForRowAtIndexPath(collectionView collection: UICollectionView,
                                        layout: WaterfallMutiSectionFlowLayout,
                                        indexPath: IndexPath,
                                        itemWidth: CGFloat) -> CGFloat {
        switch indexPath.section {
        case 0:
            if let cellModel = self.data?[indexPath.section] {
                if let item = cellModel.data[indexPath.row] as? MBHomeCardModel {
                    return item.cellHeight
                }
            }
            
            return 0
        default:
            return 0
        }
    }
    
    /// 每个 section 并排几个 cell（几列）？
    public func columnNumber(collectionView collection: UICollectionView,
                             layout: WaterfallMutiSectionFlowLayout,
                             section: Int) -> Int {
        switch section {
        case 0:
            // waterfall 2 列
            return 2
        default:
            return 1
        }
    }
    
    /// 每个 section 如果有 header 的话，header view 的高度
    public func referenceSizeForHeader(collectionView collection: UICollectionView,
                                       layout: WaterfallMutiSectionFlowLayout,
                                       section: Int) -> CGSize {
        switch section {
        case 0:
            // loop header height
            return CGSize(width: self.view.frame.size.width, height: 0)
        default:
            return CGSize(width: self.view.frame.size.width, height: 0)
        }
    }
    
    /// 每个 section 如果有 footer 的话，footer view 的高度
    public func referenceSizeForFooter(collectionView collection: UICollectionView,
                                       layout: WaterfallMutiSectionFlowLayout,
                                       section: Int) -> CGSize {
        switch section {
        case 0:
            return CGSize(width: self.view.frame.size.width, height: 0)
        default:
            return CGSize(width: self.view.frame.size.width, height: 0)
        }
    }
    
    /// 每个 section 之间的间距是多少
    public func insetForSection(collectionView collection: UICollectionView,
                                layout: WaterfallMutiSectionFlowLayout,
                                section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
    }
    
    /// 同一个 section 内，左右 2 个 cell 的间距
    public func lineSpacing(collectionView collection: UICollectionView,
                            layout: WaterfallMutiSectionFlowLayout,
                            section: Int) -> CGFloat {
        
        if section == 1 {
            return 6
        }
        
        return 12
    }
    
    /// cell 距离 section 上下边缘的距离
    public func interitemSpacing(collectionView collection: UICollectionView,
                                 layout: WaterfallMutiSectionFlowLayout,
                                 section: Int) -> CGFloat {
        return 6
    }
    
    /// cell 距离 section 底部的距离
    public func spacingWithLastSection(collectionView collection: UICollectionView,
                                       layout: WaterfallMutiSectionFlowLayout,
                                       section: Int) -> CGFloat {
        return 6
    }
    
    // MARK: - 点击事件

    public func didClickCell(with object: MBHomeCardModel?, extra: [AnyHashable : Any]?) {
        
        if let appDelegate = UIApplication.shared.delegate as? AppDelegate {
            if appDelegate.llamaState != nil {
                
                let sysPrompt = object?.prompt ?? ""
                let prologue = object?.prologue ?? ""
                let name = object?.name ?? ""
                
                let vc = MBChatViewController(customParameter: ["prompt": sysPrompt,
                                                                "prologue": prologue,
                                                                "name": name])
                vc.hidesBottomBarWhenPushed = true
                self.navigationController?.pushViewController(vc, animated: true)
            }
        }
    }
}
