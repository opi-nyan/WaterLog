import Foundation
import HealthKit
import Combine

// エラーの種類を定義
enum HealthKitError: Error, LocalizedError {
    case dataTypeNotAvailable
    case deviceNotSupported
    case authorizationFailed // 以前から(必要なら)
    case saveFailed(Error?)
    case fetchFailed(Error?) // ← 追加: データ取得失敗エラー

    // エラーメッセージを返す部分も修正
    var errorDescription: String? {
        switch self {
        case .dataTypeNotAvailable:
            return "水分データタイプが利用できません。"
        case .deviceNotSupported:
            return "このデバイスではHealthKitは利用できません。"
        case .authorizationFailed:
             return "ヘルスケアへのアクセスが許可されませんでした。" // 必要なら
        case .saveFailed(let error):
             return "データの保存に失敗しました: \(error?.localizedDescription ?? "不明なエラー")"
        case .fetchFailed(let error): // ← 追加
             return "データの取得に失敗しました: \(error?.localizedDescription ?? "不明なエラー")"
        }
    }
}

class HealthKitManager: ObservableObject {

    let healthStore = HKHealthStore()

    // --- requestAuthorization メソッドを修正 ---
    func requestAuthorization() async throws -> Bool {
        guard let waterType = HKObjectType.quantityType(forIdentifier: .dietaryWater) else {
            print("水分データタイプが利用できません")
            throw HealthKitError.dataTypeNotAvailable
        }
        // 書き込みたいタイプ
        let typesToWrite: Set = [waterType]
        // ★★★ 読み取りたいタイプを追加 ★★★
        let typesToRead: Set = [waterType]

        guard HKHealthStore.isHealthDataAvailable() else {
            print("このデバイスではHealthKitは利用できません")
            throw HealthKitError.deviceNotSupported
        }

        print("HealthKitへの読み書き権限をリクエストします...")
        // ★★★ read: パラメータに typesToRead を指定 ★★★
        try await healthStore.requestAuthorization(toShare: typesToWrite, read: typesToRead)
        print("権限リクエストが完了しました。")
        // 注：ユーザーが実際に何を許可したかは別途確認が必要だが、
        //     エラーなく完了すればリクエスト処理自体は成功とみなす。
        return true
    }

    // --- saveWaterIntake メソッドは変更なし ---
    func saveWaterIntake(amount: Double) async throws {
        // ... (以前のコードのまま) ...
        guard let waterType = HKQuantityType.quantityType(forIdentifier: .dietaryWater) else {
             print("水分データタイプが利用できません")
             throw HealthKitError.dataTypeNotAvailable
         }
         let waterQuantity = HKQuantity(unit: .literUnit(with: .milli), doubleValue: amount)
         let waterSample = HKQuantitySample(type: waterType, quantity: waterQuantity, start: Date(), end: Date())
         print("\(amount)ml のデータを保存します...")
         do {
             try await healthStore.save(waterSample)
             print("データの保存に成功しました！")
         } catch {
             print("データの保存に失敗しました: \(error.localizedDescription)")
             throw HealthKitError.saveFailed(error)
         }
    }

    // --- ★★★ 今日の合計値を取得するメソッドを追加 ★★★ ---
    func fetchTodaysWaterIntake() async throws -> Double {
        guard let waterType = HKQuantityType.quantityType(forIdentifier: .dietaryWater) else {
            print("水分データタイプが利用できません")
            throw HealthKitError.dataTypeNotAvailable
        }

        // 時間範囲（今日の0時〜現在）を指定
        let calendar = Calendar.current
        let startDate = calendar.startOfDay(for: Date()) // 今日の0時0分
        let endDate = Date() // 現在時刻

        // 時間範囲でデータを絞り込むための条件 (Predicate)
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictStartDate)

        // 合計値を取得するクエリ (HKStatisticsQuery) - これは完了ハンドラ形式
        // async/await で使えるようにラップします
        return try await withCheckedThrowingContinuation { continuation in
            let query = HKStatisticsQuery(quantityType: waterType,
                                          quantitySamplePredicate: predicate,
                                          options: .cumulativeSum) { _, result, error in // データ取得後の処理
                // エラーがあればエラーを投げて中断
                if let error = error {
                    print("今日の水分合計の取得に失敗しました: \(error.localizedDescription)")
                    continuation.resume(throwing: HealthKitError.fetchFailed(error))
                    return
                }

                // 合計値を取得
                var totalAmount: Double = 0.0
                if let sumQuantity = result?.sumQuantity() {
                    // 単位をミリリットルに変換して値を取得
                    totalAmount = sumQuantity.doubleValue(for: .literUnit(with: .milli))
                    print("今日の合計水分摂取量(取得成功): \(totalAmount) ml")
                } else {
                    // データがない場合 (エラーではない)
                    print("今日の合計水分摂取量(データなし): 0 ml")
                }
                // 取得した合計値 (0.0の場合も含む) を返す
                continuation.resume(returning: totalAmount)
            }
            // クエリを実行開始
            healthStore.execute(query)
        }
    }
    // --- ここまで追加 ---

}
