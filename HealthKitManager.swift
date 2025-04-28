import Foundation
import HealthKit // ← ① これがありますか？ ファイルの先頭です。
import Combine // ← これを追加

// エラーの種類を定義 (クラスの外、または中に記述)
enum HealthKitError: Error {
    case dataTypeNotAvailable
    case deviceNotSupported
    // case authorizationFailed // 必要なら追加
    case saveFailed(Error?)
}

class HealthKitManager: ObservableObject { // ← 「: ObservableObject」を追記！

    let healthStore = HKHealthStore() // ← クラスの中

    // 権限リクエストメソッド (クラスの中)
    func requestAuthorization() async throws -> Bool {
        guard let waterType = HKObjectType.quantityType(forIdentifier: .dietaryWater) else {
            print("水分データタイプが利用できません")
            throw HealthKitError.dataTypeNotAvailable // HealthKitError を使用
        }
        let typesToWrite: Set = [waterType]

        guard HKHealthStore.isHealthDataAvailable() else {
            print("このデバイスではHealthKitは利用できません")
            throw HealthKitError.deviceNotSupported // HealthKitError を使用
        }

        print("HealthKitへの書き込み権限をリクエストします...")
        // healthStore プロパティを使用
        try await healthStore.requestAuthorization(toShare: typesToWrite, read: [])
        print("権限リクエストが完了しました。")
        return true
    }

    // データ保存メソッド (クラスの中)
    func saveWaterIntake(amount: Double) async throws {
        guard let waterType = HKQuantityType.quantityType(forIdentifier: .dietaryWater) else {
            print("水分データタイプが利用できません")
            throw HealthKitError.dataTypeNotAvailable // HealthKitError を使用
        }

        let waterQuantity = HKQuantity(unit: .literUnit(with: .milli), doubleValue: amount)
        let waterSample = HKQuantitySample(type: waterType, quantity: waterQuantity, start: Date(), end: Date())

        print("\(amount)ml のデータを保存します...")
        do {
            // healthStore プロパティを使用
            try await healthStore.save(waterSample)
            print("データの保存に成功しました！")
        } catch {
            print("データの保存に失敗しました: \(error.localizedDescription)")
            // HealthKitError を使用
            throw HealthKitError.saveFailed(error)
        }
    }

} // ← ② クラス定義の終わり }
