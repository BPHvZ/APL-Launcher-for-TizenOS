import Foundation
import Security

let request = try JSONSerialization.jsonObject(with: FileHandle.standardInput.readDataToEndOfFile()) as! [String: String]
guard let action = request["action"], let service = request["service"] else {
    fputs("Invalid Keychain request\n", stderr)
    exit(2)
}
let account = "APL Launcher"
let query: [String: Any] = [
    kSecClass as String: kSecClassGenericPassword,
    kSecAttrService as String: service,
    kSecAttrAccount as String: account
]

func respond(_ object: [String: String]) {
    let data = try! JSONSerialization.data(withJSONObject: object)
    print(String(data: data, encoding: .utf8)!)
}

switch action {
case "get":
    var attributes = query
    attributes[kSecReturnData as String] = true
    attributes[kSecMatchLimit as String] = kSecMatchLimitOne
    var item: CFTypeRef?
    let status = SecItemCopyMatching(attributes as CFDictionary, &item)
    if status == errSecItemNotFound {
        respond(["value": ""])
    } else if status == errSecSuccess, let data = item as? Data,
              let value = String(data: data, encoding: .utf8) {
        respond(["value": value])
    } else {
        fputs("Unable to read the API key from macOS Keychain\n", stderr)
        exit(1)
    }
case "set":
    guard let value = request["value"], !value.isEmpty else {
        fputs("Missing Keychain value\n", stderr)
        exit(2)
    }
    let data = Data(value.utf8)
    let update: [String: Any] = [kSecValueData as String: data]
    var status = SecItemUpdate(query as CFDictionary, update as CFDictionary)
    if status == errSecItemNotFound {
        var item = query
        item[kSecValueData as String] = data
        status = SecItemAdd(item as CFDictionary, nil)
    }
    guard status == errSecSuccess else {
        fputs("Unable to save the API key in macOS Keychain\n", stderr)
        exit(1)
    }
    respond(["saved": "true"])
case "delete":
    let status = SecItemDelete(query as CFDictionary)
    guard status == errSecSuccess || status == errSecItemNotFound else {
        fputs("Unable to remove the API key from macOS Keychain\n", stderr)
        exit(1)
    }
    respond(["deleted": "true"])
default:
    fputs("Unknown Keychain action\n", stderr)
    exit(2)
}
