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

import UIKit
import llama
import SnapKit
import SwiftUI
import Combine
import MBProgressHUD
import HXPhotoPicker

/// 聊天 ViewController
@objc public class MBChatViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, UITextViewDelegate, UIGestureRecognizerDelegate {
        
    // MARK: - properties
    
    /// 当前正在使用的模型：有语言模型和多模态模型
    var currentUsingModelType: CurrentUsingModelType = .Unknown

    /// llama.cpp main executor
    var llamaState: LlamaState?

    /// subscriber for Combine
    public var dataSubscriber: AnyCancellable?

    /// subscriber for Combine
    public var perfLogSubscriber: AnyCancellable?

    /// 是否有过一轮图文对话，有的话，就可以直接对话，不用再发图了
    var hasImageAndTextConversation = false
    
    /// 是否在思考中？
    var thinking = false
    
    /// 是否是全屏编辑器
    var fullscreenEditor = false
    
    /// 加载多模态模型时 loading 计时、记录加载时长 log 用的一个 timer
    public var logTimer: Timer?
    public var logTimeSecond = 0
    
    /// 临时显示输出用的 output 区域
    lazy var outputLabel: UILabel = {
        let lb = UILabel()
        lb.font = UIFont.systemFont(ofSize: 16, weight: .regular)
        lb.backgroundColor = .white
        lb.textColor = .blue
        lb.textAlignment = .center
        lb.numberOfLines = 0
        lb.lineBreakMode = .byWordWrapping
        
        lb.isHidden = true
        
        return lb
    }()

    /// 这是一个列表
    lazy var tableView : UITableView = {
        let tv = UITableView(frame: self.view.bounds, style: .grouped)
        
        tv.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 124 + 140, right: 0)

        // 设置一个预估值
        tv.estimatedRowHeight = 34

        tv.backgroundColor = .white
        
        tv.separatorStyle = .none
        
        // 设置数据源和委托对象
        tv.dataSource = self
        tv.delegate = self
        
        // 注册一个标准的 UITableViewCell
        tv.register(MBTextTableViewCell.classForCoder(), forCellReuseIdentifier: "MBTextTableViewCell")

        // 注册 CustomHeaderView
        tv.register(MBHomeTableViewHeaderView.self, forHeaderFooterViewReuseIdentifier: "MBHomeTableViewHeaderView")
        
        return tv
    }()

    /// 列表对应的数组
    var dataArray = [MBChatModel]()
    
    /// 底部输入框总容器
    lazy var inputContainerView: UIView = {
        let v = UIView()
        v.backgroundColor = UIColor.mb_color(with: "#F9FAFC")
        return v
    }()
    
    /// 输入框外边的那个蓝色的
    lazy var inputRoundCornerView: UIView = {
        let v = UIView()
        v.backgroundColor = .white
        v.clipsToBounds = true
        v.layer.cornerRadius = 16
        return v
    }()

    /// 免责声明
    lazy var bottomDisclaimerLabel: UILabel = {
        let lb = UILabel()
        lb.text = "以上内容为AI生成，不代表开发者立场，请勿删除或修改本标记"
        if MBUtils.isDeviceIPad() {
            lb.font = UIFont.systemFont(ofSize: 12, weight: .regular)
        } else {
            lb.font = UIFont.systemFont(ofSize: 11, weight: .regular)
        }
        lb.textColor = UIColor.mb_color(with: "#8A8A8E")
        lb.textAlignment = .center
        lb.lineBreakMode = .byWordWrapping
        
        return lb
    }()
    
    /// 输入框
    public lazy var textInputView: UITextView = {
        let tv = UITextView()
        tv.font = UIFont.systemFont(ofSize: 16)
        tv.textContainerInset = UIEdgeInsets(top: 8, left: 0, bottom: 0, right: 0)
        tv.textColor = .black
        tv.backgroundColor = .white
        tv.returnKeyType = .send
        tv.delegate = self
        tv.autoresizingMask = .flexibleHeight
        return tv
    }()
    
    var placeholderLabel = UILabel()

    /// 发送按钮
    lazy var sendButton: UIButton = {
        let btn = UIButton()
        btn.setImage(UIImage(named: "send_icon"), for: .normal)
        btn.addTarget(self, action: #selector(handleSendText), for: .touchUpInside)
        btn.isEnabled = false
        return btn
    }()

    // 记录用户输入
    var latestUserInputText = ""
    
    /// 键盘的高度
    var keyboardHeight: CGFloat = 0

    /// 输出时暂停和继续的 popup view
    lazy var floatingActionView: MBFloatingActionView = {
        let v = MBFloatingActionView()
        return v
    }()

    /// 这是个蒙层，输入框进入全屏时，覆盖在顶导上用的
    public lazy var topNavGrayMaskView: UIView = {
        let v = UIView()
        v.backgroundColor = UIColor.black.withAlphaComponent(0.15)
        return v
    }()
    
    /// 外部透传来的参数
    var customParameter: [AnyHashable : Any]?
    
    // MARK: - view life cycle
        
    // Custom initializer
    public init(customParameter: [AnyHashable : Any]?) {
        self.customParameter = customParameter
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()

        self.view.backgroundColor = UIColor.mb_color(with: "#F9FAFC")

        Task {
            // 获取 AppDelegate 实例
            if let appDelegate = UIApplication.shared.delegate as? AppDelegate {
                self.llamaState = appDelegate.llamaState
            }

            // load model
            prepareModel()

            // 订阅大模型的输出
            self.subscriberLlamaMessageLog()
        }

        // create all sub views
        setupSubViews()

        // 添加观察者来监听键盘的显示和隐藏事件
        NotificationCenter.default.addObserver(self, 
                                               selector: #selector(keyboardWillShow(notification:)),
                                               name: UIResponder.keyboardWillShowNotification,
                                               object: nil)
        NotificationCenter.default.addObserver(self, 
                                               selector: #selector(keyboardWillHide(notification:)),
                                               name: UIResponder.keyboardWillHideNotification,
                                               object: nil)
        
        // Enable the interactive pop gesture recognizer
        self.navigationController?.interactivePopGestureRecognizer?.isEnabled = true
        self.navigationController?.interactivePopGestureRecognizer?.delegate = self
    }
    
    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    public func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        // If this view controller is the root view controller, prevent the gesture
        return self.navigationController?.viewControllers.count ?? 0 > 1
    }

    // 销毁时移除观察者
    deinit {
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    // MARK: - create sub views
    func setupSubViews() {
        
        updateNavTitle()
        
        // create nav bar views
        setupNavBarViews()
                
        // place holder
        setupPlaceholder()
        
        // create chat list view
        setupTableView()
        
        // create input view
        setupInputView();

        // create tmp output view
        setupOutputViews()
        
        // 创建
        setupFloatingActionView()
    }
    
    /// 更新顶导标题
    func updateNavTitle() {
        let lastSelectedModelString = UserDefaults.standard.value(forKey: "current_selected_model") as? String ?? ""
        var modelDisplayedName = ""
        if lastSelectedModelString == "language_paperplane" {
            // 1.2B 语言模型
            modelDisplayedName = MiniCPMModelConst.paperplaneModelDisplayedName
        }
        
        if !modelDisplayedName.isEmpty {
            self.title = "MiniCPM（当前模型：\(modelDisplayedName)）"
        } else {
            self.title = "MiniCPM"
        }
    }
    
    func setupNavBarViews() {

        let titleDict: [NSAttributedString.Key : Any] = [NSAttributedString.Key.foregroundColor: UIColor.black]
        self.navigationController?.navigationBar.titleTextAttributes = titleDict
                
        var img = UIImage(named: "back_icon")
        img = img?.mb_imageCompress(forWidth: img ?? UIImage(), targetWidth: 22)
        let leftNavIcon = UIBarButtonItem(image: img,
                                          style: .plain,
                                          target: self,
                                          action: #selector(handleLeftNavIcon))
        self.navigationItem.leftBarButtonItem = leftNavIcon
        self.navigationItem.leftBarButtonItem?.tintColor = .black
        
        self.navigationController?.navigationBar.backgroundColor = .white

        // delete icon
        let deleteButton = UIBarButtonItem(image: UIImage(named: "delete_icon"),
                                           style: .plain,
                                           target: self,
                                           action: #selector(deleteButtonTapped))
        deleteButton.tintColor = UIColor.mb_color(with: "#FF3B30")
        
        // 设置 NavigationItem 的 rightBarButtonItem 属性
        self.navigationItem.rightBarButtonItems = [deleteButton]
        
        // 白色顶导
        self.navigationController?.setNavigationBackgroundColor(UIColor.mb_color(with: "#F9FAFC"))
    }
    
    func setupTableView() {
        // 添加 UITableView 到当前视图
        tableView.contentInsetAdjustmentBehavior = .never
        self.view.addSubview(tableView)
        tableView.backgroundColor = UIColor.mb_color(with: "#F9FAFC")
        tableView.snp.makeConstraints { make in
            make.top.equalTo(0)
            make.left.right.equalTo(self.view)
            make.bottom.equalTo(self.view.snp.bottom)
        }
    }
    
    func setupInputView() {
        
        var inputViewMargin: CGFloat = 120
        
        if MBUtils.isDeviceIPhone() {
            inputViewMargin = 24
        }

        let tapResignKeyboardGesture = UITapGestureRecognizer(target: self, action: #selector(handleResignKeyboard))
        self.inputContainerView.isUserInteractionEnabled = true
        self.inputContainerView.addGestureRecognizer(tapResignKeyboardGesture)
        self.view.addSubview(self.inputContainerView)
        self.inputContainerView.snp.makeConstraints { make in
            make.left.equalTo(0)
            make.right.equalTo(0)
            make.height.equalTo(130)
            make.bottom.equalTo(self.view.snp.bottom).offset(0)
        }
        
        // 那个蓝色圆角的线框
        self.inputContainerView.addSubview(self.inputRoundCornerView)
        self.inputRoundCornerView.snp.makeConstraints { make in
            make.top.equalTo(self.inputContainerView.snp.top).offset(2)
            make.bottom.equalTo(self.inputContainerView.snp.bottom).offset(-64)
            make.left.equalTo(inputViewMargin)
            make.right.equalTo(-inputViewMargin)
        }
        
        // add shadow
        self.inputRoundCornerView.layer.masksToBounds = false
        self.inputRoundCornerView.layer.shadowColor = UIColor.black.withAlphaComponent(0.05).cgColor
        self.inputRoundCornerView.layer.shadowOpacity = 1
        self.inputRoundCornerView.layer.shadowOffset = CGSize(width: 0, height: 4)
        self.inputRoundCornerView.layer.shadowRadius = 4
        let rc = CGRect(x: -2,
                        y: -2,
                        width: self.view.frame.size.width - inputViewMargin*2 + 4,
                        height: 64 + 4)
        self.inputRoundCornerView.layer.shadowPath = UIBezierPath(rect: rc).cgPath

        // textview 输入框
        self.inputRoundCornerView.addSubview(self.textInputView)
        self.textInputView.snp.makeConstraints { make in
            make.left.equalTo(12)
            make.top.equalTo(16)
            make.bottom.equalTo(-14)
            make.right.equalTo(-64)
        }

        // 发送按钮
        self.inputRoundCornerView.addSubview(self.sendButton)
        self.sendButton.snp.makeConstraints { make in
            make.bottom.equalTo(-14)
            make.width.height.equalTo(40)
            make.right.equalTo(-16)
        }

        /// 免责声明
        self.inputContainerView.addSubview(bottomDisclaimerLabel)
        bottomDisclaimerLabel.snp.makeConstraints { make in
            make.centerX.equalTo(self.inputContainerView)
            make.height.equalTo(14)
            make.top.equalTo(self.inputRoundCornerView.snp.bottom).offset(14)
            make.left.right.equalTo(self.inputContainerView)
        }
    }
        
    /// 创建 uitextview 内嵌的文本区 placeholder view
    func setupPlaceholder() {
        // 创建占位符 UILabel
        placeholderLabel.translatesAutoresizingMaskIntoConstraints = false
        placeholderLabel.text = "发消息"
        placeholderLabel.textColor = UIColor.mb_color(with: "#8A8A8E")
        placeholderLabel.font = textInputView.font
        textInputView.addSubview(placeholderLabel)
        placeholderLabel.snp.makeConstraints { make in
            make.left.equalTo(8)
            make.centerY.equalTo(textInputView)
        }
    }
    
    /// 创建输出窗口
    func setupOutputViews() {
        // 输出文本
        self.view.addSubview(self.outputLabel)
        self.outputLabel.snp.makeConstraints { make in
            make.center.equalTo(self.view)
            make.width.height.equalTo(400)
        }
    }
    
    /// 创建暂停、继续悬浮按钮
    func setupFloatingActionView() {
        view.addSubview(floatingActionView)
        floatingActionView.isHidden = true
        floatingActionView.snp.makeConstraints { make in
            make.centerX.equalTo(self.view)
            make.width.equalTo(140)
            make.height.equalTo(44)
            make.bottom.equalTo(self.inputContainerView.snp.top).offset(-10)
        }
        floatingActionView.onTap = { [weak self] value in
            
            // 通知状态机取消本次输出
            self?.llamaState?.cancelCurrentOutput = true
        }
    }
    
    // MARK: - 列表代理及数据源
    
    /// UITableViewDataSource 方法 - 返回 cell 总数
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dataArray.count
    }
    
    /// 生成指定的 cell
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        if indexPath.row >= dataArray.count {
            return UITableViewCell()
        }
    
        let model = dataArray[indexPath.row]
        
        if model.type == "TEXT" {
            
            if let cell = tableView.dequeueReusableCell(withIdentifier: "MBTextTableViewCell", for: indexPath) as? MBTextTableViewCell {
                cell.selectionStyle = .none
                cell.bindTextWith(data: model)
                // cell toolbar 点击事件
                cell.onTap = { [weak self] model, actionName in
                    self?.cellToolbarClickEvent(model, action: actionName)
                }
                return cell
            }
            
            return UITableViewCell()

        }
        
        return UITableViewCell()
    }
    
    /// 返回 cell 高度
    public func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        
        if indexPath.row < dataArray.count {
            let model = dataArray[indexPath.row]
            // 返回 cell 的高度
            return model.cellHeight
        }

        return 0
    }
    
    /// UITableViewDelegate 方法，点击了指定 cell
    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: false)
        self.textInputView.resignFirstResponder()
        if indexPath.row < dataArray.count {
            let model = dataArray[indexPath.row]
            if model.type == "IMAGE" {
                // 图片自己有自己的点击事件
                return
            } else if model.type == "TEXT" {
                if model.role == "llm" {
                    // 注意，只有点击 LLM 输出的 文字 cell，则会显示 popup action button
                    if let curCell = tableView.cellForRow(at: indexPath) as? MBTextTableViewCell {
                        // 显示 popup area
                        curCell.showPopupActionWith(show: !model.hasFloatingActionButton)
                    }
                }
            }
        }
        
    }

    // 返回 section header 高度
    public func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 88
    }
    
    // 配置 section header
    public func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let headerView = tableView.dequeueReusableHeaderFooterView(withIdentifier: "MBHomeTableViewHeaderView") as! MBHomeTableViewHeaderView
        return headerView
    }
    
    // MARK:  - 顶导 点击 事件

    /// delete nav item clicked
    @objc func deleteButtonTapped() {
        
        // 进入全屏状态
        if self.fullscreenEditor {
            return
        }

        if thinking {
            self.showErrorTips("处理中，请稍等")
            return
        }
        
        let alertController = UIAlertController(title: "是否清除对话记录",
                                                message: "清除后对话记录无法恢复，是否确认清除对话记录？",
                                                preferredStyle: .alert)
        
        let okayAction = UIAlertAction(title: "删除",
                                       style: .destructive) { [weak self] (action) in
            self?.dataArray.removeAll()
            self?.tableView.reloadData()
            self?.textInputView.text = ""
            self?.thinking = false
            
            // 重置 llama.cpp 状态
            Task {
                await self?.llamaState?.clear()
                
                // 开场白
                self?.appendPrologue()
            }
        }
        
        let cancelAction = UIAlertAction(title: "取消",
                                         style: .cancel,
                                         handler: nil)
        
        alertController.addAction(okayAction)
        alertController.addAction(cancelAction)
        
        present(alertController, animated: true, completion: nil)
    }

    // MAKR: - TextView 事件
    
    public func textViewDidBeginEditing(_ textView: UITextView) {
        if textView.text == "" {
            placeholderLabel.isHidden = false
            sendButton.isEnabled = false
        } else {
            placeholderLabel.isHidden = true
            sendButton.isEnabled = true
        }
    }
    
    public func textViewDidChange(_ textView: UITextView) {
        if textView.text == "" {
            placeholderLabel.isHidden = false
            sendButton.isEnabled = false
        } else {
            placeholderLabel.isHidden = true
            sendButton.isEnabled = true
        }
    }
    
    public func textViewDidEndEditing(_ textView: UITextView) {
        if textView.text == "" {
            placeholderLabel.isHidden = false
            sendButton.isEnabled = false
        } else {
            placeholderLabel.isHidden = true
            sendButton.isEnabled = true
        }
    }

    // MARK: - 与 llamaState 交互的逻辑
    
    func prepareModel() {
        guard let llamaState = llamaState else {
            return
        }

        // 是否有已经下载好的语言模型
        var hasLanguageModel = false
        
        // 有选中任意模型
        for (_, item) in llamaState.downloadedModels.enumerated() {
            if item.filename == MiniCPMModelConst.paperplaneLanguageModelName ||
                item.filename == MiniCPMModelConst.languageModelFileName {
                // 有语言模型
                hasLanguageModel = true
                break
            }
        }

        if !hasLanguageModel {
            // 没有语言模型
            self.showErrorTips("请先下载模型")
            return
        }

        if hasLanguageModel {
            // 这是语言模型

            // 是否需要重加载模型
            var needReloadModel = false

            // 语言模型本地沙箱里的 file url
            var selectedLanguageModel = MiniCPMModelConst.paperplaneLanguageModelName
            
            let selected = UserDefaults.standard.value(forKey: "current_selected_model") as? String ?? ""
            
            if selected == "LanguageQ4_1" {
                selectedLanguageModel = MiniCPMModelConst.languageModelFileName
                
                if self.currentUsingModelType != .LanguageQ4_1 {
                    // 需要重新加载语言模型
                    needReloadModel = true
                }
                
                self.updateNavTitle()
            }
            
            // 当前使用的模型为语言模型
            if selected == "LanguageQ4_1" {
                self.currentUsingModelType = .LanguageQ4_1
            }
            
            if self.currentUsingModelType == .Unknown {
                self.showErrorTips("请先下载并选中模型")
                return
            }
            
            let languageModelURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent(selectedLanguageModel)

            // 如果当前加载的不是同一个语言模型，则需要加载一次
            if needReloadModel {
                Task {
                    // 重启对话
                    await self.llamaState?.clear()

                    do {
                        
                        if self.currentUsingModelType == .LanguageQ4_1 {

                            if let act_as = self.customParameter?["name"] as? String,
                                !act_as.isEmpty {
                                // 标题显示角色名字
                                self.title = act_as
                            }

                            var systemInfo = ""
                            if let prompt = self.customParameter?["prompt"] as? String {
                                systemInfo = String(format: "<用户>%@", prompt)
                            }

                            try await self.llamaState?.loadModel(modelUrl: languageModelURL,
                                                                 template: "",
                                                                 system_prompt: systemInfo)
                            
                            // 然后立刻把 prologue 说出来
                            appendPrologue()
                        }

                    } catch {
                        self.thinking = false
                        self.showErrorTips("初始化模型失败，请重试。")
                    }
                    
                    // 初始化后要 reset 性能日志，为了输出 heat log 用
                    self.llamaState?.performanceLog = ""
                }
            }
        }
        
    }
    
    func appendPrologue() {
        var prologue = ""
        if let prol = self.customParameter?["prologue"] as? String,
            !prol.isEmpty {
            prologue = prol
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                self.appendTextDataToCellWith(text: prologue, role: "llm")
                self.tableViewScrollToBottom()
            }
        }
    }
    
    /// 发送文本
    @objc public func handleSendText(_ sender: UIButton) {

        guard let llamaState = llamaState else {
            return
        }

        textInputView.resignFirstResponder()

        if thinking {
            // 禁止重复点击
            self.showErrorTips("请稍等")
            return
        }
        
        if self.currentUsingModelType == .Unknown {
            self.showErrorTips("请先下载模型")
            return
        }
        
        // 是否有已经下载好的语言模型
        var hasLanguageModel = false
        
        for (_, item) in llamaState.downloadedModels.enumerated() {
            if item.filename == MiniCPMModelConst.languageModelFileName {
                // 有语言模型
                hasLanguageModel = true
                break
            }
        }

        if !hasLanguageModel {
            // 没有语言模型
            self.showErrorTips("请先下载模型")
            return
        }

        // 输入框上的文字
        let inputText = textInputView.text.trimmingCharacters(in: .whitespacesAndNewlines)

        if inputText.isEmpty {
            self.showErrorTips("请输入内容")
            return
        }
        
        textInputView.text = ""
        sendButton.isEnabled = false
        placeholderLabel.isHidden = false

        // 把文字也放上去
        appendTextDataToCellWith(text: inputText, role: "user")

        // 把之前显示在 llm cell 上的 toolbar 及 popup 都隐藏掉，注意，不能把下边即将要输出显示的 llm cell 隐藏了。
        hideAllCellToolbarAndPopup()

        // append robte output text cell, prepare llm output
        appendTextDataToCellWith(text: "", role: "llm")

        // 滚动到底部
        tableViewScrollToBottom()

        // 清空输出
        llamaState.messageLog = ""
        llamaState.performanceLog = ""

        // 记录用户输入
        latestUserInputText = inputText

        // 显示暂停和继续的悬浮的按钮
        showFloatingActionViewWith(show: true)
        
        // 记录日志，用户输入文字
        MBLLMDB.sharedInstance().saveModel(["role": "user", "content": inputText])

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            
            Task {
                self.thinking = true
                
                if hasLanguageModel {
                    // 语言推理
                    await self.llamaState?.minicpmv_complete(text: inputText, model: self.currentUsingModelType)
                }
            }
        }

    }

    // MARK: - 更新 cell
    
    /// 添加一个 文本 cell 到 tableview 里
    func appendTextDataToCellWith(text: String?, role: String?) {
        let textModel = MBChatModel()
        textModel.type = "TEXT"
        textModel.contentText = text
        textModel.role = role
        textModel.cellHeight = MBTextTableViewCell.calcCellHeight(data: textModel, viewWidth: self.view.frame.width)

        /*
        if role == "llm" {
            // 如果是输出的内容的话，第 1 次显示时，要显示底部的 toolbar 区域
            textModel.hasBottomToolbar = true
        }*/
        
        dataArray.append(textModel)
    }
    
    /// 每次输入完，要把列表滚动到归底部
    func tableViewScrollToBottom() {
        // scroll to bottom
        if dataArray.count > 0 {
            tableView.reloadData()
            tableView.scrollToRow(at: IndexPath(row: dataArray.count - 1, section: 0), at: .bottom, animated: true)
        }
    }
}

extension MBChatViewController {
    
    /// 显示错误提示
    func showErrorTips(_ str: String?, delay: TimeInterval = 2) {
        DispatchQueue.main.async {
            let hud = MBProgressHUD.showAdded(to: self.view, animated: true)
            hud.mode = .text
            hud.label.text = str
            hud.hide(animated: true, afterDelay: delay)
        }
    }
}

extension MBChatViewController {

    /// 把之前已经显示的 cell 上的所有 toolbar 和 popup 都隐藏掉
    func hideAllCellToolbarAndPopup() {
        for item in dataArray {
            if item.role == "llm" {
                item.hasBottomToolbar = false
                item.hasFloatingActionButton = false
                // 重新计算 cell 的高度（因为要隐藏 toolbar）
                item.cellHeight = MBTextTableViewCell.calcCellHeight(data: item, viewWidth: self.view.frame.width)
            }
        }

        self.tableView.reloadData()
    }
    
}

extension MBChatViewController {
    
    @objc public func handleLeftNavIcon() {
        self.navigationController?.popViewController(animated: true)
    }
}
