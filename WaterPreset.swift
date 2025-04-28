import Foundation // UUIDやCodableのために必要

// 水分摂取パターンを表す構造体（設計図）
struct WaterPreset: Identifiable, Codable {
    let id = UUID()      // 一つ一つのパターンを区別するためのユニークなID
    var name: String     // パターンの名前 (例: "コップ")
    var amount: Double   // パターンの量 (例: 200.0 ml)
}
