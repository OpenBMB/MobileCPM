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
import SnapKit

/// 充当 section header，footer view
class MBHomeSectionSupplementView: UICollectionReusableView {
    static let header = "SAIHomeV2SectionHeaderViewID"
    static let footer = "SAIHomeV2SectionFooterViewID"
    override init(frame: CGRect) {
        super.init(frame: frame)
        configBaseView()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func configBaseView() {
        addSubview(testLab)
        testLab.snp.makeConstraints { make in
            make.left.equalTo(12)
            make.right.equalTo(-12)
            make.centerY.equalTo(self)
            make.height.equalTo(14)
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
    }
    
    lazy var testLab: UILabel = {
        let tmp = UILabel()
        tmp.textColor = .white
        tmp.font = .systemFont(ofSize: 14)
        tmp.textAlignment = .center
        tmp.numberOfLines = 0
        return tmp
    }()
}
