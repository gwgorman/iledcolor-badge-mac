import Foundation

// Candidate wire format from set4npl/ledsign. Only operations with badge traces
// and physical confirmation may be described as verified.
enum BadgeProtocol {
    struct Animation: Decodable {
        let width: Int
        let height: Int
        let frameMs: Int
        let frames: [[String]]
        let packing: String?
    }
    static func animationProgram(path: String) throws -> (bytes: [UInt8], id: UInt32) {
        let a = try JSONDecoder().decode(Animation.self, from: Data(contentsOf: URL(fileURLWithPath: path)))
        guard a.width == 48, a.height == 12, a.frameMs >= 20, a.frameMs <= 5100, a.frameMs % 20 == 0, !a.frames.isEmpty, a.frames.count <= 65535 else { throw NSError(domain: "Invalid 48x12 animation or timing", code: 1) }
        var content: [UInt8] = []
        for rows in a.frames {
            guard rows.count == 12, rows.allSatisfy({ $0.count == 48 && $0.allSatisfy({ $0 == "0" || $0 == "1" }) }) else { throw NSError(domain: "Each frame needs twelve 48-character binary rows", code: 1) }
            if a.packing == nil || a.packing == "column16" {
                let grid = rows.map(Array.init)
                for x in 0..<48 {
                    for startY in [0,8] {
                        var byte: UInt8 = 0
                        for bit in 0..<8 where startY+bit < 12 && grid[startY+bit][x] == "1" { byte |= 1 << (7-bit) }
                        content.append(byte)
                    }
                }
            } else {
            for row in rows {
                let pixels = Array(row)
                for x in stride(from: 0, to: 48, by: 8) {
                    var byte: UInt8 = 0
                    for bit in 0..<8 where pixels[x+bit] == "1" { byte |= 1 << (7-bit) }
                    content.append(byte)
                }
            }
            }
            // The RGB reference's two-byte frame suffix shifts monochrome
            // frames by one column. Column16 frames are exactly 96 bytes.
            if a.frames.count > 1 && a.packing == "row" { content += [0,1] }
        }
        let n = a.frames.count
        let partition: [UInt8] = [0,0,0,0,0,48,0,12,0,0,0,n > 1 ? 2 : 1,UInt8(n >> 8),UInt8(n & 255),0,0,UInt8(a.frameMs/20),0,30,0,0,0] + content
        return package(partition)
    }
    static func package(_ partition: [UInt8]) -> (bytes: [UInt8], id: UInt32) {
        var crc: UInt32 = 0xffffffff
        for byte in partition {
            crc ^= UInt32(byte)
            for _ in 0..<8 { crc = (crc >> 1) ^ ((crc & 1) == 1 ? 0x82f63b78 : 0) }
        }
        crc ^= 0xffffffff
        return (u32(crc) + [1,0,0,0] + Array(repeating: 0, count: 16) + partition, crc)
    }
    static func u32(_ n: UInt32) -> [UInt8] { [UInt8(n >> 24), UInt8((n >> 16) & 255), UInt8((n >> 8) & 255), UInt8(n & 255)] }
    static func solidTestProgram() -> (bytes: [UInt8], id: UInt32) {
        // Verified spatial packing: two vertical MSB-first bytes per column.
        let pixels = (0..<48).flatMap { _ -> [UInt8] in [255,240] }
        let partition: [UInt8] = [0,0,0,0,0,48,0,12,0,0,0,1,0,1,0,0,5,0,30,0,0,0] + pixels
        return package(partition)
    }
    static func frame(command: UInt8, payload: [UInt8]) -> Data {
        precondition(payload.count <= 65533)
        let length = payload.count + 2
        var bytes: [UInt8] = [0x54, command, UInt8(length >> 8), UInt8(length & 255)] + payload
        let checksum = bytes.reduce(0) { ($0 + Int($1)) & 65535 }
        bytes += [UInt8(checksum >> 8), UInt8(checksum & 255)]
        return Data(bytes)
    }
}
