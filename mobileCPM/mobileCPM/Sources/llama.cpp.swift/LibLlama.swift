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
import llama
import common
import minicpmv
import minicpmv_wrapper
import CxxStdlib

/// 定义 llama.cpp 自定义错误
enum LlamaError: Error {
    /// 初始化错误
    case couldNotInitializeContext
    /// 采样错误
    case couldNotInitializeSamplingContext
}

/// 全局便捷方法，清空 or 重置的方法，inout 方法可以修改传入的对象中的属性
func llama_batch_clear(_ batch: inout llama_batch) {
    // llama_batch（结构体） 对象 tokens 属性置 0
    batch.n_tokens = 0
}

/// 全局便捷方法，inout llama_batch 属性修改值
func llama_batch_add(_ batch: inout llama_batch,
                     _ id: llama_token,
                     _ pos: llama_pos,
                     _ seq_ids: [llama_seq_id],
                     _ logits: Bool) {
    
    batch.token   [Int(batch.n_tokens)] = id
    batch.pos     [Int(batch.n_tokens)] = pos
    batch.n_seq_id[Int(batch.n_tokens)] = Int32(seq_ids.count)
    
    for i in 0..<seq_ids.count {
        batch.seq_id[Int(batch.n_tokens)]![Int(i)] = seq_ids[i]
    }
    
    batch.logits  [Int(batch.n_tokens)] = logits ? 1 : 0
    
    batch.n_tokens += 1
}

/// llama.cpp 上下文结构体，actor 是并发模型，行为类似于 class，不过不能继承，也不能遵守任何协议，可以封装数据和方法，并以线程安全的方式访问它们
actor LlamaContext {
    
    /*
     OpaquePointer 在 Swift 与 C 语言交互时常常使用，因为 C 语言的代码库通常会使用 void* 类型来表示各种不同类型的指针。
     */
    
    /// 指向 struct llama_model 结构体类型
    private var model: OpaquePointer
    
    /// 指向 struct llama_context 结构体类型
    private var context: OpaquePointer
    
    /*
     在 Swift 中，UnsafeMutablePointer 是一个指向某个值的可变指针。
     你可以看到，UnsafeMutablePointer 具有一个 pointee 属性用来获取或修改指针所指向的值。
     */
    
    /// 指向 minicpmv_context 结构体指针
    private var context_llava: UnsafeMutablePointer<minicpmv_context>
    
    /// 指向 llama_sampling_context 采样上下文结构体指针
    private var ctx_sampling: UnsafeMutablePointer<llama_sampling_context>
    
    /// 一个结构体，Input data for llama_decode
    private var batch: llama_batch
    
    /// ⚠️ llama_token 是个 typedef，实际类型是 int32_t
    private var tokens_list: [llama_token]
    
    /// This variable is used to store temporarily invalid cchars
    private var temporary_invalid_cchars: [CChar]
    
    var n_len: Int32 = 1024
    var n_cur: Int32 = 0
    var n_ctx: Int32 = 4096
    
    /// minicpm 专用模版
    var chat_template = "<用户>{{prompt}}\n<AI>"
    
    private var system_prompt = ""
    private var n_keep: Int32 = 4
    var n_decode: Int32 = 0
    
    
    /// LlamaContext init 方法
    /// - Parameters:
    ///   - context: 上下文
    ///   - ctxSampling: 采样
    ///   - nCur: current（默认 0）
    ///   - nCtx: 上下文长度（默认 4k）
    init(context: UnsafeMutablePointer<minicpmv_context>,
         ctxSampling: UnsafeMutablePointer<llama_sampling_context>,
         nCur:Int32 = 0,
         nCtx:Int32 = 4096) {
        self.context_llava = context
        self.model = context.pointee.model
        self.context = context.pointee.ctx_llama
        self.ctx_sampling = ctxSampling
        self.tokens_list = []
        self.batch = llama_batch_init(512, 0, 1)
        self.temporary_invalid_cchars = []
        self.n_cur = nCur
        self.n_ctx = nCtx
    }
    
    /// deinit 清空上下文
    deinit {
        llama_batch_free(batch)
        llama_free(context)
        llama_free_model(model)
        llama_backend_free()
    }
    
    /// 暴露给业务侧的超参数修改器
    /// - Parameters:
    ///   - temp: 温度
    ///   - penalty_repeat: 惩罚者
    ///   - seed: 种子
    ///   - top_p: p
    ///   - top_k: k
    func set_sampling_params(temp: Float32,
                             penalty_repeat: Float32,
                             seed: UInt32,
                             top_p: Float32,
                             top_k: Int32) {
        self.ctx_sampling.pointee.params.penalty_repeat = penalty_repeat
        self.ctx_sampling.pointee.params.temp = temp
        self.ctx_sampling.pointee.params.seed = seed
        self.ctx_sampling.pointee.params.top_p = top_p
        self.ctx_sampling.pointee.params.top_k = top_k
    }
    
    /// 全局（静态）的创建采样上下文的方法
    static func create_sampling_context(gparams: UnsafePointer<gpt_params>) throws -> UnsafeMutablePointer<llama_sampling_context> {
        
        let ctxSampling = llama_sampling_init(gparams.pointee.sparams)
        
        guard let ctxSampling else {
            print("Could not init sampling context!")
            throw LlamaError.couldNotInitializeSamplingContext
        }
        
        ctxSampling.pointee.params.temp = 0.3
        ctxSampling.pointee.params.penalty_repeat = 1.05
        ctxSampling.pointee.params.seed = UInt32(NSDate().timeIntervalSince1970)
        ctxSampling.pointee.params.top_k = 100
        ctxSampling.pointee.params.top_p = 0.2
        
        return ctxSampling
    }

    /// setter: 设置「模版」（用来格式化回复内容用的）
    private func set_chat_template(template: String) {
        chat_template = template
    }
    
    /// setter: 设置「系统级提示词」（可以设置故事背景）
    private func set_system_prompt(system_prompt: String) {
        self.system_prompt = system_prompt
        eval_string(context_llava.pointee.ctx_llama, system_prompt, 2048, &n_cur, false)
        n_keep = n_cur
    }
    
    /// setter: 设置聊天历史（可以恢复记忆）
    private func set_history(history: String) {
        eval_string(context_llava.pointee.ctx_llama, history, 2048, &n_cur, false)
    }
    
    /// 全局（静态）方法，创建「语言模型」对象的上下文
    static func create_context(path: String,
                               template:String = "",
                               system_prompt:String = "",
                               history: String = "",
                               nCtx: Int32 = 4096) async throws -> LlamaContext {
        
        var gparams:gpt_params = gpt_params()
        
        gparams.model = std.string(path)
        gparams.n_ctx = nCtx
        let n_threads = max(1, min(8, ProcessInfo.processInfo.processorCount - 2))
        gparams.n_threads = Int32(n_threads)
        gparams.n_threads_batch = Int32(n_threads)
        let model = llava_init(&gparams)
        
        guard let model else {
            print("Could not load model at \(path)")
            throw LlamaError.couldNotInitializeContext
        }
        
        let ctxLlava = llava_init_context(&gparams, model)
        
        guard let ctxLlava else {
            throw LlamaError.couldNotInitializeContext
        }
        
        let ctxSampling = try create_sampling_context(gparams: &gparams)
        
        let ctx = LlamaContext(context: ctxLlava,
                               ctxSampling: ctxSampling,
                               nCtx: gparams.n_ctx)
        
        if template != "" {
            await ctx.set_chat_template(template: template)
        }
        
        if system_prompt != "" {
            await ctx.set_system_prompt(system_prompt: system_prompt)
        }
        
        if history != "" {
            await ctx.set_history(history: history)
        }
        
        return ctx
    }
    
    /// 获取模型信息
    func model_info() -> String {
        
        let result = UnsafeMutablePointer<Int8>.allocate(capacity: 256)
        
        result.initialize(repeating: Int8(0), count: 256)
        
        defer {
            result.deallocate()
        }
        
        // TODO: this is probably very stupid way to get the string from C
        let nChars = llama_model_desc(model, result, 256)
        let bufferPointer = UnsafeBufferPointer(start: result, count: Int(nChars))
        
        var SwiftString = ""
        for char in bufferPointer {
            SwiftString.append(Character(UnicodeScalar(UInt8(char))))
        }
        
        return SwiftString
    }
    
    /// 便捷方法，获取 batch 中的 tokens
    func get_n_tokens() -> Int32 {
        return batch.n_tokens;
    }
    
    /// 具体的、续写方法，其中 text 是用户的输入
    func completion_init(text: String) {
        print("attempting to complete \"\(text)\"")
        
        tokens_list = tokenize(text: text, add_bos: true)
        temporary_invalid_cchars = []
        
        let n_ctx = llama_n_ctx(context)
        let n_kv_req = tokens_list.count + (Int(n_len) - tokens_list.count)
        
        print("\n n_len = \(n_len), n_ctx = \(n_ctx), n_kv_req = \(n_kv_req)")
        
        if n_kv_req > n_ctx {
            print("error: n_kv_req > n_ctx, the required KV cache size is not big enough")
        }
        
        for id in tokens_list {
            print(String(cString: token_to_piece(token: id) + [0]))
        }
        
        llama_batch_clear(&batch)
        
        for i1 in 0..<tokens_list.count {
            let i = Int(i1)
            llama_batch_add(&batch, tokens_list[i], Int32(i), [0], false)
        }
        batch.logits[Int(batch.n_tokens) - 1] = 1 // true
        
        if llama_decode(context, batch) != 0 {
            print("llama_decode() failed")
        }
        
        n_cur = batch.n_tokens
    }
    
    /// 多模态模型，开始说话
    func chat_init(text: String) {
        print("user prompt: \"\(text)\"")
        let prompt = text
        eval_string(context_llava.pointee.ctx_llama, prompt, 128, &n_cur, false)
        eval_string(context_llava.pointee.ctx_llama, "<|eot_id|><|start_header_id|>assistant<|end_header_id|>\n\n", 128, &n_cur, false)
    }
    
    /// 语言模型，开始说话
    func chat_init_minicpm(text:String) {
        print("user prompt: \"\(text)\"")
        
        var prompt = chat_template
        prompt.replace("{{prompt}}", with:text)
        
        eval_string(context_llava.pointee.ctx_llama, prompt, 1024, &n_cur, false)
    }
    
    /// 结束说话，就是加一个结构标记，形成一个标签，为了下次说话格式正确
    func chat_end(eot: String) {
        eval_string(context_llava.pointee.ctx_llama, eot, 128, &n_cur, false)
    }
    
    /// 关键方法之一，循环地说，说到 </s> 结束
    func chat_loop() -> String {
        
        let new_char_pointer = sample(ctx_sampling, context_llava.pointee.ctx_llama, &n_cur)
        
        var new_token_cchars = [CChar]()
        
        // Iterate through the memory pointed to by unsafePointer until you encounter a null terminator
        var currentPointer = new_char_pointer
        while currentPointer.pointee != 0 {
            new_token_cchars.append(currentPointer.pointee)
            currentPointer = currentPointer?.advanced(by: 1)
        }
        
        temporary_invalid_cchars.append(contentsOf: new_token_cchars)
        
        let new_token_str: String
        if let string = String(validatingUTF8: temporary_invalid_cchars + [0]) {
            temporary_invalid_cchars.removeAll()
            new_token_str = string
        } else if (0 ..< temporary_invalid_cchars.count).contains(where: {$0 != 0 && String(validatingUTF8: Array(temporary_invalid_cchars.suffix($0)) + [0]) != nil}) {
            // in this case, at least the suffix of the temporary_invalid_cchars can be interpreted as UTF8 string
            let string = String(cString: temporary_invalid_cchars + [0])
            temporary_invalid_cchars.removeAll()
            new_token_str = string
        } else {
            new_token_str = ""
        }
        
        print(new_token_str)
        
        check_kv_cache()
        
        return new_token_str
    }
    
    /// 内部私有方法，检查 kv cache
    private func check_kv_cache() {
        if n_cur > n_ctx {
            let n_left = n_cur - n_keep
            let n_discard = n_left / 2
            llama_kv_cache_seq_rm (context, 0, n_keep, n_keep + n_discard);
            llama_kv_cache_seq_add(context, 0, n_keep + n_discard, n_cur, -n_discard);
            n_cur -= n_discard
        }
    }
    
    /// 循环方法
    func completion_loop() -> String {
        var new_token_id: llama_token = 0
        
        let n_vocab = llama_n_vocab(model)
        let logits = llama_get_logits_ith(context, batch.n_tokens - 1)
        
        var candidates = Array<llama_token_data>()
        candidates.reserveCapacity(Int(n_vocab))
        
        for token_id in 0..<n_vocab {
            candidates.append(llama_token_data(id: token_id, logit: logits![Int(token_id)], p: 0.0))
        }
        candidates.withUnsafeMutableBufferPointer() { buffer in
            var candidates_p = llama_token_data_array(data: buffer.baseAddress, size: buffer.count, sorted: false)
            
            new_token_id = llama_sample_token_greedy(context, &candidates_p)
        }
        
        if llama_token_is_eog(model, new_token_id) || n_cur == n_len {
            print("\n")
            let new_token_str = String(cString: temporary_invalid_cchars + [0])
            temporary_invalid_cchars.removeAll()
            return new_token_str
        }
        
        let new_token_cchars = token_to_piece(token: new_token_id)
        temporary_invalid_cchars.append(contentsOf: new_token_cchars)
        let new_token_str: String
        if let string = String(validatingUTF8: temporary_invalid_cchars + [0]) {
            temporary_invalid_cchars.removeAll()
            new_token_str = string
        } else if (0 ..< temporary_invalid_cchars.count).contains(where: {$0 != 0 && String(validatingUTF8: Array(temporary_invalid_cchars.suffix($0)) + [0]) != nil}) {
            // in this case, at least the suffix of the temporary_invalid_cchars can be interpreted as UTF8 string
            let string = String(cString: temporary_invalid_cchars + [0])
            temporary_invalid_cchars.removeAll()
            new_token_str = string
        } else {
            new_token_str = ""
        }
        print(new_token_str)
        
        llama_batch_clear(&batch)
        llama_batch_add(&batch, new_token_id, n_cur, [0], true)
        
        n_decode += 1
        n_cur    += 1
        
        if llama_decode(context, batch) != 0 {
            print("failed to evaluate llama!")
        }
        
        return new_token_str
    }
    
    /// 评测用方法
    /// - Parameters:
    ///   - pp: pp
    ///   - tg: tg
    ///   - pl: pl
    ///   - nr: nr
    /// - Returns: 返回结果
    func bench(pp: Int, tg: Int, pl: Int, nr: Int = 1) -> String {
        var pp_avg: Double = 0
        var tg_avg: Double = 0
        
        var pp_std: Double = 0
        var tg_std: Double = 0
        
        for _ in 0..<nr {
            // bench prompt processing
            
            llama_batch_clear(&batch)
            
            let n_tokens = pp
            
            for i in 0..<n_tokens {
                llama_batch_add(&batch, 0, Int32(i), [0], false)
            }
            batch.logits[Int(batch.n_tokens) - 1] = 1 // true
            
            llama_kv_cache_clear(context)
            
            let t_pp_start = ggml_time_us()
            
            if llama_decode(context, batch) != 0 {
                print("llama_decode() failed during prompt")
            }
            llama_synchronize(context)
            
            let t_pp_end = ggml_time_us()
            
            // bench text generation
            
            llama_kv_cache_clear(context)
            
            let t_tg_start = ggml_time_us()
            
            for i in 0..<tg {
                llama_batch_clear(&batch)
                
                for j in 0..<pl {
                    llama_batch_add(&batch, 0, Int32(i), [Int32(j)], true)
                }
                
                if llama_decode(context, batch) != 0 {
                    print("llama_decode() failed during text generation")
                }
                llama_synchronize(context)
            }
            
            let t_tg_end = ggml_time_us()
            
            llama_kv_cache_clear(context)
            
            let t_pp = Double(t_pp_end - t_pp_start) / 1000000.0
            let t_tg = Double(t_tg_end - t_tg_start) / 1000000.0
            
            let speed_pp = Double(pp)    / t_pp
            let speed_tg = Double(pl*tg) / t_tg
            
            pp_avg += speed_pp
            tg_avg += speed_tg
            
            pp_std += speed_pp * speed_pp
            tg_std += speed_tg * speed_tg
            
            print("pp \(speed_pp) t/s, tg \(speed_tg) t/s")
        }
        
        pp_avg /= Double(nr)
        tg_avg /= Double(nr)
        
        if nr > 1 {
            pp_std = sqrt(pp_std / Double(nr - 1) - pp_avg * pp_avg * Double(nr) / Double(nr - 1))
            tg_std = sqrt(tg_std / Double(nr - 1) - tg_avg * tg_avg * Double(nr) / Double(nr - 1))
        } else {
            pp_std = 0
            tg_std = 0
        }
        
        let model_desc     = model_info();
        let model_size     = String(format: "%.2f GiB", Double(llama_model_size(model)) / 1024.0 / 1024.0 / 1024.0);
        let model_n_params = String(format: "%.2f B", Double(llama_model_n_params(model)) / 1e9);
        let backend        = "Metal";
        let pp_avg_str     = String(format: "%.2f", pp_avg);
        let tg_avg_str     = String(format: "%.2f", tg_avg);
        let pp_std_str     = String(format: "%.2f", pp_std);
        let tg_std_str     = String(format: "%.2f", tg_std);
        
        var result = ""
        
        result += String("| model | size | params | backend | test | t/s |\n")
        result += String("| --- | --- | --- | --- | --- | --- |\n")
        result += String("| \(model_desc) | \(model_size) | \(model_n_params) | \(backend) | pp \(pp) | \(pp_avg_str) ± \(pp_std_str) |\n")
        result += String("| \(model_desc) | \(model_size) | \(model_n_params) | \(backend) | tg \(tg) | \(tg_avg_str) ± \(tg_std_str) |\n")
        
        return result;
    }
    
    /// 清除用的方法
    func clear() {
        tokens_list.removeAll()
        temporary_invalid_cchars.removeAll()
        llama_kv_cache_clear(context)
    }
    
    /// 内部方法，token-化
    private func tokenize(text: String, add_bos: Bool) -> [llama_token] {
        let utf8Count = text.utf8.count
        let n_tokens = utf8Count + (add_bos ? 1 : 0) + 1
        let tokens = UnsafeMutablePointer<llama_token>.allocate(capacity: n_tokens)
        let tokenCount = llama_tokenize(model, text, Int32(utf8Count), tokens, Int32(n_tokens), add_bos, false)
        
        var swiftTokens: [llama_token] = []
        for i in 0..<tokenCount {
            swiftTokens.append(tokens[Int(i)])
        }
        
        tokens.deallocate()
        
        return swiftTokens
    }
    
    /// - note: The result does not contain null-terminator
    private func token_to_piece(token: llama_token) -> [CChar] {
        let result = UnsafeMutablePointer<Int8>.allocate(capacity: 8)
        result.initialize(repeating: Int8(0), count: 8)
        defer {
            result.deallocate()
        }
        let nTokens = llama_token_to_piece(model, token, result, 8, false)
        
        if nTokens < 0 {
            let newResult = UnsafeMutablePointer<Int8>.allocate(capacity: Int(-nTokens))
            newResult.initialize(repeating: Int8(0), count: Int(-nTokens))
            defer {
                newResult.deallocate()
            }
            let nNewTokens = llama_token_to_piece(model, token, newResult, -nTokens, false)
            let bufferPointer = UnsafeBufferPointer(start: newResult, count: Int(nNewTokens))
            return Array(bufferPointer)
        } else {
            let bufferPointer = UnsafeBufferPointer(start: result, count: Int(nTokens))
            return Array(bufferPointer)
        }
    }
    
}

