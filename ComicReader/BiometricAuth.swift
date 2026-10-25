import LocalAuthentication

enum BiometricAuth {
    static func canAuthenticate() -> Bool {
        LAContext().canEvaluatePolicy(.deviceOwnerAuthentication, error: nil)
    }

    static func authenticate(reason: String, completion: @escaping (Bool) -> Void) {
        let context = LAContext()
        context.localizedCancelTitle = "Άκυρο"
        context.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: reason) { ok, _ in
            DispatchQueue.main.async { completion(ok) }
        }
    }
}
