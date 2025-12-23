// GB18030 编码和解码模块
// 基于 MoonBit core 库实现完整的 GB18030 编解码功能

///|
/// 解码函数 - 返回解码后的字符数量
pub fn decode(bytes : Array[Int]) -> Int raise {
  let mut char_count = 0
  let mut i = 0
  while i < bytes.length() {
    let byte = bytes.get(i)
    match byte {
      Some(b) =>
        if is_ascii(b) {
          char_count = char_count + 1
          i = i + 1
        } else if is_gb18030_lead(b) {
          if i + 1 < bytes.length() {
            let b2 = bytes[i + 1]
            // Check for 4-byte sequence: b2 is 0x30-0x39
            if b2 >= 0x30 && b2 <= 0x39 {
              if i + 3 < bytes.length() {
                let b3 = bytes[i + 2]
                let b4 = bytes[i + 3]
                if b3 >= 0x81 && b3 <= 0xFE && b4 >= 0x30 && b4 <= 0x39 {
                  char_count = char_count + 1
                  i = i + 4
                } else {
                  raise InvalidByteSequence(
                    "Invalid byte sequence in GB18030 4-byte decoding",
                  )
                }
              } else {
                raise IncompleteByteSequence(
                  "Incomplete GB18030 4-byte sequence",
                )
              }
            } else if is_gb18030_trail(b2) {
              char_count = char_count + 1
              i = i + 2
            } else {
              raise InvalidByteSequence(
                "Invalid trail byte in GB18030 sequence",
              )
            }
          } else {
            raise IncompleteByteSequence("Incomplete GB18030 byte sequence")
          }
        } else {
          raise InvalidByteSequence("Invalid byte sequence in GB18030 decoding")
        }
      None => raise OutOfRange("Byte index out of range in GB18030 decoding")
    }
  }
  char_count
}

///|
/// 编码函数 - 返回编码后的字节数量
pub fn encode(s : String) -> Int {
  let mut byte_count = 0
  for c in s {
    let char_code = c.to_int()
    if char_code <= 0x7F {
      byte_count = byte_count + 1
    } else {
      let gb_code = unicode_to_gb18030(char_code)
      if gb_code > 0xFFFF || gb_code < 0 {
        byte_count = byte_count + 4
      } else {
        byte_count = byte_count + 2
      }
    }
  }
  byte_count
}

///|
/// 解码 GB18030 字节序列为字符串
pub fn decode_to_string(bytes : Array[Int]) -> String raise {
  let mut result = ""
  let mut i = 0
  while i < bytes.length() {
    let byte = bytes.get(i)
    match byte {
      Some(b) =>
        if is_ascii(b) {
          // ASCII 字符直接转换
          if b >= 0 && b <= 0x7F {
            result = result + b.unsafe_to_char().to_string()
          } else {
            result = result + "?"
          }
          i = i + 1
        } else if is_gb18030_lead(b) {
          if i + 1 < bytes.length() {
            let b2 = bytes[i + 1]
            // Check for 4-byte sequence: b2 is 0x30-0x39
            if b2 >= 0x30 && b2 <= 0x39 {
              if i + 3 < bytes.length() {
                let b3 = bytes[i + 2]
                let b4 = bytes[i + 3]
                if b3 >= 0x81 && b3 <= 0xFE && b4 >= 0x30 && b4 <= 0x39 {
                  let gb_code = (b << 24) | (b2 << 16) | (b3 << 8) | b4
                  let unicode = gb18030_to_unicode(gb_code)
                  result = result + unicode.unsafe_to_char().to_string()
                  i = i + 4
                } else {
                  raise InvalidByteSequence(
                    "Invalid byte sequence in GB18030 4-byte decoding",
                  )
                }
              } else {
                raise IncompleteByteSequence(
                  "Incomplete GB18030 4-byte sequence",
                )
              }
            } else if is_gb18030_trail(b2) {
              let gb_code = (b << 8) | b2
              let unicode = gb18030_to_unicode(gb_code)
              result = result + unicode.unsafe_to_char().to_string()
              i = i + 2
            } else {
              raise InvalidByteSequence(
                "Invalid trail byte in GB18030 sequence",
              )
            }
          } else {
            raise IncompleteByteSequence("Incomplete GB18030 byte sequence")
          }
        } else {
          raise InvalidByteSequence("Invalid byte sequence in GB18030 decoding")
        }
      None => raise OutOfRange("Byte index out of range in GB18030 decoding")
    }
  }
  result
}

///|
/// 解码 GB18030 字节序列为字符数组
pub fn decode_to_array(bytes : Array[Int]) -> Array[Char] raise {
  let chars = []
  let mut i = 0
  while i < bytes.length() {
    let byte = bytes.get(i)
    match byte {
      Some(b) =>
        if is_ascii(b) {
          // ASCII 字符直接转换
          if b >= 0 && b <= 0x7F {
            chars.push(b.unsafe_to_char())
          } else {
            chars.push('?')
          }
          i = i + 1
        } else if is_gb18030_lead(b) {
          if i + 1 < bytes.length() {
            let b2 = bytes[i + 1]
            // Check for 4-byte sequence: b2 is 0x30-0x39
            if b2 >= 0x30 && b2 <= 0x39 {
              if i + 3 < bytes.length() {
                let b3 = bytes[i + 2]
                let b4 = bytes[i + 3]
                if b3 >= 0x81 && b3 <= 0xFE && b4 >= 0x30 && b4 <= 0x39 {
                  let gb_code = (b << 24) | (b2 << 16) | (b3 << 8) | b4
                  let unicode = gb18030_to_unicode(gb_code)
                  chars.push(unicode.unsafe_to_char())
                  i = i + 4
                } else {
                  raise InvalidByteSequence(
                    "Invalid byte sequence in GB18030 4-byte decoding",
                  )
                }
              } else {
                raise IncompleteByteSequence(
                  "Incomplete GB18030 4-byte sequence",
                )
              }
            } else if is_gb18030_trail(b2) {
              let gb_code = (b << 8) | b2
              let unicode = gb18030_to_unicode(gb_code)
              chars.push(unicode.unsafe_to_char())
              i = i + 2
            } else {
              raise InvalidByteSequence(
                "Invalid trail byte in GB18030 sequence",
              )
            }
          } else {
            raise IncompleteByteSequence("Incomplete GB18030 byte sequence")
          }
        } else {
          raise InvalidByteSequence("Invalid byte sequence in GB18030 decoding")
        }
      None => raise OutOfRange("Byte index out of range in GB18030 decoding")
    }
  }
  chars
}

///|
/// 解码 GB18030 字节序列为字符迭代器
pub fn decode_to_iter(bytes : Array[Int]) -> Iter[Char] raise {
  let chars = decode_to_array(bytes)
  chars.iter()
}

///|
/// 编码字符串为 GB18030 字节序列
pub fn encode_from_string(s : String) -> Array[Int] {
  encode_from_iter(s.iter())
}

///|
/// 编码字符数组为 GB18030 字节序列
pub fn encode_from_array(chars : Array[Char]) -> Array[Int] {
  let bytes = []
  for c in chars {
    let char_code = c.to_int()
    if char_code <= 0x7F {
      // ASCII 字符
      bytes.push(char_code)
    } else {
      // 中文字符使用映射表编码
      let gb_code = unicode_to_gb18030(char_code)
      if gb_code > 0xFFFF || gb_code < 0 {
        // 4-byte sequence
        bytes.push((gb_code >> 24) & 0xFF)
        bytes.push((gb_code >> 16) & 0xFF)
        bytes.push((gb_code >> 8) & 0xFF)
        bytes.push(gb_code & 0xFF)
      } else {
        // 2-byte sequence
        let lead_byte = (gb_code >> 8) & 0xFF
        let trail_byte = gb_code & 0xFF
        bytes.push(lead_byte)
        bytes.push(trail_byte)
      }
    }
  }
  bytes
}

///|
/// 编码字符迭代器为 GB18030 字节序列
pub fn encode_from_iter(chars : Iter[Char]) -> Array[Int] {
  let chars_array = chars.collect()
  encode_from_array(chars_array)
}
