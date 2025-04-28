import SwiftUI

struct ContentView: View {
    // HealthKitManagerを使えるように準備 (変更なし)
    @StateObject private var healthKitManager = HealthKitManager()

    // --- waterAmountString は不要になったので削除 ---

    // アラート表示用の変数 (変更なし)
    @State private var showingAlert = false
    @State private var alertMessage = ""

    // 合計値用の変数 (変更なし)
    @State private var todaysTotal: Double = 0.0

    var body: some View {
        VStack { // 全体を縦に並べる

            // --- 合計値表示 (変更なし) ---
            Text("今日の合計: \(Int(todaysTotal)) ml")
                .font(.title2)
                .padding(.top)

            Spacer() // 上部とボタンの間にスペースを空ける

            // --- 記録用ボタン (ここを大きく変更) ---
            HStack { // ボタンを横に並べる
                Spacer() // 左のスペース

                // --- コップ (200ml) ボタン ---
                Button {
                    // ボタンが押されたら200ml記録する関数を呼ぶ
                    recordWater(amount: 200.0)
                } label: {
                    VStack { // アイコンとテキストを縦に並べる
                        Image(systemName: "cup.and.saucer.fill") // コップっぽいアイコン
                            .font(.title) // アイコンサイズ
                        Text("コップ (200ml)")
                    }
                    .padding() // ボタン内の余白
                    .frame(maxWidth: .infinity) // ボタンの幅を広げる
                }
                .buttonStyle(.bordered) // ボタンのスタイル（枠線付き）

                Spacer() // ボタン間のスペース

                // --- トールサイズ (350ml) ボタン ---
                Button {
                    // ボタンが押されたら350ml記録する関数を呼ぶ
                    recordWater(amount: 350.0)
                } label: {
                    VStack {
                        Image(systemName: "mug.fill") // マグカップっぽいアイコン
                            .font(.title)
                        Text("トール (350ml)") // トールサイズだと長いので少し短縮
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)

                Spacer() // 右のスペース
            }
            .padding(.horizontal) // ボタン左右の余白

            // --- 手入力用の TextField と Button は削除 ---

            Spacer() // ボタンと画面下部の間にスペース

        }
        // 画面が表示された時に合計を読み込む (変更なし)
        .onAppear {
            loadTodaysTotal()
        }
        // アラート表示の設定 (変更なし)
        .alert(alertMessage, isPresented: $showingAlert) {
            Button("OK") {
                showingAlert = false
            }
        }
    }

    // --- 水分を記録する共通の処理 (新しい関数) ---
    func recordWater(amount: Double) {
        Task { // 非同期処理を開始
            do {
                print("ContentView: \(amount)ml を記録します...")
                // 権限リクエスト（毎回確認するがダイアログは初回のみ）
                _ = try await healthKitManager.requestAuthorization()
                // データを保存
                try await healthKitManager.saveWaterIntake(amount: amount)

                // 成功アラートの準備
                self.alertMessage = "\(Int(amount))ml 記録しました！"
                self.showingAlert = true
                // 合計値を再読み込みして画面を更新
                loadTodaysTotal()

            } catch let error as HealthKitError { // エラー処理 (変更なし)
                print("HealthKitエラー: \(error.localizedDescription)")
                self.alertMessage = "エラーが発生しました: \(error.localizedDescription)"
                self.showingAlert = true
            } catch { // その他のエラー処理 (変更なし)
                print("予期せぬエラー: \(error.localizedDescription)")
                self.alertMessage = "予期せぬエラーが発生しました。"
                self.showingAlert = true
            }
        }
    }

    // --- 合計値を取得・更新する関数 (変更なし) ---
    func loadTodaysTotal() {
        Task {
            do {
                print("ContentView: 今日の合計を取得します...")
                let total = try await healthKitManager.fetchTodaysWaterIntake()
                await MainActor.run {
                     self.todaysTotal = total
                     print("ContentView: 合計値を更新しました - \(total)")
                }
            } catch {
                print("ContentView: 合計の取得に失敗 - \(error.localizedDescription)")
                self.alertMessage = "今日の合計値を取得できませんでした。"
                // showingAlert = true // 起動時のエラーは表示しない方が良いかも？
            }
        }
    }
}

// プレビュー用コード (変更なし)
#Preview {
    ContentView()
}
