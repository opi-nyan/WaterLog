import AppIntents
import HealthKit // HealthKitManager を使うために必要

// ショートカットアプリで使えるアクションを定義します
struct RecordFixedWaterIntent: AppIntent {

    // ショートカットアプリの一覧に表示されるアクションの名前
    static var title: LocalizedStringResource = "水分摂取を記録 (200ml)"
    // アクションの説明文（任意）
    static var description = IntentDescription("ワンタップで200mlの水分摂取をヘルスケアに記録します。")

    // アクション実行時にアプリ本体を開くかどうか（falseでバックグラウンド実行）
    static var openAppWhenRun: Bool = false

    // このアクションが実行された時に呼ばれる処理
    @MainActor // 念のためメインスレッドで実行指定
    func perform() async throws -> some ProvidesDialog { // 結果としてダイアログを表示する
        print("RecordFixedWaterIntent: perform() が呼ばれました")

        // ヘルスケア操作を行うマネージャーを準備
        let healthKitManager = HealthKitManager()
        let amountToRecord: Double = 200.0 // 記録する量を200mlに固定

        // ヘルスケアへの書き込みを実行
        do {
            // まず権限があるか（なければリクエスト）
            print("RecordFixedWaterIntent: 権限をリクエストまたは確認します...")
            // 戻り値は使わないので _ で受けます
            _ = try await healthKitManager.requestAuthorization()

            // データを保存
            print("RecordFixedWaterIntent: \(amountToRecord)ml を保存します...")
            try await healthKitManager.saveWaterIntake(amount: amountToRecord)

            // 成功したら、ショートカット実行結果としてメッセージを表示
            print("RecordFixedWaterIntent: 保存に成功しました")
            // .result(dialog:) でユーザーにフィードバックを返します
            return .result(dialog: "\(Int(amountToRecord))ml 記録しました。")

        } catch let error as HealthKitError { // 自作のエラーをキャッチ
            print("RecordFixedWaterIntent: HealthKitエラー - \(error.localizedDescription)")
            // エラーが発生したことをショートカットに伝えます (エラー内容がダイアログで表示されます)
            throw error // エラーをそのままスロー
        } catch { // その他の予期せぬエラー
            print("RecordFixedWaterIntent: 予期せぬエラー - \(error.localizedDescription)")
            throw error // エラーをそのままスロー
        }
    }
}

// (もしプレビュー用のコードが必要なら追記しますが、AppIntentには通常不要です)
