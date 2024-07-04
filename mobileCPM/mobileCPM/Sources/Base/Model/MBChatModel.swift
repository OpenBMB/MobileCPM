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

enum MBChatVoteStatusCode {
    case neutral
    case voteup
    case votedown
}

/// chat model
public class MBChatModel: NSObject {
    
    /// 类型：支持 TEXT 和 IMAGE
    var type: String?
    
    /// 角色：人 or 大模型, user or llm
    var role: String?
    
    /// 文字内容
    var contentText: String?
    
    /// 性能日志
    var performLog: String?
    
    /// 多模态加载图片、clip 的总进度【0 - 1】
    var processProgress: CGFloat = 0.0
    
    /// 图片内容
    var contentImage: UIImage?
    
    /// cell 的高度
    var cellHeight: CGFloat = 0.0
    
    /// 是否在每一条内容输出的底部显示调试信息
    var enableDebugLog: Bool = true
    
    /// 最后一条 LLM 输出的内容会有 toolbar【复制、重新生成、👍、🦶】，非最后一条不显示 toolbar
    var hasBottomToolbar: Bool = false
    
    /// 非最后一条 LLM 输出的内容，点击后会有悬浮的 action button【复制、👍、🦶】，滚动时消失
    var hasFloatingActionButton: Bool = false
    
    /// 赞同状态
    var voteStatus: MBChatVoteStatusCode = .neutral
    
    /// 本次输出是否被强制终止了？
    var isForceHalted = false
}
