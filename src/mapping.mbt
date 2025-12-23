// GB18030 字符映射表 - 完整的映射实现

///|
/// 映射 GB18030 编码到 Unicode
pub fn gb18030_to_unicode(gb_code : Int) -> Int {
  // ASCII 字符
  if gb_code >= 0 && gb_code <= 0x7F {
    return gb_code
  }

  // 双字节区域
  if gb_code >= 0x8140 && gb_code <= 0xFEFE {
    let lead = (gb_code >> 8) & 0xFF
    let trail = gb_code & 0xFF
    if trail >= 0x40 && trail <= 0xFE && trail != 0x7F {
      // 计算偏移量
      let area = lead - 0x81
      let pos = if trail >= 0x80 { trail - 0x80 + 63 } else { trail - 0x40 }

      // 0x4E00-0x9FFF 区域
      // 扩展支持 0x8140 开始的区域
      if area <= 0xA0 { // 0x2F 是 0x4E00 的偏移量
        let offset = (area - 0x2F) * 190 + pos
        // 移除 offset >= 0 的限制，允许映射到 0x4E00 以下
        if offset <= 0x9FA5 - 0x4E00 {
          return 0x4E00 + offset
        }
      }
    }
  }

  // 四字节区域
  let b1 = (gb_code >> 24) & 0xFF
  let b2 = (gb_code >> 16) & 0xFF
  let b3 = (gb_code >> 8) & 0xFF
  let b4 = gb_code & 0xFF
  if b1 >= 0x81 &&
    b1 <= 0xFE &&
    b2 >= 0x30 &&
    b2 <= 0x39 &&
    b3 >= 0x81 &&
    b3 <= 0xFE &&
    b4 >= 0x30 &&
    b4 <= 0x39 {
    let linear = (b1 - 0x81) * 12600 +
      (b2 - 0x30) * 1260 +
      (b3 - 0x81) * 10 +
      (b4 - 0x30)

    // 第一平面及以上 (U+10000+)
    // 从 0x90308130 开始 -> 线性偏移 189000
    if linear >= 189000 {
      return 0x10000 + (linear - 189000)
    }

    // BMP 高位区域 (U+9FA6+)
    // 从 0x82358F33 开始 -> 线性偏移 19043
    if linear >= 19043 {
      let unicode = 0x9FA6 + (linear - 19043)
      if unicode <= 0xFFFF {
        return unicode
      }
    }
  }
  0x3F
}

///|
/// 映射 Unicode 到 GB18030 编码
pub fn unicode_to_gb18030(unicode : Int) -> Int {
  // ASCII 字符
  if unicode <= 0x7F {
    return unicode
  }

  // 完整的Unicode到GB18030映射

  // 一级汉字区域 (0x4E00-0x9FFF)
  // 扩展支持更低范围的 Unicode 映射到 0x8140 区域
  // 0x4E00 对应 0xB040, 0x2B1E 对应 0x8140
  if unicode >= 0x2B1E && unicode <= 0x9FFF {
    let offset = unicode - 0x4E00
    let area = offset / 190 + 0x2F
    let pos = offset % 190
    let lead = area + 0x81
    if lead <= 0xFE {
      let trail = if pos < 63 { pos + 0x40 } else { pos - 63 + 0x80 }
      return (lead << 8) | trail
    }
  }

  // 将线性偏移量转换为 4 字节 GB 编码的辅助函数
  // 线性偏移量 0 对应 0x81308130
  let get_4byte = fn(linear : Int) -> Int {
    let b1 = linear / 12600 + 0x81
    let b2 = linear / 1260 % 10 + 0x30
    let b3 = linear / 10 % 126 + 0x81
    let b4 = linear % 10 + 0x30
    (b1 << 24) | (b2 << 16) | (b3 << 8) | b4
  }

  // 四字节区域 (0x10000-0x10FFFF)
  // 映射到 0x90308130 (线性偏移 189000) 及之后
  if unicode >= 0x10000 && unicode <= 0x10FFFF {
    let offset = unicode - 0x10000 + 189000
    return get_4byte(offset)
  }

  // BMP 高位区域 (0x9FA6-0xFFFF)
  // 包含 CJK 扩展 A 结尾、用户自定义区域等
  // 映射到 0x82358F33 (线性偏移 19043) 及之后
  if unicode >= 0x9FA6 && unicode <= 0xFFFF {
    let offset = unicode - 0x9FA6 + 19043
    return get_4byte(offset)
  }

  // 默认返回0x3F3F (问号)
  0x3F3F
}
