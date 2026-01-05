# SwiftOpenDroneID

A Swift library for parsing OpenDroneID (Remote ID) messages according to the ASTM F3411 and ASD-STAN prEN 4709-002 specifications.

## Overview

This library provides Swift data structures and parsing logic for OpenDroneID messages, matching the functionality of the Dart `dart_opendroneid` package used in the flutter_opendroneid plugin.

## Features

- ✅ Parse Basic ID messages (UAS identification)
- ✅ Parse Location messages (position, altitude, velocity)
- ✅ Parse Self ID messages (operator description)
- ✅ Parse System messages (operator location, classification)
- ✅ Parse Operator ID messages (operator identification)
- ✅ Parse Authentication messages (cryptographic authentication)
- ✅ Parse Message Pack messages (multiple messages in one packet)
- ✅ Full ASTM F3411 specification support
- ✅ Type-safe Swift enums and structs
- ✅ Comprehensive error handling

## Installation

### Swift Package Manager

Add this package to your `Package.swift`:

```swift
dependencies: [
    .package(url: "path/to/SwiftOpenDroneID", from: "1.0.0")
]
```

Or add it in Xcode:
1. File > Add Packages...
2. Enter the repository URL
3. Select the version/branch
4. Add to your target

## Usage

### Basic Parsing

```swift
import SwiftOpenDroneID

// Raw data from Bluetooth or WiFi advertisement (25 bytes)
let rawData: Data = ... 

do {
    let message = try ODIDMessageParser.parse(data: rawData)
    
    switch message {
    case let basicID as BasicIDMessage:
        print("UAS ID: \(basicID.uasID)")
        print("ID Type: \(basicID.idType)")
        print("UA Type: \(basicID.uaType)")
        
    case let location as LocationMessage:
        print("Latitude: \(location.latitude)")
        print("Longitude: \(location.longitude)")
        print("Altitude: \(location.geodeticalAltitude ?? 0)")
        print("Status: \(location.status)")
        
    case let selfID as SelfIDMessage:
        print("Description: \(selfID.operationDescription)")
        
    case let system as SystemMessage:
        print("Operator Location: \(system.operatorLatitude ?? 0), \(system.operatorLongitude ?? 0)")
        
    case let operatorID as OperatorIDMessage:
        print("Operator ID: \(operatorID.operatorId)")
        
    case let auth as AuthMessage:
        print("Auth Type: \(auth.authType)")
        print("Auth Data: \(auth.authData)")
        
    case let pack as MessagePackMessage:
        print("Message pack contains \(pack.messages.count) messages")
        for msg in pack.messages {
            print("  - Message type: \(msg.messageType)")
        }
        
    default:
        print("Unknown message type")
    }
} catch {
    print("Failed to parse message: \(error)")
}
```

### Parsing with Metadata

```swift
import SwiftOpenDroneID

// Create payload with metadata
let metadata = ODIDMetadata(
    macAddress: "AA:BB:CC:DD:EE:FF",
    source: .bluetoothLegacy,
    rssi: -65,
    btName: "Drone_12345"
)

let payload = ODIDPayload(
    rawData: rawData,
    receivedTimestamp: Int64(Date().timeIntervalSince1970 * 1000),
    metadata: metadata
)

do {
    let receivedMessage = try SwiftOpenDroneID.parsePayload(payload)
    print("Received at: \(receivedMessage.receivedTimestamp)")
    print("RSSI: \(receivedMessage.metadata.rssi ?? 0)")
    print("Message: \(receivedMessage.odidMessage)")
} catch {
    print("Failed to parse payload: \(error)")
}
```

### Working with CoreBluetooth

```swift
import CoreBluetooth
import SwiftOpenDroneID

func centralManager(_ central: CBCentralManager, 
                   didDiscover peripheral: CBPeripheral, 
                   advertisementData: [String : Any], 
                   rssi RSSI: NSNumber) {
    
    // Get service data for OpenDroneID service UUID (0xFFFA)
    guard let serviceData = advertisementData[CBAdvertisementDataServiceDataKey] as? [CBUUID: Data],
          let odidUUID = CBUUID(string: "0000FFFA-0000-1000-8000-00805F9B34FB"),
          let data = serviceData[odidUUID] else {
        return
    }
    
    // Skip the first 2 bytes (0x0D prefix) and parse
    let messageData = data.dropFirst(2)
    
    do {
        let message = try ODIDMessageParser.parse(data: messageData)
        
        // Create metadata
        let metadata = ODIDMetadata(
            macAddress: peripheral.identifier.uuidString,
            source: .bluetoothLegacy,
            rssi: RSSI.intValue,
            btName: peripheral.name
        )
        
        let receivedMessage = ReceivedODIDMessage(
            odidMessage: message,
            metadata: metadata,
            receivedTimestamp: Date()
        )
        
        // Handle the received message
        handleODIDMessage(receivedMessage)
        
    } catch {
        print("Failed to parse OpenDroneID message: \(error)")
    }
}
```

## Message Types

### Basic ID Message
Contains UAS (Unmanned Aircraft System) identification information:
- UAS ID (serial number, CAA registration, etc.)
- UA Type (aeroplane, helicopter, etc.)
- ID Type (serial number, registration ID, UUID, etc.)

### Location Message
Contains current UAS position and movement:
- Latitude/Longitude
- Altitude (pressure, geodetic, height above takeoff/ground)
- Speed (horizontal and vertical)
- Direction
- Operational status
- Accuracy indicators
- Timestamp

### Self ID Message
Contains operator-provided description of the operation.

### System Message
Contains operator location and flight area information:
- Operator location (latitude/longitude/altitude)
- Flight area (radius, ceiling, floor)
- Classification (EU category and class)
- Timestamp

### Operator ID Message
Contains operator identification string.

### Authentication Message
Contains cryptographic authentication data for verification.

### Message Pack
Contains multiple messages bundled together in a single packet.

## Data Structures

The library provides the following main structures:

- `ODIDMessage` - Protocol for all message types
- `ODIDMetadata` - Metadata about message source (MAC, RSSI, etc.)
- `ODIDPayload` - Raw data with metadata
- `ReceivedODIDMessage` - Complete message with metadata and timestamp

## Error Handling

The parser throws `ODIDParsingError` with the following cases:

- `.invalidMessageLength` - Message data is too short
- `.invalidMessageType` - Unknown or invalid message type
- `.invalidData` - Corrupted or malformed data
- `.unsupportedMessageType` - Message type not yet supported
- `.corruptedData` - Data integrity check failed

## Platform Support

- iOS 13.0+
- macOS 10.15+
- Swift 5.9+

## Specifications

This library implements:
- [ASTM F3411-22a](https://www.astm.org/f3411-22a.html) - Standard Specification for Remote ID and Tracking
- [ASD-STAN prEN 4709-002](http://asd-stan.org/downloads/asd-stan-pren-4709-002-p1/) - Direct Remote ID

## Related Projects

- [flutter_opendroneid](https://github.com/dronetag/flutter-opendroneid) - Flutter plugin for OpenDroneID (uses this library's Dart equivalent)
- [dart-opendroneid](https://github.com/dronetag/dart-opendroneid) - Dart implementation of OpenDroneID parsing
- [OpenDroneID Android receiver](https://github.com/opendroneid/receiver-android) - Android reference implementation

## License

© Dronetag 2025

This library is based on the data parsing logic from the flutter_opendroneid project.

## Contributing

Contributions are welcome! Please feel free to submit issues or pull requests.
