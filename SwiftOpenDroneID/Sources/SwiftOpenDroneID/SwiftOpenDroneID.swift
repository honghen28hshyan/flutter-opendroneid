import Foundation

/// SwiftOpenDroneID - A Swift library for parsing OpenDroneID messages
/// 
/// This library provides data structures and parsing logic for OpenDroneID (Remote ID)
/// messages according to the ASTM F3411 specification.
///
/// Usage:
/// ```swift
/// let rawData: Data = ... // Raw message data from Bluetooth/WiFi
/// do {
///     let message = try ODIDMessageParser.parse(data: rawData)
///     switch message {
///     case let basicID as BasicIDMessage:
///         print("UAS ID: \(basicID.uasID)")
///     case let location as LocationMessage:
///         print("Location: \(location.latitude), \(location.longitude)")
///     default:
///         print("Other message type")
///     }
/// } catch {
///     print("Failed to parse message: \(error)")
/// }
/// ```

public struct SwiftOpenDroneID {
    public static let version = "1.0.0"
    
    /// Parse raw OpenDroneID message data
    /// - Parameter data: Raw message bytes (typically 25 bytes per message)
    /// - Returns: Parsed ODIDMessage
    /// - Throws: ODIDParsingError if parsing fails
    public static func parseMessage(data: Data) throws -> ODIDMessage {
        return try ODIDMessageParser.parse(data: data)
    }
    
    /// Parse raw OpenDroneID payload with metadata
    /// - Parameter payload: ODIDPayload containing raw data and metadata
    /// - Returns: ReceivedODIDMessage with parsed message and metadata
    /// - Throws: ODIDParsingError if parsing fails
    public static func parsePayload(_ payload: ODIDPayload) throws -> ReceivedODIDMessage {
        let message = try ODIDMessageParser.parse(data: payload.rawData)
        let receivedDate = Date(timeIntervalSince1970: TimeInterval(payload.receivedTimestamp) / 1000.0)
        return ReceivedODIDMessage(
            odidMessage: message,
            metadata: payload.metadata,
            receivedTimestamp: receivedDate
        )
    }
}
