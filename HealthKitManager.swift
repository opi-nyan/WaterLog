import Foundation
import HealthKit
import Combine

// エラーenum (fetchFailedがあるか確認)
enum HealthKitError: Error, LocalizedError {
    case dataTypeNotAvailable
    case deviceNotSupported
    // case authorizationFailed // 必要なら
    case saveFailed(Error?)
    case fetchFailed(Error?) // データ取得失敗エラー

    var errorDescription: String? {
        switch self {
        case .dataTypeNotAvailable:
            return "必要なデータタイプが利用できません。" // 水分/歩数 両方で使う可能性
        case .deviceNotSupported:
            return "このデバイスではHealthKitは利用できません。"
        case .saveFailed(let error):
             return "データの保存に失敗しました: \(error?.localizedDescription ?? "不明なエラー")"
        case .fetchFailed(let error):
             return "データの取得に失敗しました: \(error?.localizedDescription ?? "不明なエラー")"
        }
    }
}


class HealthKitManager: ObservableObject {
    let healthStore = HKHealthStore()

    // --- requestAuthorization メソッドを修正 ---
    func requestAuthorization() async throws -> Bool {
        // 扱うデータタイプを取得（水分と歩数）
        guard let waterType = HKObjectType.quantityType(forIdentifier: .dietaryWater),
              let stepType = HKObjectType.quantityType(forIdentifier: .stepCount) // <-- 歩数を追加
        else {
            print("必要なデータタイプが利用できません")
            throw HealthKitError.dataTypeNotAvailable
        }

        // 書き込みたいタイプ（水分のみ）
        let typesToWrite: Set = [waterType]
        // ★★★ 読み取りたいタイプ（水分と歩数）★★★
        let typesToRead: Set = [waterType, stepType] // <-- 歩数を追加

        guard HKHealthStore.isHealthDataAvailable() else {
            print("このデバイスではHealthKitは利用できません")
            throw HealthKitError.deviceNotSupported
        }

        print("HealthKitへの読み書き権限をリクエストします...")
        // ★★★ read: パラメータに typesToRead を指定 ★★★
        try await healthStore.requestAuthorization(toShare: typesToWrite, read: typesToRead)
        print("権限リクエストが完了しました。")
        return true // エラーなければ完了
    }

    // --- saveWaterIntake メソッドは変更なし ---
    func saveWaterIntake(amount: Double) async throws {
        // ... (変更なし) ...
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

    // --- fetchTodaysWaterIntake メソッドは変更なし ---
    func fetchTodaysWaterIntake() async throws -> Double {
        // ... (前回のコードのまま) ...
        guard let waterType = HKQuantityType.quantityType(forIdentifier: .dietaryWater) else {
            print("水分データタイプが利用できません")
            throw HealthKitError.dataTypeNotAvailable
        }
        let calendar = Calendar.current
        let startDate = calendar.startOfDay(for: Date())
        let endDate = Date()
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictStartDate)
        return try await withCheckedThrowingContinuation { continuation in
            let query = HKStatisticsQuery(quantityType: waterType,
                                          quantitySamplePredicate: predicate,
                                          options: .cumulativeSum) { _, result, error in
                if let error = error {
                    print("今日の水分合計の取得に失敗しました: \(error.localizedDescription)")
                    continuation.resume(throwing: HealthKitError.fetchFailed(error))
                    return
                }
                var totalAmount: Double = 0.0
                if let sumQuantity = result?.sumQuantity() {
                    totalAmount = sumQuantity.doubleValue(for: .literUnit(with: .milli))
                    print("今日の合計水分摂取量(取得成功): \(totalAmount) ml")
                } else {
                    print("今日の合計水分摂取量(データなし): 0 ml")
                }
                continuation.resume(returning: totalAmount)
            }
            healthStore.execute(query)
        }
    }

    // --- ★★★ 今日の歩数を取得するメソッドを追加 ★★★ ---
    func fetchTodaysStepCount() async throws -> Double {
        guard let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount) else {
            print("歩数データタイプが利用できません")
            throw HealthKitError.dataTypeNotAvailable
        }

        let calendar = Calendar.current
        let startDate = calendar.startOfDay(for: Date()) // 今日の0時
        let endDate = Date() // 現在時刻
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictStartDate)

        // 合計値を取得するクエリ (歩数も cumulativeSum でOK)
        return try await withCheckedThrowingContinuation { continuation in
            let query = HKStatisticsQuery(quantityType: stepType,
                                          quantitySamplePredicate: predicate,
                                          options: .cumulativeSum) { _, result, error in
                if let error = error {
                    print("今日の歩数合計の取得に失敗しました: \(error.localizedDescription)")
                    continuation.resume(throwing: HealthKitError.fetchFailed(error))
                    return
                }

                var totalSteps: Double = 0.0
                if let sumQuantity = result?.sumQuantity() {
                    // 歩数の単位は .count()
                    totalSteps = sumQuantity.doubleValue(for: .count())
                    print("今日の合計歩数(取得成功): \(totalSteps) 歩")
                } else {
                    print("今日の合計歩数(データなし): 0 歩")
                }
                continuation.resume(returning: totalSteps)
            }
            healthStore.execute(query)
        }
    }
    // --- ここまで追加 ---

}
