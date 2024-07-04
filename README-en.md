<div align="center">
<h1 align="center">MobileCPM</h1>
<p align="center">A Toolkit for Running On-device Large Language Models (LLMs) in APP</p>
</div>
<div align="center">

[![License: Apache 2.0](https://img.shields.io/badge/License-Apache_2.0-green.svg)](https://opensource.org/license/apache-2-0/) ![Welcome](https://img.shields.io/badge/contributions-welcome-brightgreen.svg?style=flat)

</div>
<h4 align="center">
    <p>
        <a href="https://github.com/OpenBMB/MobileCPM/blob/main/README.md">中文</a> | <b>English</b>
    <p>
</h4>

## What is MobileCPM?

MobileCPM is the first open-source toolset for on-device large models, designed to help individual or enterprise developers seamlessly integrate on-device large models into their APP products. In the demo APP shown below, MiniCPM provides on-device model capabilities and comes with several example agents such as a translator, poet, storyteller, and motivational coach to cater to various use cases. Moreover, the types of on-device models and agents can be flexibly expanded. Developers can customize agents to meet business needs and scenarios by adding or modifying prompts and replacing on-device models. The image below demonstrates the conversation effect of the built-in "motivational coach" agent. **Please note** that in this example, the network connection has been disconnected, and the on-device model is used directly.

| ![Image 1](https://github.com/OpenBMB/MobileCPM/blob/main/assets/pics/modelselect.jpeg) | ![Image 2](https://github.com/OpenBMB/MobileCPM/blob/main/assets/pics/homepage.jpeg) | ![Image 3](https://github.com/OpenBMB/MobileCPM/blob/main/assets/pics/chatpage.jpeg) |
|:----------------------:|:----------------------:|:----------------------:|
| Step 1: Download and Load the Model          | Step 2: Select an Agent          | Step 3: Interact with the On-Device Model          |


Currently, MobileCPM fully supports the iOS system. You can access the TestFlight external testing link here: https://testflight.apple.com/join/dJt5vfOZ. The Android version is also coming soon, so stay tuned.

## What MobileCPM can do?

On-device LLMs are a significant technological trend, with some on-device LLMs already running in non-GPU environments, such as the open-source miniCPM from ModelBest. How to quickly integrate on-device LLMs into apps is the challenge that MobileCPM aims to solve. Specifically, MobileCPM features the following highlights:

+ Simple and easy to use: Download the MobileCPM source code and compile the app with one click. Additionally, the official tutorial is highly detailed, making it easy to get started;
+ Deep integration: The inference modules have been highly abstracted by MobileCPM. Without worrying about the complex intermediate implementations, you can meet custom needs by following the various examples;
+ Zero-cost inference: The LLM runs on local mobile devices without relying on cloud GPUs, eliminating any inference costs for developers;
+ Lightning-Fast Response: Mainstream mobile phones on the market can run smoothly, such as the iPhone 11, with an inference speed exceeding 20 tokens per second.


## Quickstart

MobileCPM is a complete iOS mobile app project, providing all Xcode project code. Developers can directly download the project to compile, modify, and run it. The TestFlight testing link for this open-source app is: https://testflight.apple.com/join/dJt5vfOZ

### How to Download and Load the Model
Before starting a conversation, you need to download and load the model. Here is an example:
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
### How to Replace the On-Device Model
The example provides the MiniCPM on-device model, and developers can replace it with other models.
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

### How to Customize Agents
The example comes with a dozen preset agents, each with attributes such as name, avatar, prompt, prologue, and model_name_or_path. Developers can modify these attributes or add new agents.
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

### How to Implement Streaming Conversation
As shown in the example, you can achieve a streaming output effect by subscribing to the output of the large model and updating the page output accordingly:
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

## Open-Source License

The code in this repository is open-sourced under the Apache-2.0 license.

## Disclaimer

+ The built-in MiniCPM of MobileCPM generates content by learning from a large amount of text. However, it cannot understand, express personal opinions, or value judgments, and any output content does not represent the views and positions of the model developers. Therefore, users are responsible for evaluating and verifying the content generated by MiniCPM built into MobileCPM.
+ We will not be responsible for any issues arising from the use of the open-source MiniCPM model in MobileCPM, including but not limited to data security issues, public opinion risks, or any risks and issues caused by the model being misled, misused, disseminated, or improperly utilized.
