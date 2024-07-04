//
//  testxcode.hpp
//  
//
//  Created by Jason on 2024/6/11.
//

#ifndef testxcode_hpp
#define testxcode_hpp

#include <stdio.h>
#include <vector>
#include <string>


#ifdef __cplusplus
extern "C" {
#endif

struct text_struct {
    int x;
    char y;
    std::string h;
    std::vector<std::string> test_vector;
};

int get_xcode_test();

#ifdef __cplusplus
}
#endif

#endif /* testxcode_hpp */
