import AccessorySetupKit

protocol UniversalBlePluginExtention {
    func getKnownDevices(withIdentifiers: [String], completion: @escaping (Result<[UniversalBleScanResult], Error>) -> Void)
    func invalidate()
}

class UniversalBlePluginExtNoASK: UniversalBlePluginExtention {
    func getKnownDevices(withIdentifiers: [String], completion: @escaping (Result<[UniversalBleScanResult], Error>) -> Void) {
        completion(Result.success([]))
    }

    func invalidate() {}
}

@available(iOS 18.0, *)
class UniversalBlePluginExtASK: UniversalBlePluginExtention {

    var session: ASAccessorySession?

    func getKnownDevices(withIdentifiers: [String], completion: @escaping (Result<[UniversalBleScanResult], Error>) -> Void) {
        session = ASAccessorySession()

        var sessionAccessories: [ASAccessory]?
        let eventQueue = DispatchQueue(label: "com.lifeq.universal_ble.accessoryEvents")
        session!.activate(on: eventQueue) { event in
            switch(event.eventType) {
            case .activated:
                sessionAccessories = self.session!.accessories.compactMap { accessory in
                guard let id = accessory.bluetoothIdentifier?.uuidString else { return nil }
                    return withIdentifiers.contains(id) ? accessory : nil
                }
                if let accessories = sessionAccessories, accessories.count > 0  {             
                    completion(Result.success(accessories.map { accessory in
                    return UniversalBleScanResult(
                        deviceId: accessory.bluetoothIdentifier!.uuidString,
                        name: accessory.displayName
                    )
                    }))
                } else {
                    completion(Result.success([]))
                }
            default:
                print("unhandled event")
            }
        }
    }

    func invalidate() {
        session?.invalidate()
        session = nil
    }
}


extension ASAccessoryEventType {
    var stringValue: String {
        switch self {
        case .accessoryAdded:
            return "accessoryAdded"
        case .accessoryChanged:
            return "accessoryChanged"
        case .accessoryRemoved:
            return "accessoryRemoved"
        case .activated:
            return "activated"
        case .invalidated:
            return "invalidated"
        // case .accessoryDiscovered:
        //     return "accessoryDiscovered"
        case .pickerDidPresent:
            return "pickerDidPresent"
        case .pickerDidDismiss:
            return "pickerDidDismiss"
        case .pickerSetupBridging:
            return "pickerSetupBridging"
        case .pickerSetupPairing:
            return "pickerSetupPairing"
        case .pickerSetupFailed:
            return "pickerSetupFailed"
        case .pickerSetupRename:
            return "pickerSetupRename"
        case .migrationComplete:
            return "migrationComplete"
        @unknown default:
            return "unknown"
        }
    }
}
