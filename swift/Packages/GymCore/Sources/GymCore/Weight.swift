import Foundation

/// Weights are always stored in pounds; this only changes input and display.
public enum WeightUnit: String, CaseIterable, Sendable, Codable {
  case lb
  case kg

  public static let kgPerLb = 0.45359237

  public var symbol: String { rawValue }

  public func fromLb(_ lb: Double) -> Double {
    self == .lb ? lb : lb * Self.kgPerLb
  }

  public func toLb(_ value: Double) -> Double {
    self == .lb ? value : value / Self.kgPerLb
  }

  /// `135`, `61.2`: no trailing `.0`, at most one decimal. Always a dot.
  public func format(_ lb: Double) -> String {
    Self.formatNumber(fromLb(lb))
  }

  public static func formatNumber(_ value: Double) -> String {
    let tenths = (value * 10).rounded()
    if tenths.truncatingRemainder(dividingBy: 10) == 0 {
      return String(Int(tenths / 10))
    }
    return String(format: "%.1f", locale: Locale(identifier: "en_US_POSIX"), tenths / 10)
  }
}

/// What the number in a set means.
public enum LoadType: String, CaseIterable, Sendable, Codable {
  /// Pounds (shown in lb or kg). Counts toward weekly volume.
  case weight
  /// Plates on a cable/machine stack. Never converted, left out of lb volume.
  case discs

  public static func defaultFor(_ equipment: Equipment) -> LoadType {
    switch equipment {
    case .cable, .machine: .discs
    default: .weight
    }
  }
}

public enum Equipment: String, CaseIterable, Sendable, Codable {
  case barbell
  case dumbbell
  case machine
  case cable
  case smithMachine
  case kettlebell
  case band
  case bodyweight
  case other
}

public enum MuscleGroup: String, CaseIterable, Sendable, Codable {
  case chest, shoulders, triceps, biceps, forearms
  case upperBack, lats, traps, lowerBack
  case abs, obliques
  case glutes, quads, hamstrings, adductors, calves
}
