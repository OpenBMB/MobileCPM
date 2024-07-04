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
