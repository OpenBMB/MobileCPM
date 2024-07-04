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

/// 设置页 cell 要用的 model
class MBSettingModel: NSObject {
    
    /// cell 用的图标
    var icon: UIImage?
    
    /// cell 标题
    var title: String?
    
    /// 右边附属 icon 样式
    var accessoryIcon: UIImage?
    
    /// 是否有选中状态：'none', 'downloaded', 'selected'
    var status: String?
    
    /// download, downloading, downloaded
    var statusString: String?
    
    /// 选中 arrow icon
    var selectedIcon: UIImage?
}
