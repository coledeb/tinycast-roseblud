import Foundation
import Security

/// Proves a staged bundle is ours: sealed, and signed by the Tinycast team under Developer ID.
enum BundleSignature {
    /// The team, not the certificate — a leaf is reissued on renewal and on a rename.
    static let developerID = """
        anchor apple generic \
        and certificate leaf[subject.OU] = "J656U8XZ93" \
        and certificate 1[field.1.2.840.113635.100.6.2.6] exists \
        and certificate leaf[field.1.2.840.113635.100.6.1.13] exists
        """

    /// No `notarized`: its ticket lookup can hit the network, and the chain already proves ownership.
    static func isTrusted(_ bundleURL: URL) -> Bool {
        var staticCode: SecStaticCode?
        var requirement: SecRequirement?
        guard SecStaticCodeCreateWithPath(bundleURL as CFURL, [], &staticCode) == errSecSuccess,
            let staticCode,
            SecRequirementCreateWithString(developerID as CFString, [], &requirement) == errSecSuccess,
            let requirement
        else { return false }
        // An unsealed bundle can claim any identity, and a nested helper is where one hides.
        let flags = SecCSFlags(rawValue: kSecCSCheckAllArchitectures | kSecCSCheckNestedCode)
        if SecStaticCodeCheckValidity(staticCode, flags, requirement) == errSecSuccess { return true }
        return spaceMatchesRunningLeaf(staticCode, flags: flags)
    }
}

// Space Edition: the fork signs with its own "Tinycast Self-Signed" key, never a Developer ID, so a
// sealed bundle carrying the same leaf as the running copy is ours (upstream dropped this in dc265b2).
extension BundleSignature {
    fileprivate static func spaceMatchesRunningLeaf(_ staticCode: SecStaticCode, flags: SecCSFlags) -> Bool {
        guard SecStaticCodeCheckValidity(staticCode, flags, nil) == errSecSuccess,
            let running = spaceRunningLeaf(), let candidate = spaceLeaf(of: staticCode)
        else { return false }
        return running == candidate
    }

    fileprivate static func spaceRunningLeaf() -> Data? {
        var code: SecCode?
        guard SecCodeCopySelf([], &code) == errSecSuccess, let code else { return nil }
        var staticCode: SecStaticCode?
        guard SecCodeCopyStaticCode(code, [], &staticCode) == errSecSuccess, let staticCode else {
            return nil
        }
        return spaceLeaf(of: staticCode)
    }

    fileprivate static func spaceLeaf(of code: SecStaticCode) -> Data? {
        var information: CFDictionary?
        let flags = SecCSFlags(rawValue: kSecCSSigningInformation)
        guard SecCodeCopySigningInformation(code, flags, &information) == errSecSuccess,
            let dictionary = information as? [String: Any],
            let certificates = dictionary[kSecCodeInfoCertificates as String] as? [SecCertificate],
            let leaf = certificates.first
        else { return nil }
        return SecCertificateCopyData(leaf) as Data
    }
}
