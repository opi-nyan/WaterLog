import SwiftUI

struct ContentView: View {
    // ヘルスケア関連の処理を担当するクラスのインスタンス
    @StateObject private var healthKitManager = HealthKitManager()
    // パターンデータを管理するクラスのインスタンス
    @StateObject private var presetManager = PresetManager()

    // テキストフィールドの入力文字列を保持する変数
    @State private var waterAmountString: String = ""
    // アラートを表示するかどうかを管理する変数
    @State private var showingAlert = false
    // アラートに表示するメッセージを保持する変数
    @State private var alertMessage = ""

    // 画面に表示する内容を定義
    var body: some View {
        // 要素を縦に並べる
        VStack {
            // アプリのタイトルや説明（任意）
            Text("🌊 Water Log 🌊")
                .font(.title) // 少し大きめの文字
                .padding(.top)

            Text("🥤飲んだ量を入力 (ml)")
                .padding(.top,50)

            // 水分量を入力するテキストフィールド
            TextField("例: 200", text: $waterAmountString)
                .keyboardType(.numberPad) // 数字キーボードを表示
                .padding() // 内側の余白
                .background(Color(uiColor: .secondarySystemBackground)) // 背景色
                .cornerRadius(8) // 角を丸める
                .padding(.horizontal) // 左右の余白

            // 手入力した値を記録するボタン
            Button("📝 ヘルスケアに記録する") {
                // --- 手入力ボタンが押された時の処理 ---
                recordManually() // 下で定義する別メソッドを呼ぶ
            }
            .buttonStyle(.borderedProminent) // 目立つボタンスタイル
            .padding(.horizontal) // 左右の余白
            .padding(.top, 20) // ボタンの上に少し余白

            // パターン選択エリアの見出し
            Text("🌟よく飲むやーつ🌟")
                .font(.headline) // 見出しスタイル
                .padding(.top, 50) // 上に少し多めの余白

            // ... (Text("またはパターンを選択:") の下から) ...

                        // --- ↓↓↓ パターンボタン表示エリアを LazyVGrid に変更 ↓↓↓ ---

                        // 2列表示のための定義 (各列の設定)
                        // .flexible() は利用可能な幅を均等に分け合う設定
                        // spacing は列と列の間のスペース
                        let columns: [GridItem] = [
                            GridItem(.flexible(), spacing: 16),
                            GridItem(.flexible(), spacing: 16)
                        ]

                        // LazyVGrid を使ってボタンをグリッド表示
                        // columns に上で定義した列設定を渡す
                        // spacing は行と行の間のスペース
                        LazyVGrid(columns: columns, spacing: 16) {
                            // 保存されているパターンをループ処理 (ここは変更なし)
                            ForEach(presetManager.presets) { preset in
                                // 各パターンに対応するボタン
                                Button {
                                    recordPreset(preset) // アクションは変更なし
                                } label: {
                                    // ボタンの見た目
                                    VStack {
                                        Text(preset.name)
                                            .font(.caption)
                                        Text("\(Int(preset.amount))ml")
                                    }
                                    // ★★★ ボタンの幅を、利用可能な最大幅まで広げる ★★★
                                    // これにより、2列で各ボタンの幅が揃って見える
                                    .frame(maxWidth: .infinity)
                                    .padding(EdgeInsets(top: 12, leading: 8, bottom: 12, trailing: 8)) // 内側の余白を調整
                                }
                                .buttonStyle(.bordered) // スタイルは変更なし
                            }
                        }
                        .padding(.horizontal) // グリッド全体の左右に余白
                        // --- ↑↑↑ パターンボタン表示エリアの変更ここまで ↑↑↑ ---

                        Spacer() // 画面下部との間のスペース (これは元々あるはず)
                    // } // ← VStackの閉じカッコ
                    // .alert(...) // ← アラートの設定はそのまま

            // 画面下部に余白を作るためのスペーサー
            Spacer()
        }
        // アラート表示の設定
        .alert(alertMessage, isPresented: $showingAlert) {
            Button("OK") {
                // OKボタンが押されたらアラートを閉じるだけ
                showingAlert = false
            }
        }
    } // --- body の終わり ---

    // MARK: - Helper Functions (処理をまとめた関数)

    // 手入力で記録する処理
    private func recordManually() {
        // 1. 入力文字列を数値(Double)に変換
        guard let amount = Double(waterAmountString) else {
            self.alertMessage = "有効な数値を入力してください。"
            self.showingAlert = true
            return // 処理中断
        }

        // 2. 非同期で保存処理を実行
        Task {
            await saveWater(amount: amount, sourceName: "手入力")
        }
    }

    // パターンで記録する処理
    private func recordPreset(_ preset: WaterPreset) {
        print("パターン「\(preset.name)」(\(preset.amount)ml)が選択されました。")
        // 非同期で保存処理を実行
        Task {
            await saveWater(amount: preset.amount, sourceName: preset.name)
        }
    }

    // ヘルスケアに保存する共通処理
    private func saveWater(amount: Double, sourceName: String) async {
        do {
            // 3. 権限リクエスト（必要なら）
            _ = try await healthKitManager.requestAuthorization()

            // 4. データ保存
            try await healthKitManager.saveWaterIntake(amount: amount)

            // 5. 成功アラート
            print("保存成功！")
            let amountInt = Int(amount) // アラート用に整数に
            // 記録元（手入力かパターン名か）を表示するようにメッセージ変更
            self.alertMessage = "\(sourceName) から \(amountInt)ml を記録しました！"
            self.showingAlert = true
            if sourceName == "手入力" { // 手入力の場合のみ入力欄をクリア
                 self.waterAmountString = ""
            }

        } catch let error as HealthKitError { // ハンドルするエラーを限定
            print("HealthKitエラー: \(error.localizedDescription)")
            self.alertMessage = "エラー: \(error.localizedDescription)"
            self.showingAlert = true
        } catch { // その他の予期せぬエラー
            print("予期せぬエラー: \(error.localizedDescription)")
            self.alertMessage = "予期せぬエラーが発生しました。"
            self.showingAlert = true
        }
    }

} // --- struct ContentView の終わり ---


// プレビュー用のコード（変更なし）
#Preview {
    ContentView()
}
