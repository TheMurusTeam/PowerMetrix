//
//  Verify XPC.swift
//  it.murus.powermetrix.helper
//
//  Created by hany on 30/10/21.
//

import Foundation


// MARK: - VERIFY XPC CONNECTION

// CLASSE USATA PER VALIDARE IL CLIENT DELLA CONNESSIONE XPC

/*
 codice derivato da https://github.com/securing/SimpleXPCApp
 più info sul problema dell'autenticazione XPC qui: https://developer.apple.com/forums/thread/72881
 
 Questa classe controlla se il client della connessione XPC soddisfa i requisiti:
 - deve essere un'app firmata
 - deve avere gli entitlements giusti o meglio NON deve avere alcuni entitlements specifici che consentirebbero di exploitare l'app
 - deve soddisfare un requirement specifico hardcodato che include il nostro teamID RNLG254GCK
 
 NOTA BENE:
 scommentare riga 121 per la release. In fase di sviluppo va commentata perchè le app generate facendo PLAY su Xcode usano l'entitlement "com.apple.security.get-task-allow" che in teoria sarebbe pericoloso quindi vietato.
 
 */



class PMXPCVerifier {
    
    public static func isValid(connection: NSXPCConnection) -> Bool {
        
        NSLog("authenticating XPC client...")
        
        var secCodeOptional: SecCode? = nil
        var secStaticCodeOptional: SecStaticCode? = nil
        
        // prendi l'audittoken della connessione XPC usando le api private
        if !prepareCodeReferencesFromAuditToken(connection: connection, secCodeOptional: &secCodeOptional, secStaticCodeOptional: &secStaticCodeOptional) {
            return false
        }
        
        // verifica gli entitlements dell'app client (hardened runtime e altro)
        if !verifyHardenedRuntimeAndProblematicEntitlements(secStaticCode: secStaticCodeOptional!) {
            return false
        }
        
        // verifica se l'app soddisfa i requirement prestabiliti (ossia se matcha il team id)
        if !verifyWithRequirementString(secCode: secCodeOptional!) {
            return false
        }
        
        NSLog("XPC client approved")
        return true
    }
    
    
    
    // SECCODE FROM AUDITTOKEN
    
    private static func prepareCodeReferencesFromAuditToken(connection: NSXPCConnection, secCodeOptional: inout SecCode?, secStaticCodeOptional: inout SecStaticCode?) -> Bool {
        let token = XPCauditToken.auditTokenData(connection)
        let dict = [ kSecGuestAttributeAudit : token ]
        if SecCodeCopyGuestWithAttributes(nil, dict as CFDictionary, SecCSFlags(rawValue: 0), &secCodeOptional) != errSecSuccess {
            // NSLog("Couldn't get SecCode with the audit token")
            return false
        }
        
        guard let secCode = secCodeOptional else {
            // NSLog("Couldn't unwrap the secCode")
            return false
        }
        
        SecCodeCopyStaticCode(secCode, SecCSFlags(rawValue: 0), &secStaticCodeOptional)
        
        guard let _ = secStaticCodeOptional else {
            // NSLog("Couldn't unwrap the secStaticCode")
            return false
        }
        
        return true
    }
    
    
    
    // VERIFY ENTITLEMENTS
    
    private static func verifyHardenedRuntimeAndProblematicEntitlements(secStaticCode: SecStaticCode) -> Bool {
        var signingInformationOptional: CFDictionary? = nil
        if SecCodeCopySigningInformation(secStaticCode, SecCSFlags(rawValue: kSecCSDynamicInformation), &signingInformationOptional) != errSecSuccess {
            // NSLog("Couldn't obtain signing information")
            return false
        }
        
        guard let signingInformation = signingInformationOptional else {
            return false
        }
        
        let signingInformationDict = signingInformation as NSDictionary
        
        let signingFlagsOptional = signingInformationDict.object(forKey: "flags") as? UInt32
        
        if let signingFlags = signingFlagsOptional {
            let hardenedRuntimeFlag: UInt32 = 0x10000
            if (signingFlags & hardenedRuntimeFlag) != hardenedRuntimeFlag {
                // NSLog("Hardened runtime is not set for the sender")
                return false
            }
        } else {
            return false
        }
        
        let entitlementsOptional = signingInformationDict.object(forKey: "entitlements-dict") as? NSDictionary
        guard let entitlements = entitlementsOptional else {
            return false
        }
        // NSLog("Entitlements are \(entitlements)")
        let problematicEntitlements = [
            "com.apple.security.get-task-allow",
            "com.apple.security.cs.disable-library-validation",
            "com.apple.security.cs.allow-dyld-environment-variables"
        ]
        
        for problematicEntitlement in problematicEntitlements {
            if let presentEntitlement = entitlements.object(forKey: problematicEntitlement) {
                if presentEntitlement as! Int == 1 {
                    //  NSLog("The sender has \(problematicEntitlement) entitlement set to true")
                    return false
                }
            }
        }
        return true
    }
    
    
    
    // VERIFY REQUIREMENTS
    
    private static func verifyWithRequirementString(secCode: SecCode) -> Bool {
        // accetta connessioni XPC solo da app legittime
        let requirementString = "anchor apple generic and certificate leaf[subject.OU] = RNLG254GCK" as NSString
        
        var secRequirement: SecRequirement? = nil
        if SecRequirementCreateWithString(requirementString as CFString, SecCSFlags(rawValue: 0), &secRequirement) != errSecSuccess {
            // NSLog("Couldn't create the requirement string")
            return false
        }
        
        if SecCodeCheckValidity(secCode, SecCSFlags(rawValue: 0), secRequirement) != errSecSuccess {
            // NSLog("NSXPC client does not meet the requirements")
            return false
        }
        
        return true
    }
    
    
    
}



