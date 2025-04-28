import Foundation
import Combine // ObservableObject と @Published のために必要

// パターンデータを管理するクラス (固定プリセット版)
class PresetManager: ObservableObject {

    // @Published: この配列に変更があったらUIに通知するための印 (配列自体は固定だが、SwiftUIから参照するために必要)
    // 固定のプリセットデータを直接ここで定義します
    @Published var presets: [WaterPreset] = [
        WaterPreset(name: "家のｸﾞﾗｽ", amount: 200), // ボタンに表示する名前と量
        WaterPreset(name: "家のﾏｸﾞ", amount: 220),
        WaterPreset(name: "ﾋﾟｶﾁｭｳｺｯﾌﾟ", amount: 180),
        WaterPreset(name: "ｽﾀﾊﾞ Short", amount: 240),    // 教えてもらった量
        WaterPreset(name: "ｽﾀﾊﾞ Tall", amount: 350),     // 教えてもらった量
        WaterPreset(name: "ｽﾀﾊﾞ Grande", amount: 470)
        // もし他にも固定で表示したいパターンがあれば、ここに追加できます
        // 例: WaterPreset(name: "Grande", amount: 470),
    ]

    // init(), loadPresets(), savePresets(), userDefaultsKey, didSet は不要になります
}

// ※ WaterPreset.swift ファイルはそのままで大丈夫です。
