import Foundation

/// JSON coding shared by Supabase and the offline cache.
/// Dates match Dart's `toUtc().toIso8601String()` (UTC, millisecond precision).
public enum GymJSON {
  public static let decoder: JSONDecoder = {
    let d = JSONDecoder()
    d.dateDecodingStrategy = .custom { decoder in
      let container = try decoder.singleValueContainer()
      let raw = try container.decode(String.self)
      if let date = parseTimestamp(raw) { return date }
      throw DecodingError.dataCorruptedError(in: container, debugDescription: "Unrecognized date: \(raw)")
    }
    return d
  }()

  public static let encoder: JSONEncoder = {
    let e = JSONEncoder()
    e.dateEncodingStrategy = .custom { date, encoder in
      var container = encoder.singleValueContainer()
      try container.encode(formatTimestamp(date))
    }
    return e
  }()

  public static func formatTimestamp(_ date: Date) -> String {
    let formatter = ISO8601DateFormatter()
    formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
    formatter.timeZone = TimeZone(secondsFromGMT: 0)
    let raw = formatter.string(from: date)
    // ISO8601DateFormatter can emit more than 3 fractional digits. Dart uses 3.
    guard let dot = raw.firstIndex(of: ".") else { return raw }
    let after = raw.index(after: dot)
    let zone = raw[after...].firstIndex(where: { !$0.isNumber }) ?? raw.endIndex
    let ms = String(raw[after..<zone].prefix(3)).padding(toLength: 3, withPad: "0", startingAt: 0)
    return String(raw[..<after]) + ms + String(raw[zone...])
  }

  public static func parseTimestamp(_ raw: String) -> Date? {
    if raw.count == 10 {
      let parts = raw.split(separator: "-")
      if parts.count == 3, let y = Int(parts[0]), let m = Int(parts[1]), let d = Int(parts[2]) {
        return date(y, m, d)
      }
    }
    var s = raw.replacingOccurrences(of: " ", with: "T")
    if let dot = s.firstIndex(of: ".") {
      let after = s.index(after: dot)
      let zone = s[after...].firstIndex(where: { !$0.isNumber }) ?? s.endIndex
      let ms = String(s[after..<zone].prefix(3)).padding(toLength: 3, withPad: "0", startingAt: 0)
      s.replaceSubrange(after..<zone, with: ms)
    }
    if !s.hasSuffix("Z"), s.range(of: #"[+-]\d{2}(:?\d{2})?$"#, options: .regularExpression) == nil {
      s += "Z"
    }
    let withFraction = ISO8601DateFormatter()
    withFraction.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
    if let date = withFraction.date(from: s) { return date }
    let plain = ISO8601DateFormatter()
    plain.formatOptions = [.withInternetDateTime]
    return plain.date(from: s)
  }

  public static func encode<T: Encodable>(_ value: T) throws -> Data {
    try encoder.encode(value)
  }

  public static func decode<T: Decodable>(_ type: T.Type, from data: Data) throws -> T {
    try decoder.decode(type, from: data)
  }
}

struct FlexDouble: Decodable {
  let value: Double
  init(from decoder: Decoder) throws {
    let c = try decoder.singleValueContainer()
    if let d = try? c.decode(Double.self) { value = d; return }
    if let i = try? c.decode(Int.self) { value = Double(i); return }
    if let s = try? c.decode(String.self), let d = Double(s) { value = d; return }
    throw DecodingError.dataCorruptedError(in: c, debugDescription: "Not a number")
  }
}

struct FlexInt: Decodable {
  let value: Int
  init(from decoder: Decoder) throws {
    let c = try decoder.singleValueContainer()
    if let i = try? c.decode(Int.self) { value = i; return }
    if let d = try? c.decode(Double.self) { value = Int(d); return }
    if let s = try? c.decode(String.self), let i = Int(s) { value = i; return }
    throw DecodingError.dataCorruptedError(in: c, debugDescription: "Not an int")
  }
}

extension KeyedDecodingContainer {
  func flexInt(_ key: Key, default fallback: Int) -> Int {
    (try? decode(FlexInt.self, forKey: key).value) ?? fallback
  }

  func flexDoubleIfPresent(_ key: Key) -> Double? {
    try? decodeIfPresent(FlexDouble.self, forKey: key)?.value
  }

  func flexDouble(_ key: Key, default fallback: Double) -> Double {
    flexDoubleIfPresent(key) ?? fallback
  }

  func gymDate(_ key: Key) -> Date {
    if let date = try? decodeIfPresent(Date.self, forKey: key) { return date }
    if let raw = try? decodeIfPresent(String.self, forKey: key), let date = GymJSON.parseTimestamp(raw) {
      return date
    }
    return Date(timeIntervalSince1970: 0)
  }

  func gymDateIfPresent(_ key: Key) -> Date? {
    if let date = try? decodeIfPresent(Date.self, forKey: key) { return date }
    if let raw = try? decodeIfPresent(String.self, forKey: key) { return GymJSON.parseTimestamp(raw) }
    return nil
  }
}

extension KeyedEncodingContainer {
  public mutating func encodeNullIfNil(_ value: String?, forKey key: Key) throws {
    if let value { try encode(value, forKey: key) } else { try encodeNil(forKey: key) }
  }

  public mutating func encodeNullIfNil(_ value: Double?, forKey key: Key) throws {
    if let value { try encode(value, forKey: key) } else { try encodeNil(forKey: key) }
  }

  public mutating func encodeNullIfNil(_ value: Date?, forKey key: Key) throws {
    if let value { try encode(value, forKey: key) } else { try encodeNil(forKey: key) }
  }
}
