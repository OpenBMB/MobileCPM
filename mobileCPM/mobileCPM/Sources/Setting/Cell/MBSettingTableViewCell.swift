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

/// 设置页的 cell
class MBSettingTableViewCell: UITableViewCell {
    
    let gap = 16
    
    private let iconImageView = UIImageView()
    private let titleLabel = UILabel()
    
    /// 当前生效的模型
    private let selectedImageView = UIImageView()
    
    /// 更多 > icon
    private let accessoryImageView = UIImageView()
    
    /// 模型状态 label
    private let statusLabel = UILabel()
    
    public var model : MBSettingModel?
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupViews()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupViews() {
        
        self.contentView.backgroundColor = .white
        
        // 配置 iconImageView
        iconImageView.clipsToBounds = true
        contentView.addSubview(iconImageView)
        iconImageView.snp.makeConstraints { make in
            make.centerY.equalTo(contentView)
            make.left.equalTo(12 + gap)
            make.width.height.equalTo(22)
        }
        
        // 配置 titleLabel
        titleLabel.textColor = .black
        titleLabel.font = .systemFont(ofSize: 14, weight: .medium)
        contentView.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { make in
            make.centerY.equalTo(contentView)
            make.height.equalTo(28)
            make.left.equalTo(self.iconImageView.snp.right).offset(12)
            make.right.equalTo(-88)
        }
        
        accessoryImageView.clipsToBounds = true
        contentView.addSubview(accessoryImageView)
        accessoryImageView.snp.makeConstraints { make in
            make.centerY.equalTo(contentView)
            make.width.height.equalTo(22)
            make.right.equalTo(-12 - gap)
        }
        
        statusLabel.textColor = .black
        statusLabel.font = .systemFont(ofSize: 11, weight: .regular)
        statusLabel.textAlignment = .right
        contentView.addSubview(statusLabel)
        statusLabel.snp.makeConstraints { make in
            make.centerY.equalTo(contentView)
            make.width.equalTo(128)
            make.right.equalTo(-12 - gap)
            make.height.equalTo(16)
        }
    }
    
    // 配置视图的方法
    func configure(with model: MBSettingModel?) {
        guard let model = model else {
            return
        }
        
        self.model = model
        
        iconImageView.image = model.icon
        titleLabel.text = model.title
                
        if model.status == "downloaded" {
            accessoryImageView.image = nil
            statusLabel.text = "已下载"
        } else if model.status == "selected" {
            accessoryImageView.isHidden = false
            accessoryImageView.image = model.selectedIcon
            statusLabel.text = ""
        } else /* none */ {
            if let acc = model.accessoryIcon {
                accessoryImageView.image = acc
            } else if let statusStr = model.statusString {
                // 模型未下载
                statusLabel.text = statusStr
                accessoryImageView.isHidden = true
            }
        }
    }
    
}
