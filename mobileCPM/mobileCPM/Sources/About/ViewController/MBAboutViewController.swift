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

/// 关于 ViewController
class MBAboutViewController: UIViewController {
    
    lazy var appIconImageView: UIImageView = {
        let img = UIImageView()
        img.contentMode = .scaleAspectFill
        img.clipsToBounds = true
        img.layer.cornerRadius = 8
        return img
    }()
    
    lazy var versionLabel: UILabel = {
        let lbl = UILabel()
        lbl.textAlignment = .center
        lbl.font = .systemFont(ofSize: 14, weight: .regular)
        lbl.textColor = .black
        return lbl
    }()
    
    lazy var copyrightLabel: UILabel = {
        let lbl = UILabel()
        lbl.textAlignment = .center
        lbl.font = .systemFont(ofSize: 12, weight: .regular)
        lbl.textColor = .darkGray
        return lbl
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupNavView()
        
        setupSubViews()
    }
    
    // MARK: - 创建 子 view
    
    func setupNavView() {
        var img = UIImage(named: "back_icon")
        img = img?.mb_imageCompress(forWidth: img ?? UIImage(), targetWidth: 22)
        let leftNavIcon = UIBarButtonItem(image: img,
                                          style: .plain,
                                          target: self,
                                          action: #selector(handleLeftNavIcon))
        self.navigationItem.leftBarButtonItem = leftNavIcon
        self.navigationItem.leftBarButtonItem?.tintColor = .black
        
        self.navigationController?.navigationBar.backgroundColor = .white
    }

    func setupSubViews() {
        
        self.title = "关于"
        
        view.backgroundColor = UIColor.mb_color(with: "#F9FAFC")
        
        view.addSubview(appIconImageView)
        appIconImageView.snp.makeConstraints { make in
            make.centerX.equalTo(self.view)
            make.top.equalTo(128)
            make.width.height.equalTo(48)
        }
        
        if let iconsDictionary = Bundle.main.infoDictionary?["CFBundleIcons"] as? [String: Any],
            let primaryIconsDictionary = iconsDictionary["CFBundlePrimaryIcon"] as? [String: Any],
            let iconFiles = primaryIconsDictionary["CFBundleIconFiles"] as? [String],
            let lastIcon = iconFiles.last {
            let icon = UIImage(named: lastIcon)
            appIconImageView.image = icon
        }
        
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? ""

        let buildNumber = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? ""
        
        versionLabel.text = "v\(version)(\(buildNumber))"
        
        view.addSubview(versionLabel)
        versionLabel.snp.makeConstraints { make in
            make.centerX.equalTo(self.view)
            make.top.equalTo(self.appIconImageView.snp.bottom).offset(24)
            make.height.equalTo(14)
        }
        
        copyrightLabel.text = "© 2024 北京智能涌现科技有限公司 版权所有"
        view.addSubview(copyrightLabel)
        copyrightLabel.snp.makeConstraints { make in
            make.centerX.equalTo(self.view)
            make.bottom.equalTo(-44)
            make.height.equalTo(14)
        }
    }
    
    // MARK: - 点击事件
    
    @objc public func handleLeftNavIcon() {
        self.navigationController?.popViewController(animated: true)
    }

}
