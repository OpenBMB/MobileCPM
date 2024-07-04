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

/// 大模型下载管理器，可以同时下载 主模型 和 图像识别模型
class MBModelDownloadHelper: NSObject {
    
    /// 外部（调用方）传入的引用
    private var llamaState: LlamaState
    
    /// 模型文件名
    private var modelName: String
    
    /// 模型对应服务器下载地址
    public var modelUrl: String
    
    /// 文件名（有扩展名）
    private var filename: String
    
    /// 当前模型的下载状态【没有下载前需要下载】
    public var status: String
    
    private var downloadTask: URLSessionDownloadTask?
    
    /// 下载进度
    private var progress = 0.0
    
    public var observation: NSKeyValueObservation?
    
    // 定义一个闭包类型的属性
    public var completionHandler: ((CGFloat) -> Void)?
    
    /// 当前选中的模型
    private var loadedStatus: Bool
    
    /// 获取模型对应的本地路径
    private static func getFileURL(filename: String) -> URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent(filename)
    }
    
    /// 模型下载管理器初始化方法
    /// - Parameters:
    ///   - llamaState: 外部传入的 llamaState 结构体的引用
    ///   - modelName: 模型名字
    ///   - modelUrl: 模型下载 url 地址
    ///   - filename: 本地文件名
    init(llamaState: LlamaState, modelName: String, modelUrl: String, filename: String) {
        self.llamaState = llamaState
        self.modelName = modelName
        self.modelUrl = modelUrl
        self.filename = filename
        
        // 获取模型本地 url
        let fileURL = MBModelDownloadHelper.getFileURL(filename: filename)
        
        // 模型是否存在
        status = FileManager.default.fileExists(atPath: fileURL.path) ? "downloaded" : "download"
        
        // 模型选中的模型
        loadedStatus = false
    }
}

extension MBModelDownloadHelper {
    
    /// 断点续传下载器
    public func downloadV2(completionBlock: @escaping (String, CGFloat) -> Void) {
        
        if status == "downloaded" {
            return
        }
        
        FDownLoaderManager.shareInstance().downLoader(URL(string: modelUrl)) { totalSize in
            
#if DEBUG
            debugPrint("-->> totalsize = \(totalSize)")
#endif
            
        } progress: { [weak self] progress in
            
#if DEBUG
            debugPrint("-->> progress = \(String(format: "%.2f", progress * 100))")
#endif
            
            self?.progress = Double(progress)
            
            completionBlock(self?.status ?? "", CGFloat(progress))
            
        } success: { [weak self] cachePath in
            
            guard let cachePath = cachePath else {
                return
            }
            
#if DEBUG
            debugPrint("-->> cachePath = \(cachePath)")
#endif
            
            do {
                
                // 生成正式的文件地址（下载完成后，需要从 cache folder copy 到 documents folder 中）
                let fileURL = MBModelDownloadHelper.getFileURL(filename: self?.filename ?? "")
                
                let temporaryURLString = String(format: "file://%@", cachePath)
                
                if let cacheURL = URL(string: temporaryURLString) {
                    
                    try FileManager.default.moveItem(at: cacheURL, to: fileURL)
                    
#if DEBUG
                    print("Writing to \(self?.filename ?? "") completed")
#endif
                    
                    DispatchQueue.main.async {
                        
                        let model = Model(name: self?.modelName ?? "", url: self?.modelUrl ?? "", filename: self?.filename ?? "", status: "downloaded")
                        
                        self?.llamaState.downloadedModels.append(model)
                        
                        self?.status = "downloaded"
                        
                        // 更新进度
                        if let s = self?.status {
                            completionBlock(s, 1.0)
                        }
                    }
                    
                }
                
            } catch let err {

#if DEBUG
                print("Error: \(err.localizedDescription)")
#endif

            }
            
        } failed: {

#if DEBUG
            debugPrint("-->> 下载失败.")
#endif

        }
    }
}
