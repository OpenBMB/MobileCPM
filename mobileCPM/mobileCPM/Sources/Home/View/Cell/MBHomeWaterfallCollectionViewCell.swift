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

class MBHomeWaterfallCollectionViewCell: UICollectionViewCell {
    static let identifiers = "waterfall"
    
    var model: MBHomeCardModel?

    weak var clickDelegate: MBHomeCellEventDelegate?

    lazy var imageView: UIImageView = {
        let img = UIImageView()
        img.contentMode = .scaleAspectFill
        img.clipsToBounds = true
        img.layer.cornerRadius = 14
        img.layer.masksToBounds = true
        img.isUserInteractionEnabled = true
        return img
    }()
    
    lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 13, weight: .regular)
        label.textColor = UIColor.mb_color(with: "#ffffff")
        return label
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)

        configBaseView()

        let tap = UITapGestureRecognizer(target: self, action: #selector(handleTapImg))
        imageView.addGestureRecognizer(tap)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func configBaseView() {
        addSubview(imageView)
        imageView.snp.makeConstraints { make in
            make.top.left.right.equalTo(self)
            make.height.equalTo(0)
        }
        addSubview(titleLabel)
        titleLabel.snp.makeConstraints { make in
            make.left.equalTo(14)
            make.right.equalTo(-10).priority(.low)
            make.bottom.equalTo(imageView.snp.bottom).offset(-10)
            make.height.equalTo(14)
        }

        let blurEffect = UIBlurEffect(style: .light)
        let blurEffectView = UIVisualEffectView(effect: blurEffect)
        blurEffectView.layer.cornerRadius = 7
        blurEffectView.clipsToBounds = true
        addSubview(blurEffectView)
        blurEffectView.snp.makeConstraints { make in
            make.left.equalTo(titleLabel.snp.left).offset(-8)
            make.right.equalTo(titleLabel.snp.right).offset(8)
            make.top.equalTo(titleLabel.snp.top).offset(-4)
            make.bottom.equalTo(titleLabel.snp.bottom).offset(4)
        }
        bringSubviewToFront(titleLabel)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
   
    }
    
    public func bindWidthData(data : MBHomeCardModel?) {

        model = data

        if let avatar = data?.avatar {
            let fullFileName = avatar.components(separatedBy: ".")
            if let avatarPath = Bundle.main.path(forResource: fullFileName.first, ofType: fullFileName.last),
               let avatarData = NSData(contentsOfFile: avatarPath) as? Data {
                imageView.image = UIImage(data: avatarData)
                
                var width = UIApplication.shared.keyWindow?.frame.size.width ?? 0
                width = (width - 12 - 12 - 6) / 2
                let height = ceilf(Float(width) * 1.55)

                imageView.snp.remakeConstraints { make in
                    make.top.left.right.equalTo(self)
                    make.height.equalTo(height)
                }
            }
        }
        
        titleLabel.text = model?.name ?? ""
    }
    
    // MARK: - 点击事件
    @objc public func handleTapImg(_ tap: UITapGestureRecognizer) {
        if let del = self.clickDelegate, let data = model {
            del.didClickCell?(with: data, extra: nil)
        }
    }
    
}
