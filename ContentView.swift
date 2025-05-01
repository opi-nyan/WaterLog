import SwiftUI

struct ContentView: View {
    @StateObject private var healthKitManager = HealthKitManager()
    @State private var waterAmountString: String = ""
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var todaysTotal: Double = 0.0
    @State private var todaysSteps: Double = 0.0
    @Environment(\.scenePhase) private var scenePhase // ← これを追加！
    

    var body: some View {
        // 画面全体をナビゲーションビューで囲む（タイトル表示のため）
        NavigationView {
            // リスト形式で表示（ヘルスケアアプリ風）
            List {
                // --- 「今日の記録」セクション ---
                Section("今日の記録") {
                    HStack { // 水平に要素を並べる
                        Label("合計水分量", systemImage: "drop.fill") // アイコンとテキスト
                            .foregroundColor(.blue) // 水分なので青色に
                        Spacer() // 右側に寄せるためのスペーサー
                        Text("\(Int(todaysTotal)) ml")
                            .font(.title2.weight(.semibold)) // 少し太字に
                    }

                    HStack {
                        Label("合計歩数", systemImage: "figure.walk") // 歩数アイコン
                            .foregroundColor(.orange) // 歩数はオレンジ色に
                        Spacer()
                        Text("\(Int(todaysSteps)) 歩")
                            .font(.title2.weight(.semibold))
                    }
                } // Section Today's Record End

                // --- 「水分を記録する」セクション ---
                Section("水分を記録する") {
                    // 手入力フォーム
                    HStack {
                         TextField("量 (ml)", text: $waterAmountString)
                             .keyboardType(.numberPad)
                         Button("記録") { recordWaterFromTextField() }
                             .buttonStyle(.bordered) // 少し控えめなスタイルに
                    }

                    // プリセットボタン
                    HStack {
                        Spacer() // 中央寄せのためのスペーサー
                        Button { recordWater(amount: 200.0) } label: {
                            VStack { Image(systemName: "cup.and.saucer.fill"); Text("コップ") } // テキスト短縮
                               .padding(.vertical, 6) // 縦の余白を少し調整
                               .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                        Spacer() // ボタン間のスペース
                        Button { recordWater(amount: 350.0) } label: {
                             VStack { Image(systemName: "mug.fill"); Text("トール") } // テキスト短縮
                                .padding(.vertical, 6)
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                        Spacer() // 中央寄せのためのスペーサー
                    }
                    .padding(.vertical, 4) // ボタン行全体の縦余白
                } // Section Record Water End

            } // List End
            // リストのスタイルをヘルスケア風に（角丸グループ化）
            .listStyle(.insetGrouped)
            // ナビゲーションバーにタイトルを表示
            .navigationTitle("WaterLog")
            // 画面表示時のデータ読み込み (変更なし)
            .onAppear {
                loadTodaysTotal()
                loadTodaysSteps()
            }
            // アラート表示 (変更なし)
            .alert(alertMessage, isPresented: $showingAlert) {
                Button("OK") {
                    showingAlert = false
                }
            }
            // ↓↓↓ .onChange はこの位置に移動させる ↓↓↓
            .onChange(of: scenePhase) { oldPhase, newPhase in
                if newPhase == .active {
                    print("アプリがアクティブになりました。データを更新します。")
                    loadTodaysTotal()
                    loadTodaysSteps()
                }
            } // ← .onChange をここに追加
        } // NavigationView End
    }

    // --- Helper Functions (変更なし) ---

    func recordWater(amount: Double) {
        Task {
            do {
                _ = try await healthKitManager.requestAuthorization()
                try await healthKitManager.saveWaterIntake(amount: amount)
                self.alertMessage = "\(Int(amount))ml 記録しました！"
                self.showingAlert = true
                loadTodaysTotal()
            } catch { handleError(error) }
        }
    }

    func recordWaterFromTextField() {
        guard let amount = Double(waterAmountString) else {
            self.alertMessage = "有効な数値を入力してください。"
            self.showingAlert = true
            return
        }
        self.waterAmountString = ""
        recordWater(amount: amount)
    }

    func loadTodaysTotal() {
        Task {
            do {
                let total = try await healthKitManager.fetchTodaysWaterIntake()
                await MainActor.run { self.todaysTotal = total }
            } catch { print("合計(水分)の取得失敗: \(error)") }
        }
    }

    func loadTodaysSteps() {
        Task {
            do {
                _ = try await healthKitManager.requestAuthorization() // 念のため権限確認
                let steps = try await healthKitManager.fetchTodaysStepCount()
                await MainActor.run { self.todaysSteps = steps }
            } catch { print("合計(歩数)の取得失敗: \(error)") }
        }
    }

     func handleError(_ error: Error) {
         print("エラー発生: \(error.localizedDescription)")
         if let healthKitError = error as? HealthKitError {
             self.alertMessage = "エラー: \(healthKitError.localizedDescription)"
         } else {
             self.alertMessage = "予期せぬエラーが発生しました。"
         }
         self.showingAlert = true
     }
}

// プレビュー用コード (変更なし)
#Preview {
    ContentView()
}
