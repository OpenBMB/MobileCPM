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
    
    /// 键盘弹出
    @objc func keyboardWillShow(notification: NSNotification) {
        if let keyboardSize = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue {
            
            self.view.layoutIfNeeded()
            UIView.animate(withDuration: 0.3) {
                self.inputContainerView.snp.updateConstraints { make in
                    make.bottom.equalTo(self.view.snp.bottom).offset(-keyboardSize.height + 58)
                }
                
                self.inputRoundCornerView.layer.borderWidth = 1.0 / UIScreen.main.scale
                self.inputRoundCornerView.layer.borderColor = UIColor.mb_color(with: "#108DED").cgColor
                
                // 输入时，背景色为白色
                self.inputContainerView.backgroundColor = UIColor.white.withAlphaComponent(0.02)
                
                self.view.layoutIfNeeded()
            }
            
        }
    }
    
    /// 键盘收起
    @objc func keyboardWillHide(notification: NSNotification) {
        
        self.view.layoutIfNeeded()
        
        UIView.animate(withDuration: 0.3) {
            self.inputContainerView.snp.updateConstraints { make in
                make.bottom.equalTo(self.view.snp.bottom).offset(0)
            }
            
            self.inputRoundCornerView.layer.borderWidth = 1.0 / UIScreen.main.scale
            self.inputRoundCornerView.layer.borderColor = UIColor.clear.cgColor
            
            // 收起后，背景色为白色 20% 透明
            self.inputContainerView.backgroundColor = UIColor.white.withAlphaComponent(0)
            
            self.view.layoutIfNeeded()
        }
        
    }
    
    /// 当用户按下 return 键时，取消文本框的焦点以隐藏键盘
    public func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        // 检查换行符（回车键）
        if self.fullscreenEditor == false,
           text == "\n" {
            // 在此处执行发送功能
            textView.resignFirstResponder()
            handleSendText(sendButton)
            // 取消换行
            return false
        }
        
        // 允许其他文本更改
        return true
    }
    
    /// 用户点击空白处
    @objc public func handleResignKeyboard(_ tap: UITapGestureRecognizer?) {
        if textInputView.text.isEmpty, textInputView.isFirstResponder {
            textInputView.resignFirstResponder()
        }
    }
}
