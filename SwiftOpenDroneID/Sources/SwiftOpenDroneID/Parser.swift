import Foundation

/// Errors that can occur during message parsing
public enum ODIDParsingError: Error {
    case invalidMessageLength
    case invalidMessageType
    case invalidData
    case unsupportedMessageType
    case corruptedData
}

/// Parser for OpenDroneID messages according to ASTM F3411 specification
public class ODIDMessageParser {
    
    /// Parse OpenDroneID message from raw data
    /// - Parameter data: Raw message data (25 bytes for single message)
    /// - Returns: Parsed ODID message
    /// - Throws: ODIDParsingError if parsing fails
    public static func parse(data: Data) throws -> ODIDMessage {
        guard data.count >= 25 else {
            throw ODIDParsingError.invalidMessageLength
        }
        
        let messageTypeByte = data[0]
        guard let messageType = MessageType(rawValue: messageTypeByte) else {
            throw ODIDParsingError.invalidMessageType
        }
        
        switch messageType {
        case .basicID:
            return try parseBasicID(data: data)
        case .location:
            return try parseLocation(data: data)
        case .auth:
            return try parseAuth(data: data)
        case .selfID:
            return try parseSelfID(data: data)
        case .system:
            return try parseSystem(data: data)
        case .operatorID:
            return try parseOperatorID(data: data)
        case .messagePack:
            return try parseMessagePack(data: data)
        case .invalid:
            throw ODIDParsingError.invalidMessageType
        }
    }
    
    // MARK: - Basic ID Message Parsing
    
    private static func parseBasicID(data: Data) throws -> BasicIDMessage {
        guard data.count >= 25 else {
            throw ODIDParsingError.invalidMessageLength
        }
        
        let idTypeByte = (data[1] >> 4) & 0x0F
        let uaTypeByte = data[1] & 0x0F
        
        guard let idType = IDType(rawValue: idTypeByte),
              let uaType = UAType(rawValue: uaTypeByte) else {
            throw ODIDParsingError.invalidData
        }
        
        // UAS ID is 20 bytes starting at offset 2
        let uasIDData = data.subdata(in: 2..<22)
        let uasID = String(data: uasIDData, encoding: .ascii)?
            .trimmingCharacters(in: CharacterSet(charactersIn: "\0")) ?? ""
        
        return BasicIDMessage(uaType: uaType, idType: idType, uasID: uasID)
    }
    
    // MARK: - Location Message Parsing
    
    private static func parseLocation(data: Data) throws -> LocationMessage {
        guard data.count >= 25 else {
            throw ODIDParsingError.invalidMessageLength
        }
        
        let statusByte = (data[1] >> 4) & 0x0F
        let heightTypeByte = (data[1] >> 2) & 0x01
        // let ewDirectionBit = (data[1] >> 1) & 0x01 // Reserved for future use
        let speedMultiplier = data[1] & 0x01
        
        guard let status = OperationalStatus(rawValue: statusByte),
              let heightType = HeightType(rawValue: heightTypeByte) else {
            throw ODIDParsingError.invalidData
        }
        
        // Direction (1 byte)
        let directionByte = data[2]
        let direction: Double? = directionByte != 0xFF ? Double(directionByte) : nil
        
        // Speed horizontal (1 byte)
        let speedHByte = data[3]
        let speedH: Double? = speedHByte != 0xFF ? Double(speedHByte) * (speedMultiplier == 1 ? 0.75 : 0.25) : nil
        
        // Speed vertical (1 byte, signed)
        let speedVByte = Int8(bitPattern: data[4])
        let speedV: Double? = speedVByte != -128 ? Double(speedVByte) * (speedMultiplier == 1 ? 0.75 : 0.25) : nil
        
        // Latitude (4 bytes, signed)
        let latInt = Int32(data[5]) | (Int32(data[6]) << 8) | (Int32(data[7]) << 16) | (Int32(data[8]) << 24)
        let latitude = Double(latInt) * 1e-7
        
        // Longitude (4 bytes, signed)
        let lonInt = Int32(data[9]) | (Int32(data[10]) << 8) | (Int32(data[11]) << 16) | (Int32(data[12]) << 24)
        let longitude = Double(lonInt) * 1e-7
        
        // Pressure altitude (2 bytes)
        let pressAltInt = UInt16(data[13]) | (UInt16(data[14]) << 8)
        let pressureAltitude: Double? = pressAltInt != 0xFFFF ? Double(Int16(bitPattern: pressAltInt)) * 0.5 - 1000.0 : nil
        
        // Geodetic altitude (2 bytes)
        let geoAltInt = UInt16(data[15]) | (UInt16(data[16]) << 8)
        let geodeticalAltitude: Double? = geoAltInt != 0xFFFF ? Double(Int16(bitPattern: geoAltInt)) * 0.5 - 1000.0 : nil
        
        // Height (2 bytes)
        let heightInt = UInt16(data[17]) | (UInt16(data[18]) << 8)
        let height: Double? = heightInt != 0xFFFF ? Double(Int16(bitPattern: heightInt)) * 0.5 - 1000.0 : nil
        
        // Accuracies (1 byte)
        let accByte = data[19]
        let hAcc = (accByte >> 4) & 0x0F
        let vAcc = accByte & 0x0F
        
        guard let horizontalAccuracy = HorizontalAccuracy(rawValue: hAcc),
              let verticalAccuracy = VerticalAccuracy(rawValue: vAcc) else {
            throw ODIDParsingError.invalidData
        }
        
        // Baro and speed accuracy (1 byte)
        let acc2Byte = data[20]
        let baroAcc = (acc2Byte >> 4) & 0x0F
        let speedAcc = acc2Byte & 0x0F
        
        guard let baroAccuracy = VerticalAccuracy(rawValue: baroAcc),
              let speedAccuracy = SpeedAccuracy(rawValue: speedAcc) else {
            throw ODIDParsingError.invalidData
        }
        
        // Timestamp (2 bytes, tenths of seconds)
        let timestampInt = UInt16(data[21]) | (UInt16(data[22]) << 8)
        let timestamp: Double? = timestampInt != 0xFFFF ? Double(timestampInt) * 0.1 : nil
        
        // Timestamp accuracy (1 byte, high nibble)
        let tsAccByte = (data[23] >> 4) & 0x0F
        guard let timestampAccuracy = TimestampAccuracy(rawValue: tsAccByte) else {
            throw ODIDParsingError.invalidData
        }
        
        return LocationMessage(
            status: status,
            heightType: heightType,
            direction: direction,
            speedHorizontal: speedH,
            speedVertical: speedV,
            latitude: latitude,
            longitude: longitude,
            pressureAltitude: pressureAltitude,
            geodeticalAltitude: geodeticalAltitude,
            height: height,
            horizontalAccuracy: horizontalAccuracy,
            verticalAccuracy: verticalAccuracy,
            baroAccuracy: baroAccuracy,
            speedAccuracy: speedAccuracy,
            timestamp: timestamp,
            timestampAccuracy: timestampAccuracy
        )
    }
    
    // MARK: - Self ID Message Parsing
    
    private static func parseSelfID(data: Data) throws -> SelfIDMessage {
        guard data.count >= 25 else {
            throw ODIDParsingError.invalidMessageLength
        }
        
        let descriptionType = data[1]
        
        // Operation description is 23 bytes starting at offset 2
        let descData = data.subdata(in: 2..<25)
        let operationDescription = String(data: descData, encoding: .utf8)?
            .trimmingCharacters(in: CharacterSet(charactersIn: "\0")) ?? ""
        
        return SelfIDMessage(descriptionType: descriptionType, operationDescription: operationDescription)
    }
    
    // MARK: - System Message Parsing
    
    private static func parseSystem(data: Data) throws -> SystemMessage {
        guard data.count >= 25 else {
            throw ODIDParsingError.invalidMessageLength
        }
        
        let opLocTypeByte = (data[1] >> 4) & 0x0F
        let classTypeByte = data[1] & 0x0F
        
        guard let operatorLocationType = OperatorLocationType(rawValue: opLocTypeByte),
              let classificationType = ClassificationType(rawValue: classTypeByte) else {
            throw ODIDParsingError.invalidData
        }
        
        // Operator latitude (4 bytes)
        let opLatInt = Int32(data[2]) | (Int32(data[3]) << 8) | (Int32(data[4]) << 16) | (Int32(data[5]) << 24)
        let operatorLatitude: Double? = opLatInt != 0 ? Double(opLatInt) * 1e-7 : nil
        
        // Operator longitude (4 bytes)
        let opLonInt = Int32(data[6]) | (Int32(data[7]) << 8) | (Int32(data[8]) << 16) | (Int32(data[9]) << 24)
        let operatorLongitude: Double? = opLonInt != 0 ? Double(opLonInt) * 1e-7 : nil
        
        // Area count (1 byte)
        let areaCount: UInt8? = data[10] != 0xFF ? data[10] : nil
        
        // Area radius (1 byte)
        let areaRadius: UInt8? = data[11] != 0xFF ? data[11] : nil
        
        // Area ceiling (2 bytes)
        let areaCeilInt = UInt16(data[12]) | (UInt16(data[13]) << 8)
        let areaCeiling: Double? = areaCeilInt != 0xFFFF ? Double(Int16(bitPattern: areaCeilInt)) * 0.5 - 1000.0 : nil
        
        // Area floor (2 bytes)
        let areaFloorInt = UInt16(data[14]) | (UInt16(data[15]) << 8)
        let areaFloor: Double? = areaFloorInt != 0xFFFF ? Double(Int16(bitPattern: areaFloorInt)) * 0.5 - 1000.0 : nil
        
        // Category and class (1 byte)
        let catClassByte = data[16]
        let catByte = (catClassByte >> 4) & 0x0F
        let classByte = catClassByte & 0x0F
        
        let category = EUCategory(rawValue: catByte)
        let classValue = EUClass(rawValue: classByte)
        
        // Operator altitude geo (2 bytes)
        let opAltInt = UInt16(data[17]) | (UInt16(data[18]) << 8)
        let operatorAltitudeGeo: Double? = opAltInt != 0xFFFF ? Double(Int16(bitPattern: opAltInt)) * 0.5 - 1000.0 : nil
        
        // Timestamp (4 bytes)
        let timestamp = UInt32(data[19]) | (UInt32(data[20]) << 8) | (UInt32(data[21]) << 16) | (UInt32(data[22]) << 24)
        
        return SystemMessage(
            operatorLocationType: operatorLocationType,
            classificationType: classificationType,
            operatorLatitude: operatorLatitude,
            operatorLongitude: operatorLongitude,
            areaCount: areaCount,
            areaRadius: areaRadius,
            areaCeiling: areaCeiling,
            areaFloor: areaFloor,
            category: category,
            classValue: classValue,
            operatorAltitudeGeo: operatorAltitudeGeo,
            timestamp: timestamp != 0xFFFFFFFF ? timestamp : nil
        )
    }
    
    // MARK: - Operator ID Message Parsing
    
    private static func parseOperatorID(data: Data) throws -> OperatorIDMessage {
        guard data.count >= 25 else {
            throw ODIDParsingError.invalidMessageLength
        }
        
        let operatorIdType = data[1]
        
        // Operator ID is 20 bytes starting at offset 2
        let opIDData = data.subdata(in: 2..<22)
        let operatorId = String(data: opIDData, encoding: .ascii)?
            .trimmingCharacters(in: CharacterSet(charactersIn: "\0")) ?? ""
        
        return OperatorIDMessage(operatorIdType: operatorIdType, operatorId: operatorId)
    }
    
    // MARK: - Authentication Message Parsing
    
    private static func parseAuth(data: Data) throws -> AuthMessage {
        guard data.count >= 25 else {
            throw ODIDParsingError.invalidMessageLength
        }
        
        let authTypeByte = (data[1] >> 4) & 0x0F
        guard let authType = AuthType(rawValue: authTypeByte) else {
            throw ODIDParsingError.invalidData
        }
        
        let dataPage = data[2]
        let lastPageIndex = data[3]
        let length = data[4]
        
        // Timestamp (4 bytes)
        let timestamp = UInt32(data[5]) | (UInt32(data[6]) << 8) | (UInt32(data[7]) << 16) | (UInt32(data[8]) << 24)
        
        // Authentication data (remaining bytes)
        let authData = data.subdata(in: 9..<min(data.count, 25))
        
        return AuthMessage(
            authType: authType,
            dataPage: dataPage,
            lastPageIndex: lastPageIndex,
            length: length,
            timestamp: timestamp,
            authData: authData
        )
    }
    
    // MARK: - Message Pack Parsing
    
    private static func parseMessagePack(data: Data) throws -> MessagePackMessage {
        guard data.count >= 25 else {
            throw ODIDParsingError.invalidMessageLength
        }
        
        var messages: [ODIDMessage] = []
        
        // Message pack contains single message count in byte 1
        let messageCount = data[1]
        
        // Each message is 25 bytes, starting from byte 2
        var offset = 2
        for _ in 0..<messageCount {
            guard offset + 25 <= data.count else {
                break
            }
            
            let messageData = data.subdata(in: offset..<(offset + 25))
            
            do {
                let message = try parse(data: messageData)
                messages.append(message)
            } catch {
                // Skip invalid messages in pack
            }
            
            offset += 25
        }
        
        return MessagePackMessage(messages: messages)
    }
}
