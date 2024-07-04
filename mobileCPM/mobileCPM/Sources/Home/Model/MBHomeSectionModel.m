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

#import "MBHomeSectionModel.h"

@interface MBHomeSectionModel ()

@property (nonatomic, copy) NSString *uuid;

@end

@implementation MBHomeSectionModel

- (instancetype)init {
    if (self = [super init]) {
        self.uuid = [self genUUID];
    }
    
    return self;
}

#pragma mark - IGListDiffable

- (nonnull id<NSObject>)diffIdentifier {
    return self.uuid;
}

- (NSString *)genUUID {
    NSString *uuidString = [[NSUUID UUID] UUIDString];
    return uuidString;
}

- (BOOL)isEqualToDiffableObject:(MBHomeSectionModel *)object {
    if (self == object) {
        return YES;
    }
    if (![object isKindOfClass:[MBHomeSectionModel class]]) {
        return NO;
    }

    return [self.objID isEqualToString:((MBHomeSectionModel *)object).objID] &&
    [self.type isEqualToString:((MBHomeSectionModel *)object).type];
}

@end
