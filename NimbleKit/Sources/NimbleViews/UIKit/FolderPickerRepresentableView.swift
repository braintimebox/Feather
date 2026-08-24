//
//  FolderPickerRepresentableView.swift
//  Feather
//
//  A system folder picker (single folder selection) used to choose a
//  default folder — e.g. the Default IPA Folder in Settings.
//

import SwiftUI
import UniformTypeIdentifiers

public struct FolderPickerRepresentableView: UIViewControllerRepresentable {
	public var onFolderPicked: (URL?) -> Void
	
	public init(onFolderPicked: @escaping (URL?) -> Void) {
		self.onFolderPicked = onFolderPicked
	}
	
	public func makeCoordinator() -> Coordinator {
		Coordinator(onFolderPicked: onFolderPicked)
	}
	
	public func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
		let picker = UIDocumentPickerViewController(forOpeningContentTypes: [.folder], asCopy: false)
		picker.delegate = context.coordinator
		picker.allowsMultipleSelection = false
		return picker
	}
	
	public func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}
	
	public class Coordinator: NSObject, UIDocumentPickerDelegate {
		var onFolderPicked: (URL?) -> Void
		
		init(onFolderPicked: @escaping (URL?) -> Void) {
			self.onFolderPicked = onFolderPicked
		}
		
		public func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
			onFolderPicked(urls.first)
		}
		
		public func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
			onFolderPicked(nil)
		}
	}
}
