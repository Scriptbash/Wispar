import UIKit
import Flutter
import UniformTypeIdentifiers

class FolderPickerDelegate: NSObject, UIDocumentPickerDelegate {
    
    var pickerCompletionHandler: ((String?) -> Void)?
    
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        guard let url = urls.first else {
            pickerCompletionHandler?(nil)
            return
        }
        
        guard url.startAccessingSecurityScopedResource() else {
            print("Failed to start accessing security-scoped resource.")
            pickerCompletionHandler?(nil)
            return
        }
        
        do {
            let bookmarkData = try url.bookmarkData(
                options: [],
                includingResourceValuesForKeys: nil,
                relativeTo: nil
            )

            url.stopAccessingSecurityScopedResource()
            
            let base64Bookmark = bookmarkData.base64EncodedString()
            
            pickerCompletionHandler?(base64Bookmark)
            
        } catch {
            url.stopAccessingSecurityScopedResource() 
            print("Error creating bookmark for URL: \(error)")
            pickerCompletionHandler?(nil)
        }
    }
    
    func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
        pickerCompletionHandler?(nil)
    }
}