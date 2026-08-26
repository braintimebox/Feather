//
//  Storage+Signed.swift
//  Feather
//
//  Created by samara on 17.04.2025.
//

import CoreData
import UIKit.UIImpactFeedbackGenerator

// MARK: - Class extension: Signed Apps
extension Storage {
	func addSigned(
		uuid: String,
		source: URL? = nil,
		certificate: CertificatePair? = nil,
		
		appName: String? = nil,
		appIdentifier: String? = nil,
		appVersion: String? = nil,
		appIcon: String? = nil,
		
		completion: @escaping (Error?) -> Void
	) {
		let generator = UIImpactFeedbackGenerator(style: .light)
		
		let new = Signed(context: context)
		
		new.uuid = uuid
		new.source = source
		new.date = Date()
		// if nil, we assume adhoc or certificate was deleted afterwards
		new.certificate = certificate
		// could possibly be nil, but thats fine.
		new.identifier = appIdentifier
		new.name = appName
		new.icon = appIcon
		new.version = appVersion
		
		saveContext()
		
		// Keep only the 3 most recent signed versions of the same app
		// (grouped by bundle identifier) to avoid filling device storage.
		pruneSignedVersions(identifier: appIdentifier, keep: 3)
		
		generator.impactOccurred()
		completion(nil)
	}
	
	/// Removes the oldest signed builds of the same bundle identifier so that
	/// only the `keep` most recent versions remain.
	private func pruneSignedVersions(identifier: String?, keep: Int) {
		guard let identifier, !identifier.isEmpty else { return }
		
		let request: NSFetchRequest<Signed> = Signed.fetchRequest()
		request.predicate = NSPredicate(format: "identifier == %@", identifier)
		request.sortDescriptors = [NSSortDescriptor(keyPath: \Signed.date, ascending: false)]
		
		guard let all = try? context.fetch(request), all.count > keep else { return }
		
		for app in all.dropFirst(keep) {
			deleteApp(for: app)
		}
	}
}
