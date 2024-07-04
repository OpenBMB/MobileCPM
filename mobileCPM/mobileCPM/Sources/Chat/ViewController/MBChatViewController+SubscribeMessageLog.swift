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
                            // 多模态模型 更新性能日志
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
    
}
