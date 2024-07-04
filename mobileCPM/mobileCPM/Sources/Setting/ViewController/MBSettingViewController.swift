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
import llama
import UIKit
import SnapKit
import MBProgressHUD

/// 设置 VC
@objc(MBSettingViewController)
public class MBSettingViewController: UIViewController, UIGestureRecognizerDelegate {

    /// 这是由外部（home）传入的引用
    private var llamaState: LlamaState?

    /// 更新选中的模型
    var updateUsingModeltype: ((CurrentUsingModelType) -> Void)?

    /// 一个列表
    lazy var tableView: UITableView = {
        // grouped has section title
        let tv = UITableView(frame: .zero, style: .grouped)
        tv.register(MBSettingTableViewCell.self, forCellReuseIdentifier: "MBSettingTableViewCell")
        tv.estimatedRowHeight = 48
        tv.separatorStyle = .none
        tv.separatorColor = .clear
        tv.dataSource = self
        tv.delegate = self
        return tv
    }()
    
    /// 列表对应的数据源 [[]]
    var dataArray = [[MBSettingModel]]()

    /// 语言模型
    var paperplaneLanguageModelManager: MBModelDownloadHelper?

    /// 1.2B 语言模型
    var languageModelQ4_1Manager: MBModelDownloadHelper?

    // MARK: - view life cycle
    
    init(with llamaState: LlamaState) {
        self.llamaState = llamaState
        super.init(nibName: nil, bundle: nil)
    }
    
    public override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nil, bundle: nil)
    }
    
    // 这是指定的初始化方法
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()

        // 获取 AppDelegate 实例
        if let appDelegate = UIApplication.shared.delegate as? AppDelegate {
            self.llamaState = appDelegate.llamaState
        }

        // step 1, create ui
        setupSubViews()

        // step 2, 配置大模型
        setupModels()

        // 禁止熄屏
        UIApplication.shared.isIdleTimerDisabled = true
        
        // Enable the interactive pop gesture recognizer
        self.navigationController?.interactivePopGestureRecognizer?.isEnabled = true
        self.navigationController?.interactivePopGestureRecognizer?.delegate = self
    }
    
    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        // step 3, 配置 UI 数据
        loadTableViewData()
    }
    
    public override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // 允许熄屏
        UIApplication.shared.isIdleTimerDisabled = false
    }

    public func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        // If this view controller is the root view controller, prevent the gesture
        return self.navigationController?.viewControllers.count ?? 0 > 1
    }
    
    // MARK: - 创建子视图
    
    func setupSubViews() {
        self.title = "设置"
        
        let titleDict: [NSAttributedString.Key : Any] = [NSAttributedString.Key.foregroundColor: UIColor.black]
        self.navigationController?.navigationBar.titleTextAttributes = titleDict

        self.view.backgroundColor = UIColor.mb_color(with: "#F9FAFC")

        setupNavView()
        
        tableView.sectionHeaderTopPadding = 0
        tableView.backgroundColor = UIColor.mb_color(with: "#F9FAFC")
        tableView.contentInsetAdjustmentBehavior = .never
        tableView.contentInset = UIEdgeInsets(top: 20, left: 0, bottom: 0, right: 0)
        view.addSubview(tableView)
        tableView.snp.makeConstraints { make in
            make.top.equalTo(self.view.safeAreaLayoutGuide.snp.top)
            make.left.right.bottom.equalTo(self.view)
        }
    }
    
    func setupNavView() {
        // 白色顶导
        self.navigationController?.setNavigationBackgroundColor(UIColor.mb_color(with: "#F9FAFC"))
        
        var img = UIImage(named: "about")
        img = img?.mb_imageCompress(forWidth: img ?? UIImage(), targetWidth: 22)
        let right = UIBarButtonItem(image: img,
                                          style: .plain,
                                          target: self,
                                          action: #selector(handleRightNavIcon))
        self.navigationItem.rightBarButtonItem = right
    }
    
    // MARK: - 配置大模型
    func setupModels() {
        if let llamaState = llamaState {

            // 1.2B 语言模型
            let languageModelQ4_1URLString = MiniCPMModelConst.languageModelURLString
            languageModelQ4_1Manager = MBModelDownloadHelper(llamaState: llamaState,
                                                             modelName: MiniCPMModelConst.languageModelFileName,
                                                             modelUrl: languageModelQ4_1URLString,
                                                             filename: MiniCPMModelConst.languageModelFileName)

            // 断点+续传
            if let info = FDownLoaderManager.shareInstance().downLoaderInfo {

                // 恢复 1.2B 语言模型下载进度
                let languageModelQ4_1FileName = String(stringLiteral: languageModelQ4_1URLString).md5() ?? ""
                if let obj = info[languageModelQ4_1FileName] as? FDownLoader {
                    if obj.state == .downLoading {
                        // 1.2 语言模型继续下载
                        self.privateLanguageModelQ4_1Down()
                    }
                }
            }

        }
    }

    public override func viewWillTransition(to size: CGSize, with coordinator: any UIViewControllerTransitionCoordinator) {
        self.tableView.reloadData()
    }
    
    // MARK: - 加载数据
    func loadTableViewData() {
        
        dataArray.removeAll()

        var sectionA = [MBSettingModel]()
        
        // 依次选中的模型
        let lastSelectedModelString = UserDefaults.standard.string(forKey: "current_selected_model")
        
        self.llamaState?.currentUsingModelType = .Unknown
        
        if lastSelectedModelString == "language_paperplane" {
            // paperplane 语言模型
            self.llamaState?.currentUsingModelType = .paperPlane
        } else if lastSelectedModelString == "LanguageQ4_1" {
            // 1.2B 语言模型
            self.llamaState?.currentUsingModelType = .LanguageQ4_1
        }
        
        /*
         section 0 依次是：
         1.2B 语言模型
         paperplance
         */

        // 1.2B 语言模型
        let languageModelQ4_1 = MBSettingModel()
        languageModelQ4_1.title = MiniCPMModelConst.languageModelQ4_1DisplayedName
        languageModelQ4_1.icon = UIImage(named: "setting_model_icon")
        languageModelQ4_1.accessoryIcon = nil
        languageModelQ4_1.selectedIcon = UIImage(named: "setting_selected_icon")
        
        if self.llamaState?.currentUsingModelType == .LanguageQ4_1 {
            languageModelQ4_1Manager?.status = "selected"
        }
        
        if let status = languageModelQ4_1Manager?.status {
            if status == "download" {
                languageModelQ4_1.status = "none"
                languageModelQ4_1.statusString = "模型未下载"
            } else if status == "downloading" {
                languageModelQ4_1.status = "none"
                languageModelQ4_1.statusString = "下载中"
            } else if status == "downloaded" {
                languageModelQ4_1.status = "downloaded"
                languageModelQ4_1.statusString = nil
            } else if status == "selected" {
                languageModelQ4_1.status = "selected"
            }
        } else {
            languageModelQ4_1.status = "none"
            languageModelQ4_1.statusString = "模型未下载"
        }
        sectionA.append(languageModelQ4_1)

        // inset as section a
        dataArray.append(sectionA)

        tableView.reloadData()
    }
    
    // MARK: - 点击事件
    
    @objc public func handleRightNavIcon() {
        let about = MBAboutViewController()
        about.hidesBottomBarWhenPushed = true
        self.navigationController?.pushViewController(about, animated: true)
    }
}

extension MBSettingViewController: UITableViewDataSource {
    // MARK: - UITableView

    public func numberOfSections(in tableView: UITableView) -> Int {
        return dataArray.count
    }
    
    // 返回表格中的行数
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dataArray[section].count
    }
    
    public func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 48
    }
    
    // 设置每个单元格的内容
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "MBSettingTableViewCell", for: indexPath)
        cell.selectionStyle = .none
        
        if let c = cell as? MBSettingTableViewCell {
            let model = dataArray[indexPath.section][indexPath.row]
            c.configure(with: model)
        }
                
        return cell
    }
    
    public func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 1.0
    }
    
    public func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        return UIView()
    }
    
}

extension MBSettingViewController: UITableViewDelegate {
    
    // 处理用户点击单元格的事件
    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        if indexPath.section == 0 {
            
            if indexPath.row == 0 {
                // row 0 is language model 1.2B
                
                if languageModelQ4_1Manager?.status == "selected" {
                    return
                } else if languageModelQ4_1Manager?.status == "downloaded" {
                    // 表示模型已经下载完成，用户点击的话，直接就是切换的逻辑了
                    llamaState?.currentUsingModelType = .LanguageQ4_1
                    
                    // 选中 1.2B 语言模型
                    self.languageModelQ4_1Manager?.status = "selected"
                    if let cell = self.getLanguageModelQ4_1Cell() {
                        let model = cell.model
                        model?.status = "selected"
                        cell.configure(with: model)
                    }

                    self.showInfoTips("切换为 1.2B 语言模型")
                    UserDefaults.standard.setValue("LanguageQ4_1", forKey: "current_selected_model")
                    self.updateUsingModeltype?(.Unknown)
                } else {
                    let info = FDownLoaderManager.shareInstance().downLoaderInfo
                    
                    // 恢复 1.2B 语言模型下载进度
                    let languageModelQ4_1FileName = String(stringLiteral: MiniCPMModelConst.languageModelURLString).md5() ?? ""
                    if let obj = info?[languageModelQ4_1FileName] as? FDownLoader {
                        if obj.state == .downLoading || obj.state == .pauseFailed || obj.state == .pause {
                            // 1.2B 语言模型继续下载
                            self.privateLanguageModelQ4_1Down()
                        }
                    } else {
                        self.privateLanguageModelQ4_1Down()
                    }
                }
            }
        }
    }
    
    /// 删除功能
    public func tableView(_ tableView: UITableView,
                          commit editingStyle: UITableViewCell.EditingStyle,
                          forRowAt indexPath: IndexPath) {
        
        if editingStyle == .delete {
            if indexPath.row == 0 {
                // 删除 1.2B 语言模型
                self.privateDeleteLocalLanguageModelQ4_1(indexPath)
                UserDefaults.standard.removeObject(forKey: "current_selected_model")
            }
        }
    }
    
}

extension MBSettingViewController {

    /// 1.2B 语言模型下载
    func privateLanguageModelQ4_1Down() {
        languageModelQ4_1Manager?.downloadV2(completionBlock: { [weak self] status, progress in
            DispatchQueue.main.async {
                if let languageCell = self?.getLanguageModelQ4_1Cell() {
                    let languageModel = languageCell.model
                    if progress >= 1 {
                        languageModel?.status = "selected"
                        languageModel?.statusString = "完成"
                        
                        // 如果下载完，直接选中
                        UserDefaults.standard.setValue("LanguageQ4_1", forKey: "current_selected_model")
                    } else {
                        languageModel?.statusString = String(format: "%.2f%%", progress * 100)
                    }
                    languageCell.configure(with: languageModel)
                    
                }
            }
        })
    }
    
    /// 删除本地下载过的 1.2B 语言模型
    func privateDeleteLocalLanguageModelQ4_1(_ indexPath: IndexPath) {
        var languageModel: Model?
        var languageModelIndex = -1

        if let models = llamaState?.downloadedModels {
            for (index, item) in models.enumerated() {
                if item.filename == MiniCPMModelConst.languageModelFileName {
                    languageModel = item
                    languageModelIndex = index
                }
            }
        }

        if languageModelIndex == -1 {
            return
        }
        
        let fileURL = getDocumentsDirectory().appendingPathComponent(languageModel?.filename ?? "")
        do {
            try FileManager.default.removeItem(at: fileURL)
        } catch {
            #if DEBUG
            print("Error deleting file: \(error)")
            #endif
        }
        
        // Remove models from downloadedModels array
        if languageModelIndex != -1 {
            
            if let cell = getLanguageModelQ4_1Cell() {
                let model = cell.model
                model?.status = "none"
                model?.statusString = "模型未下载"
                cell.configure(with: model)
            }

            // 删除状态机中对应的模型
            llamaState?.downloadedModels.removeAll(where: { model in
                if model.filename == MiniCPMModelConst.languageModelFileName {
                    return true
                }

                return false
            })
            
            // user defaults 中也要删除
            // 1.2B 语言模型
            UserDefaults.standard.removeObject(forKey: "current_selected_model")
            showInfoTips("已删除")
        } else {
            UserDefaults.standard.removeObject(forKey: "current_selected_model")
            showInfoTips("模型未下载")
        }
    }

    /// 公共方法，获取沙箱 documents 目录
    func getDocumentsDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0]
    }

}

extension MBSettingViewController {
    
    /// 显示提示
    func showInfoTips(_ str: String?) {
        DispatchQueue.main.async {
            let hud = MBProgressHUD.showAdded(to: self.view, animated: true)
            hud.mode = .text
            hud.label.text = str
            hud.hide(animated: true, afterDelay: 1)
        }
    }

    /// 获取 1.2B 语言模型 cell
    func getLanguageModelQ4_1Cell() -> MBSettingTableViewCell? {
        if let cell = self.tableView.cellForRow(at: IndexPath(row: 0, section: 0)) as? MBSettingTableViewCell {
            return cell
        }
        return nil
    }
}
