import SwiftUI

struct ContentView: View {
    @StateObject private var healthKitManager = HealthKitManager()
    // 手入力用の @State を復活
    @State private var waterAmountString: String = ""
    // アラート用 (変更なし)
    @State private var showingAlert = false
    @State private var alertMessage = ""
    // 合計水分量用 (変更なし)
    @State private var todaysTotal: Double = 0.0
    // ★★★ 歩数用の @State を追加 ★★★
    @State private var todaysSteps: Double = 0.0

    var body: some View {
        VStack(spacing: 20) { // 要素間のスペースを少し空ける

            // 1. タイトルを変更
            Text("🌊WaterLog🌊")
                .font(.largeTitle.bold()) // 大きく太字に
                .padding(.top)

            // 2. 手入力フォームを復活 (ボタンの上)
            HStack {
                TextField("量 (ml)", text: $waterAmountString)
                    .keyboardType(.numberPad)
                    .padding(10)
                    .background(Color(uiColor: .secondarySystemBackground))
                    .cornerRadius(8)

                Button("記録") {
                    recordWaterFromTextField() // 手入力用の記録関数を呼ぶ
                }
                .buttonStyle(.borderedProminent) // 目立つスタイル
            }
            .padding(.horizontal)

            // 3. プリセットボタン (変更なし)
            HStack {
                Spacer()
                Button { recordWater(amount: 200.0) } label: {
                    VStack { Image(systemName: "cup.and.saucer.fill").font(.title); Text("コップ (200ml)") }
                    .padding().frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                Spacer()
                Button { recordWater(amount: 350.0) } label: {
                     VStack { Image(systemName: "mug.fill").font(.title); Text("トール (350ml)") }
                     .padding().frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                Spacer()
            }
            .padding(.horizontal)

            // 4. 今日の合計水分量 (ボタンの下、大きく)
            Text("今日の合計: \(Int(todaysTotal)) ml")
                .font(.title.bold()) // ← 大きく太字に
                .padding(.top) // 上に少しスペース

            Spacer() // スペーサーで歩数を一番下に

            // 5. 今日の歩数を表示 (一番下)
            Text("今日の歩数: \(Int(todaysSteps)) 歩")
                .font(.headline) // 少し小さめの見出しフォント
                .padding(.bottom) // 下に余白

        }
        .onAppear {
            // 画面表示時に両方のデータを読み込む
            loadTodaysTotal()
            loadTodaysSteps() // ← 歩数読み込みを追加
        }
        .alert(alertMessage, isPresented: $showingAlert) {
            Button("OK") {
                showingAlert = false
            }
        }
    }

    // --- Helper Functions ---

    // プリセットボタン・手入力記録ボタンから呼ばれる共通処理
    func recordWater(amount: Double) {
        Task {
            do {
                print("ContentView: \(amount)ml を記録します...")
                _ = try await healthKitManager.requestAuthorization()
                try await healthKitManager.saveWaterIntake(amount: amount)

                self.alertMessage = "\(Int(amount))ml 記録しました！"
                self.showingAlert = true
                loadTodaysTotal() // 合計を再読み込み

            } catch let error { // エラー処理を共通化
                 handleError(error)
            }
        }
    }

    // 手入力フォームの「記録」ボタン専用の処理
    func recordWaterFromTextField() {
        guard let amount = Double(waterAmountString) else {
            self.alertMessage = "有効な数値を入力してください。"
            self.showingAlert = true
            return
        }
        self.waterAmountString = "" // 入力欄をクリア
        recordWater(amount: amount) // 共通の記録処理を呼ぶ
    }

    // 合計水分量を取得・更新する関数 (変更なし)
    func loadTodaysTotal() {
        Task {
            do {
                print("ContentView: 今日の合計(水分)を取得します...")
                let total = try await healthKitManager.fetchTodaysWaterIntake()
                await MainActor.run {
                     self.todaysTotal = total
                     print("ContentView: 合計(水分)を更新しました - \(total)")
                }
            } catch {
                print("ContentView: 合計(水分)の取得に失敗 - \(error.localizedDescription)")
                // 起動時のエラーはアラート表示しない方が親切かも
            }
        }
    }

    // ★★★ 歩数を取得・更新する関数を追加 ★★★
    func loadTodaysSteps() {
        Task {
            do {
                print("ContentView: 今日の合計(歩数)を取得します...")
                // 権限リクエストは loadTodaysTotal or recordWater で行われる想定
                // _ = try await healthKitManager.requestAuthorization() // ここでも呼んでも良い
                let steps = try await healthKitManager.fetchTodaysStepCount()
                await MainActor.run {
                     self.todaysSteps = steps
                     print("ContentView: 合計(歩数)を更新しました - \(steps)")
                }
            } catch {
                print("ContentView: 合計(歩数)の取得に失敗 - \(error.localizedDescription)")
                // 起動時のエラーはアラート表示しない方が親切かも
            }
        }
    }

     // ★★★ エラー処理を共通化する関数 ★★★
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

#Preview {
    ContentView()
}
