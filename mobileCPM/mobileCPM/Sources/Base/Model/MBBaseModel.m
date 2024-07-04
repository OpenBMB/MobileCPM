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

#import "MBBaseModel.h"
#import <objc/runtime.h>

@implementation MBBaseModel

/// debug `po` 时，打印所有属性
- (NSString *)description {
    NSMutableString *desc = [NSMutableString string];
    unsigned int count;
    objc_property_t *props = class_copyPropertyList([self class], &count);
    for (int i = 0; i < count; i++) {
        objc_property_t property = props[i];
        const char *name = property_getName(property);
        NSString *propertyName = [NSString stringWithUTF8String:name];
        id propertyValue = [self valueForKey:propertyName];
        [desc appendFormat:@"%@: %@; \n", propertyName, propertyValue];
    }
    free(props);
    return desc;
}

@end
