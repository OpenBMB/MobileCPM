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

extension MBChatViewController {
    
    /// cell 上 toolbar & floating bar 点击事件
    public func cellToolbarClickEvent(_ model: MBChatModel?, action: String?) {
        
        if thinking {
            // 输出时不允许按钮事件
            return
        }
        
        if action == "copy" {
            if let text = model?.contentText {
                UIPasteboard.general.string = text
                self.showErrorTips("已复制", delay: 1)
            }
        } else if action == "regenerate" {
            // 重新生成
            // 建议不要删除用户的输入和之前的输出，这样可以看到对比的效果；
            self.regenerateLastOutput()
        } else if action == "voteup" {
            if model?.voteStatus == .voteup {
                self.showErrorTips("已取消", delay: 1)
            } else {
                self.showErrorTips("已赞同", delay: 1)
            }
        } else if action == "votedown" {
            if model?.voteStatus == .votedown {
                self.showErrorTips("已取消", delay: 1)
            } else {
                self.showErrorTips("已反对", delay: 1)
            }
        }
    }
 
    /// 显示输出中 底部飘出来的 赞停、继续 按钮
    public func showFloatingActionViewWith(show: Bool) {
        floatingActionView.isHidden = !show
    }
    
    // MARK: - 重新生成最后的一次输出内容
    func regenerateLastOutput() {
        textInputView.text = latestUserInputText
        
        Task {
            await self.llamaState?.set_sampling_params(temp: 0.3,
                                                       penalty_repeat: 1.05,
                                                       seed: UInt32(NSDate().timeIntervalSince1970),
                                                       top_p: 0.2,
                                                       top_k: 100)
            
            handleSendText(sendButton)
        }
        
    }
}
