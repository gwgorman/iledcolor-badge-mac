import Foundation
import CoreBluetooth

final class Scanner: NSObject, CBCentralManagerDelegate, CBPeripheralDelegate {
    var central: CBCentralManager!
    var target: CBPeripheral?
    var pending = 0
    var finished = false
    var seen = Set<UUID>()
    var control: CBCharacteristic?
    var notifications: CBCharacteristic?
    var bulk: CBCharacteristic?
    var upload: [UInt8] = []
    var offset = 0
    var wrap: UInt32 = 0
    var chunkSize = 0
    var uploadState = ""
    func log(_ event: String, _ fields: [String: Any] = [:]) {
        var item = fields
        item["event"] = event
        item["time"] = ISO8601DateFormatter().string(from: Date())
        if let data = try? JSONSerialization.data(withJSONObject: item, options: [.sortedKeys]), let line = String(data: data, encoding: .utf8) { print(line); fflush(stdout) }
    }
    func start() {
        central = CBCentralManager(delegate: self, queue: .main)
        DispatchQueue.main.asyncAfter(deadline: .now() + (CommandLine.arguments.contains("--upload") ? 180 : 35)) { self.log("timeout"); self.finish(2) }
    }
    func finish(_ code: Int32) {
        guard !finished else { return }
        finished = true
        central.stopScan()
        if let p = target { central.cancelPeripheralConnection(p) }
        exit(code)
    }
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        log("state", ["state": central.state.rawValue, "authorization": CBManager.authorization.rawValue])
        if central.state == .poweredOn { central.scanForPeripherals(withServices: nil) }
        else if central.state == .unauthorized || central.state == .unsupported { finish(3) }
    }
    func centralManager(_ central: CBCentralManager, didDiscover p: CBPeripheral, advertisementData: [String : Any], rssi: NSNumber) {
        let name = advertisementData[CBAdvertisementDataLocalNameKey] as? String ?? p.name ?? ""
        if seen.insert(p.identifier).inserted || name.lowercased().contains("iled") {
            log("advertisement", ["name": name, "id": p.identifier.uuidString, "rssi": rssi, "advertisement": advertisementData.mapValues { value -> String in
                if let data = value as? Data { return data.map { String(format: "%02x", $0) }.joined() }
                return String(describing: value)
            }])
        }
        guard name.lowercased() == "iledcolor-012b", target == nil else { return }
        target = p; p.delegate = self; central.stopScan(); central.connect(p)
    }
    func centralManager(_ central: CBCentralManager, didConnect p: CBPeripheral) {
        log("connected", ["id": p.identifier.uuidString, "maxWriteWithResponse": p.maximumWriteValueLength(for: .withResponse), "maxWriteWithoutResponse": p.maximumWriteValueLength(for: .withoutResponse)])
        p.discoverServices(nil)
    }
    func centralManager(_ central: CBCentralManager, didFailToConnect p: CBPeripheral, error: Error?) { log("connection_error", ["error": String(describing: error)]); finish(4) }
    func peripheral(_ p: CBPeripheral, didDiscoverServices error: Error?) {
        if let error = error { log("service_error", ["error": error.localizedDescription]); finish(5); return }
        let services = p.services ?? []; pending = services.count
        for s in services { log("service", ["uuid": s.uuid.uuidString, "primary": s.isPrimary]); p.discoverCharacteristics(nil, for: s) }
        if pending == 0 { finish(0) }
    }
    func peripheral(_ p: CBPeripheral, didDiscoverCharacteristicsFor s: CBService, error: Error?) {
        if let error = error { log("characteristic_error", ["service": s.uuid.uuidString, "error": error.localizedDescription]) }
        for c in s.characteristics ?? [] {
            if s.uuid == CBUUID(string: "A950") && c.uuid == CBUUID(string: "A951") { control = c }
            if s.uuid == CBUUID(string: "A950") && c.uuid == CBUUID(string: "A953") { notifications = c }
            if s.uuid == CBUUID(string: "A950") && c.uuid == CBUUID(string: "A952") { bulk = c }
            let flags: [(CBCharacteristicProperties, String)] = [(.broadcast,"broadcast"),(.read,"read"),(.writeWithoutResponse,"writeWithoutResponse"),(.write,"write"),(.notify,"notify"),(.indicate,"indicate"),(.authenticatedSignedWrites,"signedWrite"),(.extendedProperties,"extended"),(.notifyEncryptionRequired,"notifyEncryptionRequired"),(.indicateEncryptionRequired,"indicateEncryptionRequired")]
            log("characteristic", ["service": s.uuid.uuidString, "uuid": c.uuid.uuidString, "propertiesRaw": c.properties.rawValue, "properties": flags.filter { c.properties.contains($0.0) }.map { $0.1 }])
        }
        pending -= 1
        if pending == 0 {
            log("enumeration_complete")
            if (CommandLine.arguments.contains("--probe") || CommandLine.arguments.contains("--brightness") || CommandLine.arguments.contains("--test-solid") || CommandLine.arguments.contains("--upload")), let c = notifications { p.setNotifyValue(true, for: c) }
            else { finish(0) }
        }
    }
    func peripheral(_ p: CBPeripheral, didUpdateNotificationStateFor c: CBCharacteristic, error: Error?) {
        log("notification_state", ["uuid": c.uuid.uuidString, "enabled": c.isNotifying, "error": String(describing: error)])
        guard error == nil, c.isNotifying, let control = control else { finish(6); return }
        if CommandLine.arguments.contains("--test-solid") || CommandLine.arguments.contains("--upload") {
            guard bulk != nil else { finish(6); return }
            var program = BadgeProtocol.solidTestProgram()
            if let index = CommandLine.arguments.firstIndex(of: "--upload") {
                guard index+1 < CommandLine.arguments.count else { finish(7); return }
                do { program = try BadgeProtocol.animationProgram(path: CommandLine.arguments[index+1]) }
                catch { log("input_error", ["error": String(describing: error)]); finish(7); return }
            }
            upload = program.bytes
            chunkSize = min(492, p.maximumWriteValueLength(for: .withoutResponse) - 12)
            guard chunkSize > 0 else { finish(8); return }
            uploadState = "announce"
            send(p, control, BadgeProtocol.frame(command: 6, payload: BadgeProtocol.u32(program.id) + BadgeProtocol.u32(UInt32(upload.count)) + [0,0,0]))
            return
        }
        // Published candidate: query built-in animation count. Does not alter display or storage.
        var packet = BadgeProtocol.frame(command: 0x0d, payload: [0])
        var purpose = "candidate built-in count query"
        if let index = CommandLine.arguments.firstIndex(of: "--brightness") {
            guard index + 1 < CommandLine.arguments.count, let percent = UInt8(CommandLine.arguments[index + 1]), percent <= 100 else { log("argument_error"); finish(7); return }
            packet = BadgeProtocol.frame(command: 0x09, payload: [percent])
            purpose = "candidate brightness \(percent) percent"
        }
        log("write", ["uuid": control.uuid.uuidString, "hex": packet.map { String(format: "%02x", $0) }.joined(), "purpose": purpose])
        p.writeValue(packet, for: control, type: .withoutResponse)
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) { self.finish(0) }
    }
    func peripheral(_ p: CBPeripheral, didUpdateValueFor c: CBCharacteristic, error: Error?) {
        log("notification", ["uuid": c.uuid.uuidString, "hex": (c.value ?? Data()).map { String(format: "%02x", $0) }.joined(), "error": String(describing: error)])
        guard !uploadState.isEmpty, error == nil, c.uuid == CBUUID(string: "A953"), let value = c.value else { return }
        let b = Array(value)
        guard b.count >= 7, b[0] == 0x54 else { return }
        let checksum = b.dropLast(2).reduce(0) { ($0 + Int($1)) & 65535 }
        guard checksum == Int(b[b.count-2]) * 256 + Int(b[b.count-1]) else { log("bad_checksum"); finish(9); return }
        if uploadState == "announce", b[1] == 6 {
            guard b[4] == 1 else { log("announce_status", ["status": b[4]]); finish(10); return }
            uploadState = "fragment"; sendFragment(p)
        } else if uploadState == "fragment", b[1] == 0, b.count == 11 {
            let ackWrap = b[4..<8].reduce(UInt32(0)) { ($0 << 8) | UInt32($1) }
            guard ackWrap == wrap else { return }
            guard b[8] == 1 else { log("fragment_failed"); finish(11); return }
            offset += min(chunkSize, upload.count-offset); wrap += 1
            if offset < upload.count { sendFragment(p) }
            else { uploadState = "complete"; send(p, bulk!, BadgeProtocol.frame(command: 1, payload: [1])) }
        } else if uploadState == "complete", b[1] == 1 {
            guard b[4] == 1 else { finish(12); return }
            log("upload_acknowledged", ["physical_result": "requires visual verification"]); finish(0)
        }
    }
    func send(_ p: CBPeripheral, _ c: CBCharacteristic, _ data: Data) {
        log("write", ["uuid": c.uuid.uuidString, "hex": data.map { String(format: "%02x", $0) }.joined()])
        p.writeValue(data, for: c, type: .withoutResponse)
    }
    func sendFragment(_ p: CBPeripheral) {
        let chunk = Array(upload[offset..<min(offset+chunkSize, upload.count)])
        send(p, bulk!, BadgeProtocol.frame(command: 0, payload: BadgeProtocol.u32(wrap) + [UInt8(chunk.count >> 8), UInt8(chunk.count & 255)] + chunk))
    }
}
@main struct BadgeTool {
    static func main() {
        let scanner = Scanner()
        scanner.start()
        RunLoop.main.run()
    }
}
