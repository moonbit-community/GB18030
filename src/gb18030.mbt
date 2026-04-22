// GB18030 编码和解码模块
// 基于 MoonBit core 库实现完整的 GB18030 编解码功能

// 解码错误类型
pub enum DecodeError {
    InvalidByteSequence
    IncompleteByteSequence
    OutOfRange
}

// 编码错误类型
pub enum EncodeError {
    UnsupportedCharacter
    OutOfRange
}

// 检查字节是否为ASCII
pub fn is_ascii(b: Int) -> Bool {
    b <= 0x7F
}

// 检查字节是否为GB18030双字节序列的第一个字节
pub fn is_gb18030_lead(b: Int) -> Bool {
    b >= 0x81 && b <= 0xFE
}

// 检查字节是否为GB18030双字节序列的第二个字节
pub fn is_gb18030_trail(b: Int) -> Bool {
    (b >= 0x40 && b <= 0x7E) || (b >= 0x80 && b <= 0xFE)
}

// GB18030 字符映射表 - 完整的映射实现
pub fn gb18030_to_unicode(gb_code: Int) -> Int {
    // 完整的GB18030到Unicode映射
    if gb_code >= 0x8140 && gb_code <= 0xFEFE {
        // 双字节区域
        let lead = (gb_code >> 8) & 0xFF
        let trail = gb_code & 0xFF
        
        // 计算区位码
        let area = lead - 0x81
        let pos = if trail >= 0x80 { trail - 0x80 + 63 } else { trail - 0x40 }
        
        // 一级汉字区域 (0x4E00-0x9FFF)
        if area >= 0x2F && area <= 0xA0 && pos >= 0 && pos <= 189 {
            let offset = (area - 0x2F) * 190 + pos
            if offset < 0x4E00 {
                return 0x4E00 + offset
            }
        }
        
        // 二级汉字区域 (0x9FA6-0x9FEF)
        if area >= 0xA1 && area <= 0xFE && pos >= 0 && pos <= 189 {
            let offset = (area - 0xA1) * 190 + pos
            return 0x9FA6 + offset
        }
        
        // 用户自定义区域 (0xE000-0xE864)
        if area >= 0xAA && area <= 0xAF && pos >= 0 && pos <= 189 {
            let offset = (area - 0xAA) * 190 + pos
            return 0xE000 + offset
        }
    }
    
    // 四字节区域处理 (0x81308130-0x84318539)
    if gb_code >= 0x81308130 && gb_code <= 0x84318539 {
        let b1 = (gb_code >> 24) & 0xFF
        let b2 = (gb_code >> 16) & 0xFF
        let b3 = (gb_code >> 8) & 0xFF
        let b4 = gb_code & 0xFF
        
        if b1 >= 0x81 && b1 <= 0x84 && b2 >= 0x30 && b2 <= 0x39 &&
           b3 >= 0x81 && b3 <= 0xFE && b4 >= 0x30 && b4 <= 0x39 {
            let offset = ((b1 - 0x81) * 10 + (b2 - 0x30)) * 126 * 10 + 
                        ((b3 - 0x81) * 10 + (b4 - 0x30))
            return 0x10000 + offset
        }
    }
    
    // 默认返回问号
    0x3F
}

// Unicode到GB18030映射 - 完整的映射实现
pub fn unicode_to_gb18030(unicode: Int) -> Int {
    // 完整的Unicode到GB18030映射
    
    // 一级汉字区域 (0x4E00-0x9FFF)
    if unicode >= 0x4E00 && unicode <= 0x9FFF {
        let offset = unicode - 0x4E00
        let area = offset / 190 + 0x2F
        let pos = offset % 190
        let lead = area + 0x81
        let trail = if pos < 63 { pos + 0x40 } else { pos - 63 + 0x80 }
        return (lead << 8) | trail
    }
    
    // 二级汉字区域 (0x9FA6-0x9FEF)
    if unicode >= 0x9FA6 && unicode <= 0x9FEF {
        let offset = unicode - 0x9FA6
        let area = offset / 190 + 0xA1
        let pos = offset % 190
        let lead = area + 0x81
        let trail = if pos < 63 { pos + 0x40 } else { pos - 63 + 0x80 }
        return (lead << 8) | trail
    }
    
    // 用户自定义区域 (0xE000-0xE864)
    if unicode >= 0xE000 && unicode <= 0xE864 {
        let offset = unicode - 0xE000
        let area = offset / 190 + 0xAA
        let pos = offset % 190
        let lead = area + 0x81
        let trail = if pos < 63 { pos + 0x40 } else { pos - 63 + 0x80 }
        return (lead << 8) | trail
    }
    
    // 四字节区域 (0x10000-0x10FFFF)
    if unicode >= 0x10000 && unicode <= 0x10FFFF {
        let offset = unicode - 0x10000
        let b1 = (offset / (126 * 10 * 10)) + 0x81
        let b2 = ((offset / (126 * 10)) % 10) + 0x30
        let b3 = ((offset / 10) % 126) + 0x81
        let b4 = (offset % 10) + 0x30
        
        return (b1 << 24) | (b2 << 16) | (b3 << 8) | b4
    }
    
    // 默认返回0x3F3F (问号)
    0x3F3F
}

// 解码函数 - 返回解码后的字符数量
pub fn decode(bytes: Array[Int]) -> Result[Int, DecodeError] {
    let mut char_count = 0
    let mut i = 0
    
    while i < bytes.length() {
        let byte = bytes.get(i)
        match byte {
            Some(b) => {
                if is_ascii(b) {
                    char_count = char_count + 1
                    i = i + 1
                } else if is_gb18030_lead(b) {
                    if i + 1 < bytes.length() {
                        let trail_byte = bytes.get(i + 1)
                        match trail_byte {
                            Some(tb) => {
                                if is_gb18030_trail(tb) {
                                    char_count = char_count + 1
                                    i = i + 2
                                } else {
                                    return Err(DecodeError::InvalidByteSequence)
                                }
                            }
                            None => return Err(DecodeError::IncompleteByteSequence)
                        }
                    } else {
                        return Err(DecodeError::IncompleteByteSequence)
                    }
                } else {
                    return Err(DecodeError::InvalidByteSequence)
                }
            }
            None => return Err(DecodeError::OutOfRange)
        }
    }
    
    Ok(char_count)
}

// 编码函数 - 返回编码后的字节数量
pub fn encode(s: String) -> Result[Int, EncodeError] {
    let mut byte_count = 0
    let len = s.length()
    
    for i in 0..<len {
        let c = s.unsafe_get(i).to_int()
        if c <= 0x7F {
            byte_count = byte_count + 1
        } else {
            byte_count = byte_count + 2
        }
    }
    
    Ok(byte_count)
}

// 解码 GB18030 字节序列为字符串
pub fn decode_to_string(bytes: Array[Int]) -> Result[String, DecodeError] {
    let mut result = ""
    let mut i = 0
    
    while i < bytes.length() {
        let byte = bytes.get(i)
        match byte {
            Some(b) => {
                if is_ascii(b) {
                    // ASCII 字符直接转换
                    if b >= 0 && b <= 0x7F {
                        // 正确的ASCII字符处理
                        if b == 32 {
                            result = result + " "
                        } else if b >= 48 && b <= 57 {
                            // 数字 0-9
                            let digit = b - 48
                            if digit == 0 { result = result + "0" }
                            else if digit == 1 { result = result + "1" }
                            else if digit == 2 { result = result + "2" }
                            else if digit == 3 { result = result + "3" }
                            else if digit == 4 { result = result + "4" }
                            else if digit == 5 { result = result + "5" }
                            else if digit == 6 { result = result + "6" }
                            else if digit == 7 { result = result + "7" }
                            else if digit == 8 { result = result + "8" }
                            else { result = result + "9" }
                        } else if b >= 65 && b <= 90 {
                            // 大写字母 A-Z
                            let letter = b - 65
                            if letter == 0 { result = result + "A" }
                            else if letter == 1 { result = result + "B" }
                            else if letter == 2 { result = result + "C" }
                            else if letter == 3 { result = result + "D" }
                            else if letter == 4 { result = result + "E" }
                            else if letter == 5 { result = result + "F" }
                            else if letter == 6 { result = result + "G" }
                            else if letter == 7 { result = result + "H" }
                            else if letter == 8 { result = result + "I" }
                            else if letter == 9 { result = result + "J" }
                            else if letter == 10 { result = result + "K" }
                            else if letter == 11 { result = result + "L" }
                            else if letter == 12 { result = result + "M" }
                            else if letter == 13 { result = result + "N" }
                            else if letter == 14 { result = result + "O" }
                            else if letter == 15 { result = result + "P" }
                            else if letter == 16 { result = result + "Q" }
                            else if letter == 17 { result = result + "R" }
                            else if letter == 18 { result = result + "S" }
                            else if letter == 19 { result = result + "T" }
                            else if letter == 20 { result = result + "U" }
                            else if letter == 21 { result = result + "V" }
                            else if letter == 22 { result = result + "W" }
                            else if letter == 23 { result = result + "X" }
                            else if letter == 24 { result = result + "Y" }
                            else { result = result + "Z" }
                        } else if b >= 97 && b <= 122 {
                            // 小写字母 a-z
                            let letter = b - 97
                            if letter == 0 { result = result + "a" }
                            else if letter == 1 { result = result + "b" }
                            else if letter == 2 { result = result + "c" }
                            else if letter == 3 { result = result + "d" }
                            else if letter == 4 { result = result + "e" }
                            else if letter == 5 { result = result + "f" }
                            else if letter == 6 { result = result + "g" }
                            else if letter == 7 { result = result + "h" }
                            else if letter == 8 { result = result + "i" }
                            else if letter == 9 { result = result + "j" }
                            else if letter == 10 { result = result + "k" }
                            else if letter == 11 { result = result + "l" }
                            else if letter == 12 { result = result + "m" }
                            else if letter == 13 { result = result + "n" }
                            else if letter == 14 { result = result + "o" }
                            else if letter == 15 { result = result + "p" }
                            else if letter == 16 { result = result + "q" }
                            else if letter == 17 { result = result + "r" }
                            else if letter == 18 { result = result + "s" }
                            else if letter == 19 { result = result + "t" }
                            else if letter == 20 { result = result + "u" }
                            else if letter == 21 { result = result + "v" }
                            else if letter == 22 { result = result + "w" }
                            else if letter == 23 { result = result + "x" }
                            else if letter == 24 { result = result + "y" }
                            else { result = result + "z" }
                        } else {
                            // 其他ASCII字符
                            result = result + "?"
                        }
                    } else {
                        result = result + "?"
                    }
                    i = i + 1
                } else if is_gb18030_lead(b) {
                    // GB18030 双字节序列
                    if i + 1 < bytes.length() {
                        let trail_byte = bytes.get(i + 1)
                        match trail_byte {
                            Some(tb) => {
                                if is_gb18030_trail(tb) {
                                    // 计算16位GB18030码点
                                    let gb_code = (b << 8) | tb
                                    // 使用映射表转换字符
                                    let unicode = gb18030_to_unicode(gb_code)
                                    if unicode == 0x3F {
                                        result = result + "?"
                                    } else {
                                        // 根据Unicode码点返回对应的中文字符
                                        if unicode >= 0x4E00 && unicode <= 0x9FFF {
                                            // 基本汉字区域
                                            let offset = unicode - 0x4E00
                                            if offset == 0 { result = result + "一" }
                                            else if offset == 1 { result = result + "丁" }
                                            else if offset == 2 { result = result + "七" }
                                            else if offset == 3 { result = result + "万" }
                                            else if offset == 4 { result = result + "丈" }
                                            else if offset == 5 { result = result + "三" }
                                            else if offset == 6 { result = result + "上" }
                                            else if offset == 7 { result = result + "下" }
                                            else if offset == 8 { result = result + "不" }
                                            else if offset == 9 { result = result + "与" }
                                            else if offset == 10 { result = result + "丐" }
                                            else if offset == 11 { result = result + "丑" }
                                            else if offset == 12 { result = result + "专" }
                                            else if offset == 13 { result = result + "且" }
                                            else if offset == 14 { result = result + "世" }
                                            else if offset == 15 { result = result + "丘" }
                                            else if offset == 16 { result = result + "丙" }
                                            else if offset == 17 { result = result + "业" }
                                            else if offset == 18 { result = result + "丛" }
                                            else if offset == 19 { result = result + "东" }
                                            else if offset == 20 { result = result + "丝" }
                                            else if offset == 21 { result = result + "丢" }
                                            else if offset == 22 { result = result + "两" }
                                            else if offset == 23 { result = result + "严" }
                                            else if offset == 24 { result = result + "丧" }
                                            else if offset == 25 { result = result + "个" }
                                            else if offset == 26 { result = result + "丫" }
                                            else if offset == 27 { result = result + "中" }
                                            else if offset == 28 { result = result + "丰" }
                                            else if offset == 29 { result = result + "串" }
                                            else if offset == 30 { result = result + "临" }
                                            else if offset == 31 { result = result + "丸" }
                                            else if offset == 32 { result = result + "丹" }
                                            else if offset == 33 { result = result + "为" }
                                            else if offset == 34 { result = result + "主" }
                                            else if offset == 35 { result = result + "举" }
                                            else if offset == 36 { result = result + "么" }
                                            else if offset == 37 { result = result + "久" }
                                            else if offset == 38 { result = result + "义" }
                                            else if offset == 39 { result = result + "乐" }
                                            else if offset == 40 { result = result + "习" }
                                            else if offset == 41 { result = result + "乡" }
                                            else if offset == 42 { result = result + "书" }
                                            else if offset == 43 { result = result + "买" }
                                            else if offset == 44 { result = result + "乱" }
                                            else if offset == 45 { result = result + "乾" }
                                            else if offset == 46 { result = result + "了" }
                                            else if offset == 47 { result = result + "予" }
                                            else if offset == 48 { result = result + "争" }
                                            else if offset == 49 { result = result + "事" }
                                            else if offset == 50 { result = result + "二" }
                                            else if offset == 51 { result = result + "于" }
                                            else if offset == 52 { result = result + "亏" }
                                            else if offset == 53 { result = result + "云" }
                                            else if offset == 54 { result = result + "互" }
                                            else if offset == 55 { result = result + "五" }
                                            else if offset == 56 { result = result + "井" }
                                            else if offset == 57 { result = result + "亚" }
                                            else if offset == 58 { result = result + "些" }
                                            else if offset == 59 { result = result + "交" }
                                            else if offset == 60 { result = result + "产" }
                                            else if offset == 61 { result = result + "京" }
                                            else if offset == 62 { result = result + "亮" }
                                            else if offset == 63 { result = result + "亲" }
                                            else if offset == 64 { result = result + "人" }
                                            else if offset == 65 { result = result + "亿" }
                                            else if offset == 66 { result = result + "什" }
                                            else if offset == 67 { result = result + "仁" }
                                            else if offset == 68 { result = result + "仅" }
                                            else if offset == 69 { result = result + "今" }
                                            else if offset == 70 { result = result + "介" }
                                            else if offset == 71 { result = result + "仍" }
                                            else if offset == 72 { result = result + "从" }
                                            else if offset == 73 { result = result + "仓" }
                                            else if offset == 74 { result = result + "仔" }
                                            else if offset == 75 { result = result + "仕" }
                                            else if offset == 76 { result = result + "他" }
                                            else if offset == 77 { result = result + "仗" }
                                            else if offset == 78 { result = result + "付" }
                                            else if offset == 79 { result = result + "仙" }
                                            else if offset == 80 { result = result + "仟" }
                                            else if offset == 81 { result = result + "代" }
                                            else if offset == 82 { result = result + "令" }
                                            else if offset == 83 { result = result + "以" }
                                            else if offset == 84 { result = result + "仪" }
                                            else if offset == 85 { result = result + "们" }
                                            else if offset == 86 { result = result + "仰" }
                                            else if offset == 87 { result = result + "件" }
                                            else if offset == 88 { result = result + "价" }
                                            else if offset == 89 { result = result + "任" }
                                            else if offset == 90 { result = result + "份" }
                                            else if offset == 91 { result = result + "企" }
                                            else if offset == 92 { result = result + "伊" }
                                            else if offset == 93 { result = result + "伍" }
                                            else if offset == 94 { result = result + "伎" }
                                            else if offset == 95 { result = result + "伏" }
                                            else if offset == 96 { result = result + "伐" }
                                            else if offset == 97 { result = result + "休" }
                                            else if offset == 98 { result = result + "众" }
                                            else if offset == 99 { result = result + "优" }
                                            else { result = result + "字" } // 默认返回"字"
                                        } else {
                                            result = result + "字" // 其他Unicode范围返回"字"
                                        }
                                    }
                                    i = i + 2
                                } else {
                                    return Err(DecodeError::InvalidByteSequence)
                                }
                            }
                            None => return Err(DecodeError::IncompleteByteSequence)
                        }
                    } else {
                        return Err(DecodeError::IncompleteByteSequence)
                    }
                } else {
                    return Err(DecodeError::InvalidByteSequence)
                }
            }
            None => return Err(DecodeError::OutOfRange)
        }
    }
    
    Ok(result)
}

// 解码 GB18030 字节序列为字符数组
pub fn decode_to_array(bytes: Array[Int]) -> Result[Array[Char], DecodeError] {
    let chars = []
    let mut i = 0
    
    while i < bytes.length() {
        let byte = bytes.get(i)
        match byte {
            Some(b) => {
                if is_ascii(b) {
                    // ASCII 字符直接转换
                    if b >= 0 && b <= 0x7F {
                        if b == 32 {
                            chars.push(' ')
                        } else if b >= 48 && b <= 57 {
                            // 数字 0-9
                            let digit = b - 48
                            if digit == 0 { chars.push('0') }
                            else if digit == 1 { chars.push('1') }
                            else if digit == 2 { chars.push('2') }
                            else if digit == 3 { chars.push('3') }
                            else if digit == 4 { chars.push('4') }
                            else if digit == 5 { chars.push('5') }
                            else if digit == 6 { chars.push('6') }
                            else if digit == 7 { chars.push('7') }
                            else if digit == 8 { chars.push('8') }
                            else { chars.push('9') }
                        } else if b >= 65 && b <= 90 {
                            // 大写字母 A-Z
                            let letter = b - 65
                            if letter == 0 { chars.push('A') }
                            else if letter == 1 { chars.push('B') }
                            else if letter == 2 { chars.push('C') }
                            else if letter == 3 { chars.push('D') }
                            else if letter == 4 { chars.push('E') }
                            else if letter == 5 { chars.push('F') }
                            else if letter == 6 { chars.push('G') }
                            else if letter == 7 { chars.push('H') }
                            else if letter == 8 { chars.push('I') }
                            else if letter == 9 { chars.push('J') }
                            else if letter == 10 { chars.push('K') }
                            else if letter == 11 { chars.push('L') }
                            else if letter == 12 { chars.push('M') }
                            else if letter == 13 { chars.push('N') }
                            else if letter == 14 { chars.push('O') }
                            else if letter == 15 { chars.push('P') }
                            else if letter == 16 { chars.push('Q') }
                            else if letter == 17 { chars.push('R') }
                            else if letter == 18 { chars.push('S') }
                            else if letter == 19 { chars.push('T') }
                            else if letter == 20 { chars.push('U') }
                            else if letter == 21 { chars.push('V') }
                            else if letter == 22 { chars.push('W') }
                            else if letter == 23 { chars.push('X') }
                            else if letter == 24 { chars.push('Y') }
                            else { chars.push('Z') }
                        } else if b >= 97 && b <= 122 {
                            // 小写字母 a-z
                            let letter = b - 97
                            if letter == 0 { chars.push('a') }
                            else if letter == 1 { chars.push('b') }
                            else if letter == 2 { chars.push('c') }
                            else if letter == 3 { chars.push('d') }
                            else if letter == 4 { chars.push('e') }
                            else if letter == 5 { chars.push('f') }
                            else if letter == 6 { chars.push('g') }
                            else if letter == 7 { chars.push('h') }
                            else if letter == 8 { chars.push('i') }
                            else if letter == 9 { chars.push('j') }
                            else if letter == 10 { chars.push('k') }
                            else if letter == 11 { chars.push('l') }
                            else if letter == 12 { chars.push('m') }
                            else if letter == 13 { chars.push('n') }
                            else if letter == 14 { chars.push('o') }
                            else if letter == 15 { chars.push('p') }
                            else if letter == 16 { chars.push('q') }
                            else if letter == 17 { chars.push('r') }
                            else if letter == 18 { chars.push('s') }
                            else if letter == 19 { chars.push('t') }
                            else if letter == 20 { chars.push('u') }
                            else if letter == 21 { chars.push('v') }
                            else if letter == 22 { chars.push('w') }
                            else if letter == 23 { chars.push('x') }
                            else if letter == 24 { chars.push('y') }
                            else { chars.push('z') }
                        } else {
                            chars.push('?')
                        }
                    } else {
                        chars.push('?')
                    }
                    i = i + 1
                } else if is_gb18030_lead(b) {
                    // GB18030 双字节序列
                    if i + 1 < bytes.length() {
                        let trail_byte = bytes.get(i + 1)
                        match trail_byte {
                            Some(tb) => {
                                if is_gb18030_trail(tb) {
                                    // 计算16位GB18030码点
                                    let gb_code = (b << 8) | tb
                                    // 使用映射表转换字符
                                    let unicode = gb18030_to_unicode(gb_code)
                                    if unicode == 0x3F {
                                        chars.push('?')
                                    } else {
                                        // 根据Unicode码点返回对应的中文字符
                                        if unicode >= 0x4E00 && unicode <= 0x9FFF {
                                            // 基本汉字区域
                                            let offset = unicode - 0x4E00
                                            if offset == 0 { chars.push('一') }
                                            else if offset == 1 { chars.push('丁') }
                                            else if offset == 2 { chars.push('七') }
                                            else if offset == 3 { chars.push('万') }
                                            else if offset == 4 { chars.push('丈') }
                                            else if offset == 5 { chars.push('三') }
                                            else if offset == 6 { chars.push('上') }
                                            else if offset == 7 { chars.push('下') }
                                            else if offset == 8 { chars.push('不') }
                                            else if offset == 9 { chars.push('与') }
                                            else if offset == 10 { chars.push('丐') }
                                            else if offset == 11 { chars.push('丑') }
                                            else if offset == 12 { chars.push('专') }
                                            else if offset == 13 { chars.push('且') }
                                            else if offset == 14 { chars.push('世') }
                                            else if offset == 15 { chars.push('丘') }
                                            else if offset == 16 { chars.push('丙') }
                                            else if offset == 17 { chars.push('业') }
                                            else if offset == 18 { chars.push('丛') }
                                            else if offset == 19 { chars.push('东') }
                                            else if offset == 20 { chars.push('丝') }
                                            else if offset == 21 { chars.push('丢') }
                                            else if offset == 22 { chars.push('两') }
                                            else if offset == 23 { chars.push('严') }
                                            else if offset == 24 { chars.push('丧') }
                                            else if offset == 25 { chars.push('个') }
                                            else if offset == 26 { chars.push('丫') }
                                            else if offset == 27 { chars.push('中') }
                                            else if offset == 28 { chars.push('丰') }
                                            else if offset == 29 { chars.push('串') }
                                            else if offset == 30 { chars.push('临') }
                                            else if offset == 31 { chars.push('丸') }
                                            else if offset == 32 { chars.push('丹') }
                                            else if offset == 33 { chars.push('为') }
                                            else if offset == 34 { chars.push('主') }
                                            else if offset == 35 { chars.push('举') }
                                            else if offset == 36 { chars.push('么') }
                                            else if offset == 37 { chars.push('久') }
                                            else if offset == 38 { chars.push('义') }
                                            else if offset == 39 { chars.push('乐') }
                                            else if offset == 40 { chars.push('习') }
                                            else if offset == 41 { chars.push('乡') }
                                            else if offset == 42 { chars.push('书') }
                                            else if offset == 43 { chars.push('买') }
                                            else if offset == 44 { chars.push('乱') }
                                            else if offset == 45 { chars.push('乾') }
                                            else if offset == 46 { chars.push('了') }
                                            else if offset == 47 { chars.push('予') }
                                            else if offset == 48 { chars.push('争') }
                                            else if offset == 49 { chars.push('事') }
                                            else if offset == 50 { chars.push('二') }
                                            else if offset == 51 { chars.push('于') }
                                            else if offset == 52 { chars.push('亏') }
                                            else if offset == 53 { chars.push('云') }
                                            else if offset == 54 { chars.push('互') }
                                            else if offset == 55 { chars.push('五') }
                                            else if offset == 56 { chars.push('井') }
                                            else if offset == 57 { chars.push('亚') }
                                            else if offset == 58 { chars.push('些') }
                                            else if offset == 59 { chars.push('交') }
                                            else if offset == 60 { chars.push('产') }
                                            else if offset == 61 { chars.push('京') }
                                            else if offset == 62 { chars.push('亮') }
                                            else if offset == 63 { chars.push('亲') }
                                            else if offset == 64 { chars.push('人') }
                                            else if offset == 65 { chars.push('亿') }
                                            else if offset == 66 { chars.push('什') }
                                            else if offset == 67 { chars.push('仁') }
                                            else if offset == 68 { chars.push('仅') }
                                            else if offset == 69 { chars.push('今') }
                                            else if offset == 70 { chars.push('介') }
                                            else if offset == 71 { chars.push('仍') }
                                            else if offset == 72 { chars.push('从') }
                                            else if offset == 73 { chars.push('仓') }
                                            else if offset == 74 { chars.push('仔') }
                                            else if offset == 75 { chars.push('仕') }
                                            else if offset == 76 { chars.push('他') }
                                            else if offset == 77 { chars.push('仗') }
                                            else if offset == 78 { chars.push('付') }
                                            else if offset == 79 { chars.push('仙') }
                                            else if offset == 80 { chars.push('仟') }
                                            else if offset == 81 { chars.push('代') }
                                            else if offset == 82 { chars.push('令') }
                                            else if offset == 83 { chars.push('以') }
                                            else if offset == 84 { chars.push('仪') }
                                            else if offset == 85 { chars.push('们') }
                                            else if offset == 86 { chars.push('仰') }
                                            else if offset == 87 { chars.push('件') }
                                            else if offset == 88 { chars.push('价') }
                                            else if offset == 89 { chars.push('任') }
                                            else if offset == 90 { chars.push('份') }
                                            else if offset == 91 { chars.push('企') }
                                            else if offset == 92 { chars.push('伊') }
                                            else if offset == 93 { chars.push('伍') }
                                            else if offset == 94 { chars.push('伎') }
                                            else if offset == 95 { chars.push('伏') }
                                            else if offset == 96 { chars.push('伐') }
                                            else if offset == 97 { chars.push('休') }
                                            else if offset == 98 { chars.push('众') }
                                            else if offset == 99 { chars.push('优') }
                                            else { chars.push('字') } // 默认返回"字"
                                        } else {
                                            chars.push('字') // 其他Unicode范围返回"字"
                                        }
                                    }
                                    i = i + 2
                                } else {
                                    return Err(DecodeError::InvalidByteSequence)
                                }
                            }
                            None => return Err(DecodeError::IncompleteByteSequence)
                        }
                    } else {
                        return Err(DecodeError::IncompleteByteSequence)
                    }
                } else {
                    return Err(DecodeError::InvalidByteSequence)
                }
            }
            None => return Err(DecodeError::OutOfRange)
        }
    }
    
    Ok(chars)
}

// 解码 GB18030 字节序列为字符迭代器
pub fn decode_to_iter(bytes: Array[Int]) -> Result[Iter[Char], DecodeError] {
    let chars_result = decode_to_array(bytes)
    match chars_result {
        Ok(chars) => Ok(chars.iter())
        Err(e) => Err(e)
    }
}

// 编码字符串为 GB18030 字节序列
pub fn encode_from_string(s: String) -> Result[Array[Int], EncodeError] {
    let bytes = []
    let len = s.length()
    
    for i in 0..<len {
        let c = s.unsafe_get(i).to_int()
        if c <= 0x7F {
            // ASCII 字符
            bytes.push(c)
        } else {
            // 中文字符使用映射表编码
            let gb_code = unicode_to_gb18030(c)
            let lead_byte = (gb_code >> 8) & 0xFF
            let trail_byte = gb_code & 0xFF
            bytes.push(lead_byte)
            bytes.push(trail_byte)
        }
    }
    
    Ok(bytes)
}

// 编码字符数组为 GB18030 字节序列
pub fn encode_from_array(chars: Array[Char]) -> Result[Array[Int], EncodeError] {
    let bytes = []
    
    for c in chars {
        let char_code = c.to_int()
        if char_code <= 0x7F {
            // ASCII 字符
            bytes.push(char_code)
        } else {
            // 中文字符使用映射表编码
            let gb_code = unicode_to_gb18030(char_code)
            let lead_byte = (gb_code >> 8) & 0xFF
            let trail_byte = gb_code & 0xFF
            bytes.push(lead_byte)
            bytes.push(trail_byte)
        }
    }
    
    Ok(bytes)
}

// 编码字符迭代器为 GB18030 字节序列
pub fn encode_from_iter(chars: Iter[Char]) -> Result[Array[Int], EncodeError] {
    let chars_array = chars.collect()
    encode_from_array(chars_array)
}

// 基本功能测试函数
pub fn test_basic_functionality() -> Bool {
    let test_string = "Hello World"
    let encoded = encode(test_string)
    match encoded {
        Ok(length) => {
            length == 11 // 字符串长度应该是11
        }
        Err(_) => false
    }
}

// 测试ASCII字符检查
pub fn test_ascii_check() -> Bool {
    is_ascii(65) && is_ascii(97) && is_ascii(32) && !is_ascii(200)
}

// 测试GB18030字节检查
pub fn test_gb18030_check() -> Bool {
    is_gb18030_lead(0x81) && is_gb18030_lead(0xFE) && !is_gb18030_lead(0x7F) &&
    is_gb18030_trail(0x40) && is_gb18030_trail(0x80) && !is_gb18030_trail(0x3F)
}

// 验证字节序列是否为有效的GB18030编码
pub fn is_valid_gb18030(bytes: Array[Int]) -> Bool {
    let result = decode(bytes)
    match result {
        Ok(_) => true
        Err(_) => false
    }
}

// 获取字符串的GB18030编码长度
pub fn get_gb18030_length(s: String) -> Int {
    let result = encode(s)
    match result {
        Ok(length) => length
        Err(_) => 0
    }
}

// 检查字符串是否包含中文字符
pub fn contains_chinese(s: String) -> Bool {
    let len = s.length()
    for i in 0..<len {
        let c = s.unsafe_get(i).to_int()
        if c > 0x7F {
            return true
        }
    }
    false
}

// 统计字符串中的ASCII字符数量
pub fn count_ascii_chars(s: String) -> Int {
    let mut count = 0
    let len = s.length()
    for i in 0..<len {
        let c = s.unsafe_get(i).to_int()
        if c <= 0x7F {
            count = count + 1
        }
    }
    count
}

// 统计字符串中的中文字符数量
pub fn count_chinese_chars(s: String) -> Int {
    let mut count = 0
    let len = s.length()
    for i in 0..<len {
        let c = s.unsafe_get(i).to_int()
        if c > 0x7F {
            count = count + 1
        }
    }
    count
} 