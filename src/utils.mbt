///|
/// 检查字节是否为ASCII
pub fn is_ascii(b : Int) -> Bool {
  b <= 0x7F
}

///|
/// 检查字节是否为GB18030双字节序列的第一个字节
pub fn is_gb18030_lead(b : Int) -> Bool {
  b >= 0x81 && b <= 0xFE
}

///|
// 检查字节是否为GB18030双字节序列的第二个字节
pub fn is_gb18030_trail(b : Int) -> Bool {
  (b >= 0x40 && b <= 0x7E) || (b >= 0x80 && b <= 0xFE)
}

///|
/// 基本功能测试函数
pub fn test_basic_functionality() -> Bool {
  let test_string = "Hello World"
  let encoded = encode(test_string)
  encoded == 11 // 字符串长度应该是11
}

///|
/// 测试ASCII字符检查
pub fn test_ascii_check() -> Bool {
  is_ascii(65) && is_ascii(97) && is_ascii(32) && !is_ascii(200)
}

///|
/// 测试GB18030字节检查
pub fn test_gb18030_check() -> Bool {
  is_gb18030_lead(0x81) &&
  is_gb18030_lead(0xFE) &&
  !is_gb18030_lead(0x7F) &&
  is_gb18030_trail(0x40) &&
  is_gb18030_trail(0x80) &&
  !is_gb18030_trail(0x3F)
}

///|
/// 验证字节序列是否为有效的GB18030编码
pub fn is_valid_gb18030(bytes : Array[Int]) -> Bool {
  try {
    decode(bytes) |> ignore
    true
  } catch {
    _ => false
  }
}

///|
/// 获取字符串的GB18030编码长度
pub fn get_gb18030_length(s : String) -> Int {
  encode(s)
}

///|
/// 检查字符串是否包含中文字符
pub fn contains_chinese(s : String) -> Bool {
  let len = s.length()
  for i in 0..<len {
    let c = s.unsafe_charcode_at(i)
    if c > 0x7F {
      return true
    }
  }
  false
}

///|
/// 统计字符串中的ASCII字符数量
pub fn count_ascii_chars(s : String) -> Int {
  let mut count = 0
  let len = s.length()
  for i in 0..<len {
    let c = s.unsafe_charcode_at(i)
    if c <= 0x7F {
      count = count + 1
    }
  }
  count
}

///|
/// 统计字符串中的中文字符数量
pub fn count_chinese_chars(s : String) -> Int {
  let mut count = 0
  let len = s.length()
  for i in 0..<len {
    let c = s.unsafe_charcode_at(i)
    if c > 0x7F {
      count = count + 1
    }
  }
  count
}
