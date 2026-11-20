import Foundation
import GymCore

public enum GymLog {
  public static func debug(_ message: String) {
    #if DEBUG
      print("GymTracker: \(message)")
    #endif
  }

  public static func error(_ message: String, _ error: Error? = nil) {
    if let error {
      print("GymTracker error: \(message): \(error)")
    } else {
      print("GymTracker error: \(message)")
    }
  }
}

/// True when the failure means the server could not be reached.
public func isOfflineError(_ error: Error) -> Bool {
  if let url = error as? URLError, SelfCodes.contains(url.code) { return true }
  let ns = error as NSError
  if ns.domain == NSURLErrorDomain, SelfCodes.contains(URLError.Code(rawValue: ns.code)) { return true }
  if let underlying = ns.userInfo[NSUnderlyingErrorKey] as? Error { return isOfflineError(underlying) }
  let text = String(describing: error).lowercased()
  return text.contains("authretryablefetch") || text.contains("network connection")
}

private let SelfCodes: Set<URLError.Code> = [
  .notConnectedToInternet, .timedOut, .cannotFindHost, .cannotConnectToHost,
  .networkConnectionLost, .dnsLookupFailed, .dataNotAllowed, .internationalRoamingOff,
  .callIsActive, .secureConnectionFailed, .serverCertificateUntrusted, .cannotLoadFromNetwork,
]

public struct Served<T: Sendable>: Sendable {
  public var value: T
  public var fromCache: Bool
  public init(value: T, fromCache: Bool = false) {
    self.value = value
    self.fromCache = fromCache
  }
}

public struct PlanSnapshot: Sendable {
  public var routines: [Routine]
  public var plan: WeeklyPlan
  public init(routines: [Routine], plan: WeeklyPlan) {
    self.routines = routines
    self.plan = plan
  }
}

/// One on-disk cache file.
public struct CacheEntry: Identifiable, Hashable, Sendable {
  public var key: String
  public var bytes: Int
  public var modifiedAt: Date
  public var id: String { key }
}

/// JSON file cache. Same layout as the Flutter app:
/// `<Documents>/gym_tracker/users/<userId>/cache_*.json` plus `images/`.
/// Each file is `{"version": 1, "data": ...}`.
public actor OfflineCache {
  public static let shared = OfflineCache()

  public static let exercises = "cache_exercises"
  public static let routines = "cache_routines"
  public static let weeklyPlan = "cache_weekly_plan"
  public static let workouts = "cache_workouts"
  public static let version = 1

  private let root: URL

  public init(root: URL? = nil) {
    if let root {
      self.root = root
    } else {
      let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
      self.root = docs.appendingPathComponent("gym_tracker", isDirectory: true)
    }
  }

  public func userDirectory(_ userId: String) -> URL {
    root.appendingPathComponent("users", isDirectory: true).appendingPathComponent(userId, isDirectory: true)
  }

  public func imagesDirectory(_ userId: String) -> URL {
    userDirectory(userId).appendingPathComponent("images", isDirectory: true)
  }

  private func file(_ userId: String, _ name: String) -> URL {
    userDirectory(userId).appendingPathComponent("\(name).json")
  }

  public func read<T: Decodable>(_ type: T.Type, user: String, name: String) -> T? {
    let url = file(user, name)
    guard let data = try? Data(contentsOf: url) else { return nil }
    guard let object = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else { return nil }
    let payload = object["data"] ?? object
    guard JSONSerialization.isValidJSONObject(payload), let raw = try? JSONSerialization.data(withJSONObject: payload) else {
      return nil
    }
    return try? GymJSON.decode(T.self, from: raw)
  }

  public func write<T: Encodable>(_ value: T, user: String, name: String) {
    do {
      let dir = userDirectory(user)
      try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
      let payload = try GymJSON.encode(value)
      let object = try JSONSerialization.jsonObject(with: payload)
      let wrapped: [String: Any] = ["version": Self.version, "data": object]
      let data = try JSONSerialization.data(withJSONObject: wrapped, options: [.sortedKeys])
      let url = file(user, name)
      let tmp = url.appendingPathExtension("tmp")
      try data.write(to: tmp, options: .atomic)
      if FileManager.default.fileExists(atPath: url.path) {
        try FileManager.default.removeItem(at: url)
      }
      try FileManager.default.moveItem(at: tmp, to: url)
    } catch {
      GymLog.error("offline cache write failed", error)
    }
  }

  /// Deletes `cache_*` files and downloaded photos. Keeps `*.migrated.json`.
  public func clearCache(user: String) {
    let dir = userDirectory(user)
    guard let urls = try? FileManager.default.contentsOfDirectory(at: dir, includingPropertiesForKeys: nil) else { return }
    for url in urls where url.lastPathComponent.hasPrefix("cache_") {
      try? FileManager.default.removeItem(at: url)
    }
    try? FileManager.default.removeItem(at: imagesDirectory(user))
  }

  public func entries(user: String) -> [CacheEntry] {
    let dir = userDirectory(user)
    let keys: [URLResourceKey] = [.fileSizeKey, .contentModificationDateKey]
    guard
      let urls = try? FileManager.default.contentsOfDirectory(at: dir, includingPropertiesForKeys: keys)
    else { return [] }
    return urls.filter { $0.lastPathComponent.hasPrefix("cache_") && $0.pathExtension == "json" }.compactMap { url in
      let values = try? url.resourceValues(forKeys: Set(keys))
      return CacheEntry(
        key: url.deletingPathExtension().lastPathComponent,
        bytes: values?.fileSize ?? 0,
        modifiedAt: values?.contentModificationDate ?? .distantPast
      )
    }
    .sorted { $0.modifiedAt > $1.modifiedAt }
  }

  public func legacyFileExists(user: String, name: String) -> Bool {
    FileManager.default.fileExists(atPath: file(user, name).path)
  }

  public func readLegacyData(user: String, name: String) -> Data? {
    let url = file(user, name)
    return try? Data(contentsOf: url)
  }

  public func markMigrated(user: String, name: String) {
    let url = file(user, name)
    let dest = userDirectory(user).appendingPathComponent("\(name).migrated.json")
    guard FileManager.default.fileExists(atPath: url.path) else { return }
    try? FileManager.default.removeItem(at: dest)
    try? FileManager.default.moveItem(at: url, to: dest)
  }
}

actor SaveQueue {
  private var tail: Task<Void, Never>?

  func run<T: Sendable>(_ body: @escaping @Sendable () async throws -> T) async throws -> T {
    let previous = tail
    let task = Task { () throws -> T in
      await previous?.value
      return try await body()
    }
    tail = Task { _ = try? await task.value }
    return try await task.value
  }
}
