import Foundation

enum StableIdentifier {
  static func make(_ components: [String]) -> UUID {
    let value = components.joined(separator: "\u{1F}")
    let bytes = Array(value.utf8)
    let first = fnv1a(bytes, seed: 0xcbf2_9ce4_8422_2325)
    let second = fnv1a(bytes.reversed(), seed: 0x8422_2325_cbf2_9ce4)
    var uuidBytes = withUnsafeBytes(of: first.bigEndian, Array.init)
    uuidBytes.append(contentsOf: withUnsafeBytes(of: second.bigEndian, Array.init))
    uuidBytes[6] = (uuidBytes[6] & 0x0F) | 0x50
    uuidBytes[8] = (uuidBytes[8] & 0x3F) | 0x80
    return UUID(
      uuid: (
        uuidBytes[0], uuidBytes[1], uuidBytes[2], uuidBytes[3],
        uuidBytes[4], uuidBytes[5], uuidBytes[6], uuidBytes[7],
        uuidBytes[8], uuidBytes[9], uuidBytes[10], uuidBytes[11],
        uuidBytes[12], uuidBytes[13], uuidBytes[14], uuidBytes[15]
      ))
  }

  private static func fnv1a<S: Sequence>(_ bytes: S, seed: UInt64) -> UInt64
  where S.Element == UInt8 {
    bytes.reduce(seed) { hash, byte in
      (hash ^ UInt64(byte)) &* 0x100_0000_01b3
    }
  }
}
