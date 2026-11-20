import Foundation
import GymCore

func muscleLabel(_ muscle: MuscleGroup) -> String {
  switch muscle {
  case .chest: L("muscleChest")
  case .shoulders: L("muscleShoulders")
  case .triceps: L("muscleTriceps")
  case .biceps: L("muscleBiceps")
  case .forearms: L("muscleForearms")
  case .upperBack: L("muscleUpperBack")
  case .lats: L("muscleLats")
  case .traps: L("muscleTraps")
  case .lowerBack: L("muscleLowerBack")
  case .abs: L("muscleAbs")
  case .obliques: L("muscleObliques")
  case .glutes: L("muscleGlutes")
  case .quads: L("muscleQuads")
  case .hamstrings: L("muscleHamstrings")
  case .adductors: L("muscleAdductors")
  case .calves: L("muscleCalves")
  }
}

func equipmentLabel(_ equipment: Equipment) -> String {
  switch equipment {
  case .barbell: L("equipmentBarbell")
  case .dumbbell: L("equipmentDumbbell")
  case .machine: L("equipmentMachine")
  case .cable: L("equipmentCable")
  case .smithMachine: L("equipmentSmithMachine")
  case .kettlebell: L("equipmentKettlebell")
  case .band: L("equipmentBand")
  case .bodyweight: L("equipmentBodyweight")
  case .other: L("equipmentOther")
  }
}

func weekdayName(_ weekday: Int) -> String {
  styledDate(weekday: weekday, format: "EEEE")
}

func weekdayShort(_ weekday: Int) -> String {
  styledDate(weekday: weekday, format: "EEE")
}

private func styledDate(weekday: Int, format: String) -> String {
  var calendar = Calendar(identifier: .gregorian)
  calendar.timeZone = .current
  let day = calendar.date(from: DateComponents(year: 2024, month: 1, day: weekday)) ?? .now
  let formatter = DateFormatter()
  formatter.locale = L10n.locale
  formatter.dateFormat = format
  let text = formatter.string(from: day)
  guard let first = text.first else { return text }
  return first.uppercased() + text.dropFirst()
}

func formatDay(_ date: Date) -> String {
  let formatter = DateFormatter()
  formatter.locale = L10n.locale
  formatter.setLocalizedDateFormatFromTemplate("EEEMMMd")
  return formatter.string(from: date)
}

func formatShortDate(_ date: Date) -> String {
  let formatter = DateFormatter()
  formatter.locale = L10n.locale
  formatter.setLocalizedDateFormatFromTemplate("MMMd")
  return formatter.string(from: date)
}

func formatInt(_ value: Int) -> String {
  let formatter = NumberFormatter()
  formatter.locale = L10n.locale
  formatter.numberStyle = .decimal
  return formatter.string(from: NSNumber(value: value)) ?? "\(value)"
}

func formatCompact(_ value: Double) -> String {
  let formatter = NumberFormatter()
  formatter.locale = L10n.locale
  formatter.numberStyle = .decimal
  formatter.maximumFractionDigits = value >= 1000 ? 1 : 0
  if value >= 1000 {
    formatter.numberStyle = .decimal
    let scaled = value / 1000
    let text = formatter.string(from: NSNumber(value: scaled)) ?? String(format: "%.1f", scaled)
    return "\(text)K"
  }
  return formatter.string(from: NSNumber(value: value)) ?? "\(Int(value.rounded()))"
}

func formatDuration(_ seconds: TimeInterval) -> String {
  let total = Int(seconds)
  let hours = total / 3600
  let minutes = (total % 3600) / 60
  if hours > 0 { return "\(hours)h \(String(format: "%02d", minutes))m" }
  return "\(minutes)m"
}

func deltaCaption(_ current: Double, _ previous: Double) -> String {
  guard previous > 0 else { return L("dashboardNoPreviousWeek") }
  let pct = Int(((current - previous) / previous * 100).rounded())
  let sign = pct > 0 ? "+" : ""
  return L("dashboardVsLastWeek", "\(sign)\(pct)%")
}

struct LoadText {
  var type: LoadType
  var unit: WeightUnit

  var isDiscs: Bool { type == .discs }
  var symbol: String { isDiscs ? L("discsShort") : unit.symbol }

  func format(_ stored: Double) -> String {
    WeightUnit.formatNumber(isDiscs ? stored : unit.fromLb(stored))
  }

  func withSymbol(_ stored: Double) -> String { "\(format(stored)) \(symbol)" }
}
