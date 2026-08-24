//
//  UIKitFileImporter.swift
//  Feather
//
//  Created by samara on 23.04.2025.
//

import SwiftUI
import UniformTypeIdentifiers

public struct FileImporterRepresentableView: UIViewControllerRepresentable {
	public var allowedContentTypes: [UTType]
	public var allowsMultipleSelection: Bool = false
	public var startingDirectoryURL: URL? = nil
	public var onDocumentsPicked: ([URL]) -> Void
	
	public init(
		allowedContentTypes: [UTType],
		allowsMultipleSelection: Bool = false,
		startingDirectoryURL: URL? = nil,
		onDocumentsPicked: @escaping ([URL]) -> Void
	) {
		self.allowedContentTypes = allowedContentTypes
		self.allowsMultipleSelection = allowsMultipleSelection
		self.startingDirectoryURL = startingDirectoryURL
		self.onDocumentsPicked = onDocumentsPicked
	}
	
	public func makeCoordinator() -> Coordinator {
		Coordinator(onDocumentsPicked: onDocumentsPicked)
	}
	
	public func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
		let picker = UIDocumentPickerViewController(
			forOpeningContentTypes: allowedContentTypes,
			asCopy: true,
			initialDirectoryURL: startingDirectoryURL
		)
		picker.delegate = context.coordinator
		picker.allowsMultipleSelection = allowsMultipleSelection
		return picker
	}
	
	public func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}
	
	public class Coordinator: NSObject, UIDocumentPickerDelegate {
		var onDocumentsPicked: ([URL]) -> Void
		
		init(onDocumentsPicked: @escaping ([URL]) -> Void) {
			self.onDocumentsPicked = onDocumentsPicked
		}
		
		public func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
			onDocumentsPicked(urls)
		}
		
		public func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
			onDocumentsPicked([])
		}
	}
}
