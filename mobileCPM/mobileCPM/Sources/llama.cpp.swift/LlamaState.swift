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

struct Model: Identifiable {
    var id = UUID()
    var name: String
    var url: String
    var filename: String
    var status: String?
}

/// 当前使用的模型
enum CurrentUsingModelType {
    /// 未知
    case Unknown
    /// paperplane 专用模型
    case paperPlane
    /// 纯语言模型 1.2B language-model
    case LanguageQ4_1
}

@MainActor
class LlamaState: ObservableObject {
    /// 大模型流式输出
    @Published var messageLog = ""
    /// 性能日志的输出
    @Published var performanceLog = ""
    /// 保存着所有已经下载（生效）的模型
    @Published var downloadedModels: [Model] = []
    /// 未下载的模型
    @Published var undownloadedModels: [Model] = []
    /// 纳秒常量
    let NS_PER_S = 1_000_000_000.0
    
    /// 取消本次输出
    public var cancelCurrentOutput = false
    
    /// 当前生效的模型
    var currentUsingModelType: CurrentUsingModelType = .Unknown
    
    /// context 就是与 llama.cpp 底层 c++ 逻辑通讯的封装
    public var llamaContext: LlamaContext?
    
    /// 【可选】内置至 app.bundle 中的模型
    private var defaultModelUrl: URL? {
        Bundle.main.url(forResource: "ggml-model", withExtension: "gguf", subdirectory: "models")
    }
    
    // MARK: - 初始化方法
    
    init() async {
        // 加载已经下载好的模型到状态机列表中
        loadModelsFromDisk()
        // 下载 app 内置的模型（可选）
        await loadDefaultModels()
    }
    
    /// 便捷方法，获取沙箱相对地址
    func getDocumentsDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0]
    }
    
    /// 内部方法：更新模型状态
    private func updateDownloadedModels(modelName: String, status: String) {
        undownloadedModels.removeAll { $0.name == modelName }
    }
    
    /// 原始 llama.cpp 方法，缺省模型列表
    private let defaultModels: [Model] = [
        
        // 1.2B 模型
        Model(name: MiniCPMModelConst.languageModelFileName,
              url: MiniCPMModelConst.languageModelURLString,
              filename: MiniCPMModelConst.languageModelFileName,
              status: "download"),

        // 纸飞机专用模型
        Model(name: MiniCPMModelConst.paperplaneLanguageModelName,
              url: MiniCPMModelConst.paperplaneLanguageModelURLString,
              filename: MiniCPMModelConst.paperplaneLanguageModelName,
              status: "download")
    ]
    
    /// MiniCPM-V 加载纯语言模型
    /// - Parameters:
    ///   - modelUrl: 语言模型的本地 url
    ///   - template: 对于纸飞机 App 来说是："<s>user\n{{prompt}}</s><s>assistant\n"
    ///   - system_prompt: System prompt string
    ///   - history: 上次的聊天记录
    ///   - nCtx: 上下文的大小（和模型有关，默认 4096）
    func loadModel(modelUrl: URL?, 
                   template: String = "",
                   system_prompt: String = "",
                   history: String = "",
                   nCtx: Int32 = 4096) async throws {
        if let modelUrl {
            
            // 日志，开始时间，记录文本模型 create_context 的g begin
            let t_start = DispatchTime.now().uptimeNanoseconds
            
            // 生成 llama.cpp 内部实现的上下文对象
            llamaContext = try await LlamaContext.create_context(path: modelUrl.path(),
                                                                 template: template,
                                                                 system_prompt: system_prompt,
                                                                 history: history,
                                                                 nCtx: nCtx)
            
            // 日志：load model + 图片处理的时间 end
            let t_heat_end = DispatchTime.now().uptimeNanoseconds
            let t_heat = Double(t_heat_end - t_start) / NS_PER_S
            
            // 日志：@salex 输出到 performanceLog
            performanceLog += "Loaded model \(String(format: "%.1f", t_heat))s"
            
            if modelUrl.absoluteString.contains("placeholder") {
                currentUsingModelType = .paperPlane
            } else if modelUrl.absoluteString.contains("Q4_1") {
                currentUsingModelType = .LanguageQ4_1
            }
            
            // Assuming that the model is successfully loaded, update the downloaded models
            updateDownloadedModels(modelName: modelUrl.lastPathComponent, status: "downloaded")
        } else {
            // 模型 url 为空，@salex 输出到 performanceLog
            // performanceLog += "Load a model from the list below\n"
        }
    }

    // MARK: - MiniCPM 专用 开始输入文字，耗时函数，需要定义为 async
    
    /// MiniCPM 专用 开始输入文字
    /// - Parameter text: 用户自己的输入文字
    /// - Parameter model: 当前是 语言模型 还是 多模态模型
    func minicpmv_complete(text: String, model: CurrentUsingModelType) async {
        
        guard let llamaContext else {
            // 没有 llama.cpp context，直接返回
            return
        }
        
        // 日志：记录开始时间
        let t_start = DispatchTime.now().uptimeNanoseconds
        
        if model == .paperPlane || model == .LanguageQ4_1 {
            // @salex 调用 minicpm-v 的方法: 纯语言用 chat_init_minicpm 初始化
            await llamaContext.chat_init_minicpm(text: text)
        } else {
            return
        }
        
        // 日志：记录结束时间
        let t_heat_end = DispatchTime.now().uptimeNanoseconds
        let t_heat = Double(t_heat_end - t_start) / NS_PER_S

        // @salex 要记录 result 循环了几次: result_count
        var t_result_count = 0
        
        // 每次不超过 n_cur + n_len 的内容
        let nRemain = await llamaContext.n_cur + llamaContext.n_len
        
        while await llamaContext.n_cur < nRemain {
            // 大模型的输出是由 context.chat_loop() 返回的
            let result = await llamaContext.chat_loop()
            
            // </s> 这是本轮对话结束的标记
            if result == "</s>" {
                break
            }
            
            // 外部传入的标记，取消本次输出
            if cancelCurrentOutput {
                cancelCurrentOutput = false
                let halted = "\n（用户终止）"
                messageLog += halted
                break
            }
            
            // 统计一次生成了多少 tokens
            t_result_count += 1
            
            // 把大模型的输出拼接上，业务层流式显示 messageLog 即可
            messageLog += "\(result)"
        }

        if t_result_count == 0 {
            // 防止 crash
            t_result_count = 1
        }
        
        // 日志：一次输出用时
        let t_end = DispatchTime.now().uptimeNanoseconds
        let t_generation = Double(t_end - t_heat_end) / NS_PER_S
        
        let tokens_per_second = Double(t_result_count) / t_generation
        
        // 日志：记入 log，业务侧观察 performanceLog 即可显示性能日志
        performanceLog += "响应时间： \(String(format: "%.1f", t_heat))s \t 生成速度: \(String(format: "%.1f", tokens_per_second))token/s \t 总耗时：\(String(format: "%.1f", t_generation))s"
    }

    /// 设置超采样参数
    /// - Parameters:
    ///   - temp: temp value
    ///   - penalty_repeat: penalty_repeat
    ///   - seed: seed
    ///   - top_p: top_p
    ///   - top_k: top_k
    public func set_sampling_params(temp: Float32,
                                    penalty_repeat: Float32,
                                    seed: UInt32,
                                    top_p: Float32,
                                    top_k: Int32) async {
        await self.llamaContext?.set_sampling_params(temp: temp,
                                                     penalty_repeat: penalty_repeat,
                                                     seed: seed,
                                                     top_p: top_p,
                                                     top_k: top_k)
    }

    /// 有用的：清空 llamaContext
    public func clear() async {
        guard let llamaContext else {
            return
        }
        
        // reset modeltype 为 未知
        currentUsingModelType = .Unknown
        messageLog = ""
        performanceLog = ""

        // 调用 context clear() 方法
        await llamaContext.clear()
    }

    /// 原始 llama.cpp 中的方法，从磁盘加载模型
    private func loadModelsFromDisk() {
        do {
            let documentsURL = getDocumentsDirectory()
            let modelURLs = try FileManager.default.contentsOfDirectory(at: documentsURL, includingPropertiesForKeys: nil, options: [.skipsHiddenFiles, .skipsSubdirectoryDescendants])
            for modelURL in modelURLs {
                let modelName = modelURL.deletingPathExtension().lastPathComponent
                downloadedModels.append(Model(name: modelName, url: "", filename: modelURL.lastPathComponent, status: "downloaded"))
            }
        } catch {
            print("Error loading models from disk: \(error)")
        }
    }
    
    /// 原始 llama.cpp 中的方法，加载默认模型，有用，不要动这个函数
    private func loadDefaultModels() async {
        do {
            try await loadModel(modelUrl: defaultModelUrl)
        } catch {
            // @salex 替换为输出到 performanceLog
            performanceLog += "Error!\n"
        }
        
        for model in defaultModels {
            let fileURL = getDocumentsDirectory().appendingPathComponent(model.filename)
            if FileManager.default.fileExists(atPath: fileURL.path) {
                
            } else {
                var undownloadedModel = model
                undownloadedModel.status = "download"
                undownloadedModels.append(undownloadedModel)
            }
        }
    }
    
    /// 旧的 llama.cpp 提供的纯文本聊天函数
    private func complete(text: String) async {
        guard let llamaContext else {
            return
        }
        
        let t_start = DispatchTime.now().uptimeNanoseconds
        await llamaContext.completion_init(text: text)
        let t_heat_end = DispatchTime.now().uptimeNanoseconds
        let t_heat = Double(t_heat_end - t_start) / NS_PER_S
        
        messageLog += "\(text)"
        
        while await llamaContext.n_cur < llamaContext.n_len {
            let result = await llamaContext.completion_loop()
            messageLog += "\(result)"
        }
        
        let t_end = DispatchTime.now().uptimeNanoseconds
        let t_generation = Double(t_end - t_heat_end) / NS_PER_S
        let tokens_per_second = Double(await llamaContext.n_len) / t_generation
        
        await llamaContext.clear()
        
        performanceLog += """
            \n
            Done
            Heat up took \(t_heat)s
            Generated \(tokens_per_second) t/s\n
            """
    }
    
    /// 旧的 llama.cpp 提供的评测的函数
    private func bench() async {
        guard let llamaContext else {
            return
        }
        
        messageLog += "\n"
        messageLog += "Running benchmark...\n"
        messageLog += "Model info: "
        messageLog += await llamaContext.model_info() + "\n"
        
        let t_start = DispatchTime.now().uptimeNanoseconds
        let _ = await llamaContext.bench(pp: 8, tg: 4, pl: 1) // heat up
        let t_end = DispatchTime.now().uptimeNanoseconds
        
        let t_heat = Double(t_end - t_start) / NS_PER_S
        messageLog += "Heat up time: \(t_heat) seconds, please wait...\n"
        
        // if more than 5 seconds, then we're probably running on a slow device
        if t_heat > 5.0 {
            messageLog += "Heat up time is too long, aborting benchmark\n"
            return
        }
        
        let result = await llamaContext.bench(pp: 512, tg: 128, pl: 1, nr: 3)
        
        messageLog += "\(result)"
        messageLog += "\n"
    }
}
