//
//  SigningFlow.swift
//  Feather
//
//  Auto-sign flow: signs an imported app immediately after import using the
//  currently selected certificate and the persisted signing options.
//

import Foundation
import UIKit

// MARK: - SigningFlow
enum SigningFlow {
	/// Resolves the currently selected certificate (same ordering as the UI:
	/// sorted by date, descending, indexed by `feather.selectedCert`).
	static func resolveSelectedCertificate() -> CertificatePair? {
		let index = UserDefaults.standard.integer(forKey: "feather.selectedCert")
		return Storage.shared.getCertificate(for: index)
	}
	
	/// Applies the persisted options and the per-app substitutions
	/// (PPQ protection, bundle id / display name rules) for the given app.
	static func resolvedOptions(
		for app: AppInfoPresentable,
		certificate: CertificatePair?
	) -> Options {
		var options = OptionsManager.shared.options
		
		if
			options.ppqProtection,
			let identifier = app.identifier,
			let cert = certificate,
			cert.ppQCheck
		{
			options.appIdentifier = "\(identifier).\(options.ppqString)"
		}
		
		if
			let currentBundleId = app.identifier,
			let newBundleId = options.identifiers[currentBundleId]
		{
			options.appIdentifier = newBundleId
		}
		
		if
			let currentName = app.name,
			let newName = options.displayNames[currentName]
		{
			options.appName = newName
		}
		
		return options
	}
	
	/// Signs an imported app automatically and (if the user enabled the
	/// post-signing options) triggers installation and cleanup.
	static func autoSign(
		app: AppInfoPresentable,
		completion: @escaping (Error?) -> Void = { _ in }
	) {
		let certificate = resolveSelectedCertificate()
		let options = resolvedOptions(for: app, certificate: certificate)
		
		// Mirror SigningView's gate: without a certificate and without a
		// modify-only signing option there is nothing to sign — leave the app
		// as imported rather than blocking the user.
		guard certificate != nil || options.signingOption != .default else {
			completion(nil)
			return
		}
		
		FR.signPackageFile(
			app,
			using: options,
			icon: nil,
			certificate: certificate
		) { error in
			if let error {
				completion(error)
				return
			}
			
			if options.post_deleteAppAfterSigned, !app.isSigned {
				Storage.shared.deleteApp(for: app)
			}
			
			if options.post_installAppAfterSigned {
				DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
					NotificationCenter.default.post(
						name: Notification.Name("Feather.installApp"),
						object: nil
					)
				}
			}
			
			completion(nil)
		}
	}
}
