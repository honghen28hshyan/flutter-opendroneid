import XCTest
@testable import SwiftOpenDroneID

final class SwiftOpenDroneIDTests: XCTestCase {
    
    // MARK: - Basic ID Tests
    
    func testParseBasicIDMessage() throws {
        // Create test data for Basic ID message
        var data = Data(count: 25)
        data[0] = 0x00 // Message type: Basic ID
        data[1] = 0x21 // ID Type: 2 (CAA Registration), UA Type: 1 (Aeroplane)
        
        // UAS ID "TEST123" padded with nulls
        let uasID = "TEST123"
        let uasIDData = uasID.data(using: .ascii)!
        data.replaceSubrange(2..<(2 + uasIDData.count), with: uasIDData)
        
        let message = try ODIDMessageParser.parse(data: data)
        
        XCTAssertTrue(message is BasicIDMessage)
        let basicID = message as! BasicIDMessage
        
        XCTAssertEqual(basicID.messageType, .basicID)
        XCTAssertEqual(basicID.idType, .cadRegistrationID)
        XCTAssertEqual(basicID.uaType, .aeroplane)
        XCTAssertEqual(basicID.uasID, "TEST123")
    }
    
    func testParseBasicIDWithSerialNumber() throws {
        var data = Data(count: 25)
        data[0] = 0x00 // Message type: Basic ID
        data[1] = 0x12 // ID Type: 1 (Serial Number), UA Type: 2 (Helicopter)
        
        let serialNumber = "ABC123XYZ789"
        let serialData = serialNumber.data(using: .ascii)!
        data.replaceSubrange(2..<(2 + serialData.count), with: serialData)
        
        let message = try ODIDMessageParser.parse(data: data)
        let basicID = message as! BasicIDMessage
        
        XCTAssertEqual(basicID.idType, .serialNumber)
        XCTAssertEqual(basicID.uaType, .helicopterOrMultirotor)
        XCTAssertEqual(basicID.uasID, "ABC123XYZ789")
    }
    
    // MARK: - Location Tests
    
    func testParseLocationMessage() throws {
        var data = Data(count: 25)
        data[0] = 0x01 // Message type: Location
        data[1] = 0x20 // Status: 2 (Airborne), Height type: 0, EW: 0, Speed mult: 0
        data[2] = 180 // Direction: 180 degrees
        data[3] = 40 // Speed horizontal: 10 m/s (40 * 0.25)
        data[4] = UInt8(bitPattern: Int8(-128)) // Speed vertical: invalid
        
        // Latitude: 50.0 degrees (500000000 in 1e-7 units)
        let latInt: Int32 = 500000000
        data[5] = UInt8(latInt & 0xFF)
        data[6] = UInt8((latInt >> 8) & 0xFF)
        data[7] = UInt8((latInt >> 16) & 0xFF)
        data[8] = UInt8((latInt >> 24) & 0xFF)
        
        // Longitude: 14.0 degrees (140000000 in 1e-7 units)
        let lonInt: Int32 = 140000000
        data[9] = UInt8(lonInt & 0xFF)
        data[10] = UInt8((lonInt >> 8) & 0xFF)
        data[11] = UInt8((lonInt >> 16) & 0xFF)
        data[12] = UInt8((lonInt >> 24) & 0xFF)
        
        // Pressure altitude: 100m -> (100 + 1000) / 0.5 = 2200
        let pressAlt: UInt16 = 2200
        data[13] = UInt8(pressAlt & 0xFF)
        data[14] = UInt8((pressAlt >> 8) & 0xFF)
        
        // Geodetic altitude: 150m -> (150 + 1000) / 0.5 = 2300
        let geoAlt: UInt16 = 2300
        data[15] = UInt8(geoAlt & 0xFF)
        data[16] = UInt8((geoAlt >> 8) & 0xFF)
        
        // Height: 50m -> (50 + 1000) / 0.5 = 2100
        let height: UInt16 = 2100
        data[17] = UInt8(height & 0xFF)
        data[18] = UInt8((height >> 8) & 0xFF)
        
        data[19] = 0x36 // H Acc: 3 (<1m), V Acc: 6 (<1m)
        data[20] = 0x22 // Baro Acc: 2 (<25m), Speed Acc: 2 (<1m/s)
        
        // Timestamp: 600.5 seconds -> 6005 in tenths
        let timestamp: UInt16 = 6005
        data[21] = UInt8(timestamp & 0xFF)
        data[22] = UInt8((timestamp >> 8) & 0xFF)
        
        data[23] = 0x30 // Timestamp accuracy: 3 (<0.4s)
        
        let message = try ODIDMessageParser.parse(data: data)
        
        XCTAssertTrue(message is LocationMessage)
        let location = message as! LocationMessage
        
        XCTAssertEqual(location.messageType, .location)
        XCTAssertEqual(location.status, .airborne)
        XCTAssertEqual(location.direction, 180.0)
        XCTAssertEqual(location.speedHorizontal!, 10.0, accuracy: 0.1)
        XCTAssertNil(location.speedVertical)
        XCTAssertEqual(location.latitude, 50.0, accuracy: 0.0000001)
        XCTAssertEqual(location.longitude, 14.0, accuracy: 0.0000001)
        XCTAssertEqual(location.pressureAltitude!, 100.0, accuracy: 0.1)
        XCTAssertEqual(location.geodeticalAltitude!, 150.0, accuracy: 0.1)
        XCTAssertEqual(location.height!, 50.0, accuracy: 0.1)
        XCTAssertEqual(location.horizontalAccuracy, .lessThan1m)
        XCTAssertEqual(location.verticalAccuracy, .lessThan1m)
        XCTAssertEqual(location.timestamp!, 600.5, accuracy: 0.1)
    }
    
    // MARK: - Self ID Tests
    
    func testParseSelfIDMessage() throws {
        var data = Data(count: 25)
        data[0] = 0x03 // Message type: Self ID
        data[1] = 0x00 // Description type: 0 (Text)
        
        let description = "Test Flight"
        let descData = description.data(using: .utf8)!
        data.replaceSubrange(2..<(2 + descData.count), with: descData)
        
        let message = try ODIDMessageParser.parse(data: data)
        
        XCTAssertTrue(message is SelfIDMessage)
        let selfID = message as! SelfIDMessage
        
        XCTAssertEqual(selfID.messageType, .selfID)
        XCTAssertEqual(selfID.descriptionType, 0)
        XCTAssertEqual(selfID.operationDescription, "Test Flight")
    }
    
    // MARK: - System Tests
    
    func testParseSystemMessage() throws {
        var data = Data(count: 25)
        data[0] = 0x04 // Message type: System
        data[1] = 0x11 // Operator location type: 1 (Live GNSS), Classification: 1 (EU)
        
        // Operator latitude: 51.5 degrees
        let opLatInt: Int32 = 515000000
        data[2] = UInt8(opLatInt & 0xFF)
        data[3] = UInt8((opLatInt >> 8) & 0xFF)
        data[4] = UInt8((opLatInt >> 16) & 0xFF)
        data[5] = UInt8((opLatInt >> 24) & 0xFF)
        
        // Operator longitude: -0.1 degrees
        let opLonInt: Int32 = -1000000
        data[6] = UInt8(opLonInt & 0xFF)
        data[7] = UInt8((opLonInt >> 8) & 0xFF)
        data[8] = UInt8((opLonInt >> 16) & 0xFF)
        data[9] = UInt8((opLonInt >> 24) & 0xFF)
        
        data[10] = 1 // Area count
        data[11] = 5 // Area radius: 500m
        
        // Area ceiling: 120m
        let ceiling: UInt16 = UInt16(bitPattern: Int16((120.0 + 1000.0) / 0.5))
        data[12] = UInt8(ceiling & 0xFF)
        data[13] = UInt8((ceiling >> 8) & 0xFF)
        
        // Area floor: 0m
        let floor: UInt16 = UInt16(bitPattern: Int16((0.0 + 1000.0) / 0.5))
        data[14] = UInt8(floor & 0xFF)
        data[15] = UInt8((floor >> 8) & 0xFF)
        
        data[16] = 0x11 // Category: 1 (Open), Class: 1 (Class 0)
        
        // Operator altitude: 10m
        let opAlt: UInt16 = UInt16(bitPattern: Int16((10.0 + 1000.0) / 0.5))
        data[17] = UInt8(opAlt & 0xFF)
        data[18] = UInt8((opAlt >> 8) & 0xFF)
        
        // Timestamp
        let timestamp: UInt32 = 1234567890
        data[19] = UInt8(timestamp & 0xFF)
        data[20] = UInt8((timestamp >> 8) & 0xFF)
        data[21] = UInt8((timestamp >> 16) & 0xFF)
        data[22] = UInt8((timestamp >> 24) & 0xFF)
        
        let message = try ODIDMessageParser.parse(data: data)
        
        XCTAssertTrue(message is SystemMessage)
        let system = message as! SystemMessage
        
        XCTAssertEqual(system.messageType, .system)
        XCTAssertEqual(system.operatorLocationType, .liveGNSS)
        XCTAssertEqual(system.classificationType, .eu)
        XCTAssertEqual(system.operatorLatitude!, 51.5, accuracy: 0.0000001)
        XCTAssertEqual(system.operatorLongitude!, -0.1, accuracy: 0.0000001)
        XCTAssertEqual(system.areaCount, 1)
        XCTAssertEqual(system.areaRadius, 5)
        XCTAssertEqual(system.category, .open)
        XCTAssertEqual(system.classValue, .class0)
    }
    
    // MARK: - Operator ID Tests
    
    func testParseOperatorIDMessage() throws {
        var data = Data(count: 25)
        data[0] = 0x05 // Message type: Operator ID
        data[1] = 0x01 // Operator ID type
        
        let operatorID = "OP123456"
        let opIDData = operatorID.data(using: .ascii)!
        data.replaceSubrange(2..<(2 + opIDData.count), with: opIDData)
        
        let message = try ODIDMessageParser.parse(data: data)
        
        XCTAssertTrue(message is OperatorIDMessage)
        let opID = message as! OperatorIDMessage
        
        XCTAssertEqual(opID.messageType, .operatorID)
        XCTAssertEqual(opID.operatorIdType, 0x01)
        XCTAssertEqual(opID.operatorId, "OP123456")
    }
    
    // MARK: - Error Tests
    
    func testInvalidMessageLength() {
        let data = Data(count: 10) // Too short
        
        XCTAssertThrowsError(try ODIDMessageParser.parse(data: data))
    }
    
    func testInvalidMessageType() {
        var data = Data(count: 25)
        data[0] = 0xFF // Invalid message type
        
        XCTAssertThrowsError(try ODIDMessageParser.parse(data: data))
    }
    
    // MARK: - Integration Tests
    
    func testParsePayload() throws {
        var data = Data(count: 25)
        data[0] = 0x00 // Message type: Basic ID
        data[1] = 0x11 // ID Type: 1, UA Type: 1
        
        let uasID = "DRONE001"
        let uasIDData = uasID.data(using: .ascii)!
        data.replaceSubrange(2..<(2 + uasIDData.count), with: uasIDData)
        
        let metadata = ODIDMetadata(
            macAddress: "AA:BB:CC:DD:EE:FF",
            source: .bluetoothLegacy,
            rssi: -70,
            btName: "TestDrone"
        )
        
        let timestamp = Int64(Date().timeIntervalSince1970 * 1000)
        let payload = ODIDPayload(
            rawData: data,
            receivedTimestamp: timestamp,
            metadata: metadata
        )
        
        let receivedMessage = try SwiftOpenDroneID.parsePayload(payload)
        
        XCTAssertEqual(receivedMessage.metadata.macAddress, "AA:BB:CC:DD:EE:FF")
        XCTAssertEqual(receivedMessage.metadata.rssi, -70)
        XCTAssertTrue(receivedMessage.odidMessage is BasicIDMessage)
        
        let basicID = receivedMessage.odidMessage as! BasicIDMessage
        XCTAssertEqual(basicID.uasID, "DRONE001")
    }
}

