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
import SnapKit

enum MBFloatingActionStatus: CustomStringConvertible {
    case continued
    case paused
    
    var description: String {
        switch self {
        case .continued:
            return "continued"
        case .paused:
            return "paused"
        }
    }
}

/// 开始生成时，悬浮的 暂停 or 继续 生成 button view
class MBFloatingActionView: UIView {

    // 当前状态
    var currentStatus: MBFloatingActionStatus = .continued
    
    /// 点击事件
    public var onTap: ((String?) -> Void)?

    /// icon
    lazy var iconImageView: UIImageView = {
        let img = UIImageView.init(image: UIImage(named: "generate_pause"))
        img.contentMode = .scaleAspectFill
        img.clipsToBounds = true
        
        return img
    }()

    /// text
    lazy var titleLabel: UILabel = {
        let lb = UILabel()
        if MBUtils.isDeviceIPad() {
            lb.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        } else {
            lb.font = UIFont.systemFont(ofSize: 10, weight: .medium)
        }
        lb.textColor = UIColor.mb_color(with: "#4967FA", alpha: 1)
        lb.text = "终止生成"
        return lb
    }()
    
    // 初始化方法，通过代码创建视图实例时会调用此方法
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }
    
    // 初始化方法，通过 Interface Builder 创建视图实例时会调用此方法
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupView()
    }
    
    // 设置视图和其子视图的布局和样式
    private func setupView() {
        
        self.isUserInteractionEnabled = true
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTapButton))
        addGestureRecognizer(tapGesture)

        self.clipsToBounds = true
        self.layer.cornerRadius = 16
        self.backgroundColor = .white
        
        addSubview(iconImageView)
        iconImageView.snp.makeConstraints { make in
            make.centerY.equalTo(self)
            make.left.equalTo(12)
            make.width.height.equalTo(28)
        }
        
        addSubview(titleLabel)
        titleLabel.snp.makeConstraints { make in
            make.centerY.equalTo(self)
            make.left.equalTo(iconImageView.snp.right).offset(10)
            make.height.equalTo(18)
        }
    }
    
    /// 点击事件
    @objc func handleTapButton(_ id: UITapGestureRecognizer) {

        /*
        if currentStatus == .continued {
            currentStatus = .paused
            iconImageView.image = UIImage(named: "generate_continue")
            titleLabel.text = "继续生成"
        } else {
            currentStatus = .continued
            iconImageView.image = UIImage(named: "generate_pause")
            titleLabel.text = "暂停生成"
        }*/
        
        // 最后，交给上层 VC 处理
        onTap?(currentStatus.description)
        
        self.isHidden = true
    }
    
}