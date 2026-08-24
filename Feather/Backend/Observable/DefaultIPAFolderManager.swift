//
//  DefaultIPAFolderManager.swift
//  Feather
//
//  Default IPA Folder — persistent security-scoped bookmark to the folder
//  the picker should open when importing IPA files.
//

import Foundation

// MARK: - DefaultIPAFolderManager
final class DefaultIPAFolderManager: ObservableObject {
	static let shared = DefaultIPAFolderManager()
	
	/// UserDefaults key holding the security-scoped bookmark data for the chosen folder.
	private let _bookmarkKey = "Feather.defaultIPAFolderBookmark"
	
	@Published private(set) var resolvedURL: URL?
	
	init() {
		self.resolvedURL = Self.resolveStoredFolder()
	}
	
	/// Saves a security-scoped bookmark for the given folder URL.
	/// The caller must have already granted access (e.g. via a folder picker).
	static func saveFolder(_ url: URL) throws {
		let bookmarkData = try url.bookmarkData(
			options: [.withSecurityScope],
			includingResourceValuesForKeys: nil,
			relativeTo: nil
		)
		UserDefaults.standard.set(bookmarkData, forKey: "Feather.defaultIPAFolderBookmark")
		shared.resolvedURL = url
	}
	
	/// Clears the stored folder (falls back to a system-default picker).
	static func clearFolder() {
		UserDefaults.standard.removeObject(forKey: "Feather.defaultIPAFolderBookmark")
		shared.resolvedURL = nil
	}
	
	/// Resolves the stored bookmark and starts security-scoped access.
	/// Returns nil when no folder is configured, the bookmark is stale,
	/// or the folder is no longer reachable.
	private static func resolveStoredFolder() -> URL? {
		guard let data = UserDefaults.standard.data(forKey: "Feather.defaultIPAFolderBookmark") else {
			return nil
		}
		
		var isStale = false
		guard
			let url = try? URL(
				resolvingBookmarkData: data,
				options: .withSecurityScope,
				relativeTo: nil,
				bookmarkDataIsStale: &isStale
			)
		else {
			return nil
		}
		
		// A stale bookmark might still resolve; this is fine for now — we
		// treat "unavailable" as resolvedURL == nil. Stale-but-valid folders
		// keep working until the user re-picks.
		_ = isStale
		
		return url
	}
	
	/// The folder to pass as `startingDirectoryURL` to the IPA picker.
	/// Returns nil when no folder is configured or it is no longer reachable,
	/// so the caller can fall back to a system-default picker.
	var startingDirectoryURL: URL? {
		guard let url = resolvedURL else { return nil }
		guard url.startAccessingSecurityScopedResource() else { return nil }
		return url
	}
	
	/// Must be called after the picker finishes using the folder to release access.
	func stopAccessing() {
		resolvedURL?.stopAccessingSecurityScopedResource()
	}
	
	/// Human-readable display name of the current folder (for Settings).
	var displayName: String? {
		resolvedURL?.lastPathComponent
	}
}
