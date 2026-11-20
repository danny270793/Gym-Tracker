import GymCore
import SwiftUI

/// Two linked fields for a weight stored in pounds. Disc exercises use one count field.
struct LoadEditor: View {
  @Binding var pounds: Double
  var discs: Bool
  var unit: WeightUnit

  /// Shared with the column header so the labels line up with the boxes.
  static let discsWidth: CGFloat = 110

  var body: some View {
    if discs {
      HStack {
        Spacer(minLength: 0)
        TextField(L("discsShort"), value: $pounds, format: .number)
          .keyboardType(.decimalPad)
          .multilineTextAlignment(.trailing)
          .fieldBox()
          .frame(width: LoadEditor.discsWidth)
      }
    } else {
      HStack(spacing: 8) {
        unitField(.lb)
        unitField(.kg)
      }
    }
  }

  private func unitField(_ field: WeightUnit) -> some View {
    TextField(field.symbol, text: binding(field))
      .keyboardType(.decimalPad)
      .multilineTextAlignment(.trailing)
      .fieldBox()
  }

  private func binding(_ field: WeightUnit) -> Binding<String> {
    Binding(
      get: {
        pounds <= 0 ? "" : field.format(pounds)
      },
      set: { text in
        let parsed = Double(text.replacingOccurrences(of: ",", with: "."))
        pounds = (parsed == nil || parsed! <= 0) ? 0 : field.toLb(parsed!)
      }
    )
  }
}

extension View {
  /// The grey rounded box used by every editable number in a set row.
  func fieldBox() -> some View {
    padding(.horizontal, 8)
      .padding(.vertical, 6)
      .background(.fill.tertiary, in: .rect(cornerRadius: 8))
  }
}

enum FieldMetrics {
  /// Width of the boxed number fields (sets, reps) so labels and boxes line up.
  static let number: CGFloat = 64
}

/// A boxed whole-number field.
struct IntField: View {
  var placeholder: String
  @Binding var value: Int

  var body: some View {
    TextField(placeholder, value: $value, format: .number)
      .keyboardType(.numberPad)
      .multilineTextAlignment(.trailing)
      .fieldBox()
      .frame(width: FieldMetrics.number)
  }
}

/// Column names above set/plan rows: leading number columns, then lb and kg (or discs).
struct ColumnLabels: View {
  var leading: [String]
  var discs: Bool
  /// Reserve the width of the minus button that ends a workout set row.
  var reservesRemoveButton = false

  var body: some View {
    HStack(spacing: 10) {
      ForEach(leading, id: \.self) { label in
        Text(label).padding(.horizontal, 8).frame(width: FieldMetrics.number, alignment: .trailing)
      }
      if discs {
        Spacer(minLength: 0)
        Text(L("discsShort")).padding(.horizontal, 8).frame(width: LoadEditor.discsWidth, alignment: .trailing)
      } else {
        HStack(spacing: 8) {
          Text(WeightUnit.lb.symbol).padding(.horizontal, 8).frame(maxWidth: .infinity, alignment: .trailing)
          Text(WeightUnit.kg.symbol).padding(.horizontal, 8).frame(maxWidth: .infinity, alignment: .trailing)
        }
      }
      if reservesRemoveButton { Image(systemName: "minus.circle").hidden() }
    }
    .font(.caption.bold())
    .foregroundStyle(.tint)
  }
}
