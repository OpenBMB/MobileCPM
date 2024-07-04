<div align="center">
<h1 align="center">MobileCPM</h1>
<p align="center">一键集成端侧大模型到APP</p>
</div>
<div align="center">

[![License: Apache 2.0](https://img.shields.io/badge/License-Apache_2.0-green.svg)](https://opensource.org/license/apache-2-0/) ![Welcome](https://img.shields.io/badge/contributions-welcome-brightgreen.svg?style=flat)

</div>
<h4 align="center">
    <p>
        <b>中文</b> | <a href="https://github.com/OpenBMB/MobileCPM/blob/main/README-en.md">English</a>
    <p>
</h4>

<div align="center">
  TestFlight:https://testflight.apple.com/join/dJt5vfOZ
</div>


## 什么是MobileCPM?

MobileCPM 是首个开源的端侧大模型工具套件，帮助个人或企业开发者一键集成端侧大模型到 APP 产品中。在下图演示 APP 中，MiniCPM 提供端侧模型能力，并内置翻译家、诗人、故事写手、励志教练等多个示例智能体，满足多种使用场景。不仅如此，端侧模型和智能体种类，可以灵活扩展。开发者通过增加，修改prompt、更换端侧模型的方式，即可定制智能体，满足业务需求和场景。下图演示了内置“励志教练”智能体的对话效果。**请注意**，在该例子中，已经断开网络连接，直接使用端侧模型。

| ![Image 1](https://github.com/OpenBMB/MobileCPM/blob/main/assets/pics/modelselect.jpeg) | ![Image 2](https://github.com/OpenBMB/MobileCPM/blob/main/assets/pics/homepage.jpeg) | ![Image 3](https://github.com/OpenBMB/MobileCPM/blob/main/assets/pics/chatpage.jpeg) |
|:----------------------:|:----------------------:|:----------------------:|
| 第一步：下载并加载模型          | 第二步：选择智能体          | 第三步：与端侧模型对话          |

当前，MobileCPM 已经全面支持iOS系统，testflight外部测试链接为：https://testflight.apple.com/join/dJt5vfOZ
Android版本也即将上线，敬请期待。


## MobileCPM 能做什么？

大模型小型化是科技趋势，一些端侧模型已经在非GPU环境运行，比如面壁智能公司开源的miniCPM。如何快捷集成端侧大模型能力到APP，是MobileCPM要解决的难题。具体来说，MobileCPM主要包含如下特色: 
+ 简单易用: 下载MobileCPM源码，一键即可编译出APP。并且，官方配备保姆式教程，容易上手；
+ 深度集成: 从大模型文件到最后输出智能之间的模块和链路，已被MobileCPM高度抽象，无需关心中间繁杂实现，按照官方配备的多种Agent调用示例，即可完成定制需求；
+ 零成本推理: 大模型运行在本地移动设备，不依赖云端GPU，无需开发方支付任何推理费用；
+ 毫秒急速响应: 市面主流手机皆可流程运行，比如iPhone 11，推理速度超过 20 token/s；



## 快速开始

MobileCPM是完整的iOS移动端APP项目，提供了项目全部Xcode工程代码，开发者可以直接下载工程编译、修改、运行。本开源APP的testflight测试链接为: https://testflight.apple.com/join/dJt5vfOZ

### 如何下载并加载模型
在对话开始前，需要先进行模型的下载和加载，示例如下：
```python
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
```

### 如何更换端侧模型
示例提供了MiniCPM端侧模型，开发者可更换其他模型。
```python
/// 定义 MiniCPM 模型常量
struct MiniCPMModelConst {

    /// paperplane-iOS 专用语言模型 文件名
    static let paperplaneLanguageModelName = "placeholder"
    
    /// paperplane-iOS 专用语言模型 下载地址
    static let paperplaneLanguageModelURLString = "placeholder"

    /// 1.2B 语言模型 文件名
    static let languageModelFileName = "ggml-model-Q4_1.gguf"

    /// 1.2B 语言模型 oss 下载地址
    static let languageModelURLString = "https://minicpm.modelbest.cn/ggml-model-Q4_1.gguf"
    
    /// 显示在 UI 上名字-paperplane
    static let paperplaneModelDisplayedName = "placeholder"
    
    /// 显示在 UI 上名字-Q4_1
    static let languageModelQ4_1DisplayedName = "MiniCPM 1.2B"
}

```

### 如何自定义智能体
示例预置了十几种智能体，每个智能体有name,avatar,prompt,prologue,model_name_or_path等属性，开发者可修改属性，可增加新的智能体。
```python
"0": {
        "name": "英文翻译",
        "avatar": "英文翻译.jpg",
        "prompt": "我希望你充当英语翻译、拼写校正和改进者。我会用任何语言与你交谈，你会检测语言，翻译它，并用我的文本的更正和改进版本，用英语回答。我希望你把我简化的A0级单词和句子换成更漂亮、更优雅的高级英语单词和句子。保持含义不变，但使它们更具文学性。我希望你只回复更正，改进，没有别的，不要写解释。",
        "prologue": "我的第一句话是“istanbulu cok seviyom burada olmak cok guzel”",
        "model_name_or_path": "minicpm"
    },
    "1": {
        "name": "广告文案",
        "avatar": "广告文案.png",
        "prompt": "我希望你充当广告商。您将创建一个广告系列来推广您选择的产品或服务。您将选择目标受众，制定关键信息和口号，选择媒体渠道进行推广，并决定实现目标所需的任何其他活动。",
        "prologue": "我的第一个建议请求是“我需要帮助为一种针对 18-30 岁年轻人的新型能量饮料创建广告活动。",
        "model_name_or_path": "minicpm"
    },
```

### 如何实现流式对话功能
如示例中，订阅大模型的输出，更新页面输出可实现流式输出效果：
```python
/// 订阅大模型的输出
    public func subscriberLlamaMessageLog() {
        
        // 订阅 @Published 属性的变化
        dataSubscriber = llamaState?.$messageLog
            .receive(on: DispatchQueue.main)   // 更新 UI 的相关操作切换到主线程
            .sink { [weak self] receivedData in
                
                // find last text cell and append text
                if let c = self?.dataArray.count, c > 0 {
                    if let latestCell = self?.tableView.cellForRow(at: IndexPath(row: (self?.dataArray.count ?? 0) - 1, section: 0)) as? MBTextTableViewCell {
                        
                        if latestCell.model?.role == "llm" {
                            
                            var formatedStr = receivedData
                            
                            if formatedStr.hasPrefix(" ") {
                                formatedStr = String(formatedStr.dropFirst())
                            }
                            
                            // 更新输出的文本内容
                            latestCell.model?.contentText = formatedStr
                            
                            // 重新计算 cell 高度
                            let cellHeight = MBTextTableViewCell.calcCellHeight(data: latestCell.model, viewWidth: self?.view.frame.width ?? 0)
                            latestCell.model?.cellHeight = cellHeight
                            
                            self?.tableViewScrollToBottom()
                        }
                    }
                }
            }
        
        // 订阅 performanceLog @Published 属性的变化
        perfLogSubscriber = llamaState?.$performanceLog
            .receive(on: DispatchQueue.main)   // 更新 UI 的相关操作切换到主线程
            .sink { [weak self] log in
                
                // 输出完成
                if !log.isEmpty {
                    self?.thinking = false
                }
                
                if let c = self?.dataArray.count, c > 0 {
                    if let latestCell = self?.tableView.cellForRow(at: IndexPath(row: (self?.dataArray.count ?? 0) - 1, section: 0)) as? MBTextTableViewCell {
                        if latestCell.model?.role == "llm" {
                            if !log.hasPrefix("Loaded model") {
                                latestCell.model?.performLog = log
                                
                                self?.tableViewScrollToBottom()
                                
                                // 显示暂停和继续的悬浮的按钮
                                if !log.isEmpty {
                                    
                                    // 输出完才显示 toolbar
                                    latestCell.model?.hasBottomToolbar = true
                                    latestCell.model?.cellHeight = MBTextTableViewCell.calcCellHeight(data: latestCell.model, viewWidth: self?.view.frame.width ?? 0)
                                    latestCell.bindTextWith(data: latestCell.model)
                                    
                                    self?.showFloatingActionViewWith(show: false)
                                    
                                    // 记录日志，用户输入文字
                                    if let content = latestCell.model?.contentText, !content.isEmpty {
                                        MBLLMDB.sharedInstance().saveModel(["role": "assistant", "content": content])
                                    }
                                    
                                }
                                
                            }
                            
                        }
                    }
                }
            }
    }
```
## 开源协议

本仓库中代码依照Apache-2.0协议开源

## 声明
+ MobileCPM内置的MiniCPM通过学习大量的文本来生成内容，但它无法理解、表达个人观点或价值判断，它所输出的任何内容都不代表模型开发者的观点和立场。因此用户在使用MobileCPM内置的MiniCPM生成的内容时，应自行负责对其进行评估和验证。
+ 如果由于使用MobileCPM内置的MiniCPM开源模型而导致的任何问题，包括但不限于数据安全问题、公共舆论风险，或模型被误导、滥用、传播或不当利用所带来的任何风险和问题，我们将不承担任何责任。



