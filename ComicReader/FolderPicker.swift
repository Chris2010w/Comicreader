import SwiftUI
import UIKit
import UniformTypeIdentifiers

/// Εμφανίζει τον επιλογέα φακέλου του iOS (modal, όπως πρέπει να παρουσιάζεται).
final class FolderPicker: NSObject, UIDocumentPickerDelegate {
    private static var current: FolderPicker?
    private let onPick: (URL) -> Void

    private init(onPick: @escaping (URL) -> Void) {
        self.onPick = onPick
    }

    static func present(onPick: @escaping (URL) -> Void) {
        let helper = FolderPicker(onPick: onPick)
        current = helper
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: [.folder], asCopy: false)
        picker.allowsMultipleSelection = false
        picker.delegate = helper
        topViewController()?.present(picker, animated: true)
    }

    private static func topViewController() -> UIViewController? {
        let scenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
        let scene = scenes.first(where: { $0.activationState == .foregroundActive }) ?? scenes.first
        let window = scene?.windows.first(where: { $0.isKeyWindow }) ?? scene?.windows.first
        var top = window?.rootViewController
        while let presented = top?.presentedViewController {
            top = presented
        }
        return top
    }

    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        if let url = urls.first { onPick(url) }
        FolderPicker.current = nil
    }

    func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
        FolderPicker.current = nil
    }
}
