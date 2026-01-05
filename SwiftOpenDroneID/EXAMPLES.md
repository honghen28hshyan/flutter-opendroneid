# SwiftOpenDroneID Examples

## Example 1: Parse Basic ID from Bluetooth Advertisement

```swift
import CoreBluetooth
import SwiftOpenDroneID

class DroneScanner: NSObject, CBCentralManagerDelegate {
    var centralManager: CBCentralManager!
    
    override init() {
        super.init()
        centralManager = CBCentralManager(delegate: self, queue: nil)
    }
    
    func startScanning() {
        let serviceUUID = CBUUID(string: "0000FFFA-0000-1000-8000-00805F9B34FB")
        centralManager.scanForPeripherals(
            withServices: [serviceUUID],
            options: [CBCentralManagerScanOptionAllowDuplicatesKey: true]
        )
    }
    
    func centralManager(_ central: CBCentralManager, didUpdateState state: CBManagerState) {
        if state == .poweredOn {
            startScanning()
        }
    }
    
    func centralManager(_ central: CBCentralManager,
                       didDiscover peripheral: CBPeripheral,
                       advertisementData: [String : Any],
                       rssi RSSI: NSNumber) {
        
        guard let serviceData = advertisementData[CBAdvertisementDataServiceDataKey] as? [CBUUID: Data],
              let odidUUID = CBUUID(string: "0000FFFA-0000-1000-8000-00805F9B34FB"),
              let data = serviceData[odidUUID] else {
            return
        }
        
        // Skip 0x0D prefix (first 2 bytes)
        let messageData = data.dropFirst(2)
        
        do {
            let message = try ODIDMessageParser.parse(data: messageData)
            
            if let basicID = message as? BasicIDMessage {
                print("Found drone: \(basicID.uasID)")
                print("Type: \(basicID.uaType)")
            } else if let location = message as? LocationMessage {
                print("Drone location: \(location.latitude), \(location.longitude)")
                print("Altitude: \(location.geodeticalAltitude ?? 0)m")
                print("Status: \(location.status)")
            }
            
        } catch {
            print("Failed to parse: \(error)")
        }
    }
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        if central.state == .poweredOn {
            startScanning()
        }
    }
}

// Usage
let scanner = DroneScanner()
// Scanning starts automatically when Bluetooth is ready
```

## Example 2: Batch Process Multiple Messages

```swift
import SwiftOpenDroneID

class MessageProcessor {
    var droneDatabase: [String: [ODIDMessage]] = [:]
    
    func processMessage(rawData: Data, metadata: ODIDMetadata) {
        do {
            let message = try ODIDMessageParser.parse(data: rawData)
            
            // Store message by MAC address
            let macAddress = metadata.macAddress
            if droneDatabase[macAddress] == nil {
                droneDatabase[macAddress] = []
            }
            droneDatabase[macAddress]?.append(message)
            
            // Process based on type
            switch message {
            case let basicID as BasicIDMessage:
                updateDroneIdentity(macAddress: macAddress, basicID: basicID)
                
            case let location as LocationMessage:
                updateDroneLocation(macAddress: macAddress, location: location)
                
            case let system as SystemMessage:
                updateOperatorInfo(macAddress: macAddress, system: system)
                
            default:
                break
            }
            
        } catch {
            print("Parse error for \(metadata.macAddress): \(error)")
        }
    }
    
    func updateDroneIdentity(macAddress: String, basicID: BasicIDMessage) {
        print("Drone \(macAddress): ID=\(basicID.uasID), Type=\(basicID.uaType)")
    }
    
    func updateDroneLocation(macAddress: String, location: LocationMessage) {
        print("Drone \(macAddress) at (\(location.latitude), \(location.longitude))")
        
        if location.status == .emergency {
            print("⚠️ EMERGENCY: Drone \(macAddress) in emergency state!")
        }
    }
    
    func updateOperatorInfo(macAddress: String, system: SystemMessage) {
        if let opLat = system.operatorLatitude, let opLon = system.operatorLongitude {
            print("Operator for \(macAddress) at (\(opLat), \(opLon))")
        }
    }
    
    func getDroneInfo(macAddress: String) -> [ODIDMessage]? {
        return droneDatabase[macAddress]
    }
}

// Usage
let processor = MessageProcessor()

// Process incoming messages
let metadata = ODIDMetadata(
    macAddress: "AA:BB:CC:DD:EE:FF",
    source: .bluetoothLegacy,
    rssi: -65
)

processor.processMessage(rawData: messageData, metadata: metadata)
```

## Example 3: Filter Messages by Type

```swift
import SwiftOpenDroneID

class MessageFilter {
    
    func filterLocationMessages(from messages: [Data]) -> [LocationMessage] {
        return messages.compactMap { data in
            guard let message = try? ODIDMessageParser.parse(data: data),
                  let location = message as? LocationMessage else {
                return nil
            }
            return location
        }
    }
    
    func findEmergencyDrones(from messages: [Data]) -> [LocationMessage] {
        return filterLocationMessages(from: messages).filter {
            $0.status == .emergency
        }
    }
    
    func findNearbyDrones(from messages: [Data], 
                         centerLat: Double, 
                         centerLon: Double, 
                         radiusKm: Double) -> [LocationMessage] {
        return filterLocationMessages(from: messages).filter { location in
            let distance = calculateDistance(
                lat1: centerLat, lon1: centerLon,
                lat2: location.latitude, lon2: location.longitude
            )
            return distance <= radiusKm
        }
    }
    
    private func calculateDistance(lat1: Double, lon1: Double, 
                                  lat2: Double, lon2: Double) -> Double {
        let earthRadius = 6371.0 // km
        
        let dLat = (lat2 - lat1) * .pi / 180.0
        let dLon = (lon2 - lon1) * .pi / 180.0
        
        let a = sin(dLat/2) * sin(dLat/2) +
                cos(lat1 * .pi / 180.0) * cos(lat2 * .pi / 180.0) *
                sin(dLon/2) * sin(dLon/2)
        
        let c = 2 * atan2(sqrt(a), sqrt(1-a))
        return earthRadius * c
    }
}

// Usage
let filter = MessageFilter()
let locationMessages = filter.filterLocationMessages(from: rawMessages)
let emergencyDrones = filter.findEmergencyDrones(from: rawMessages)
let nearbyDrones = filter.findNearbyDrones(
    from: rawMessages,
    centerLat: 50.0,
    centerLon: 14.0,
    radiusKm: 5.0
)
```

## Example 4: SwiftUI Integration

```swift
import SwiftUI
import CoreBluetooth
import SwiftOpenDroneID

struct DroneListView: View {
    @StateObject private var scanner = DroneBluetoothScanner()
    
    var body: some View {
        NavigationView {
            List(scanner.discoveredDrones) { drone in
                DroneRowView(drone: drone)
            }
            .navigationTitle("Nearby Drones")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(scanner.isScanning ? "Stop" : "Scan") {
                        if scanner.isScanning {
                            scanner.stopScanning()
                        } else {
                            scanner.startScanning()
                        }
                    }
                }
            }
        }
    }
}

struct DroneRowView: View {
    let drone: DiscoveredDrone
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(drone.uasID)
                .font(.headline)
            
            if let location = drone.lastLocation {
                HStack {
                    Image(systemName: "location.fill")
                    Text("Lat: \(location.latitude, specifier: "%.6f"), ")
                    Text("Lon: \(location.longitude, specifier: "%.6f")")
                }
                .font(.caption)
                .foregroundColor(.secondary)
                
                HStack {
                    Image(systemName: "arrow.up")
                    Text("Alt: \(location.geodeticalAltitude ?? 0, specifier: "%.1f")m")
                    Spacer()
                    Text("RSSI: \(drone.rssi ?? 0)dBm")
                }
                .font(.caption)
                .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

struct DiscoveredDrone: Identifiable {
    let id: String // MAC address
    var uasID: String
    var lastLocation: LocationMessage?
    var rssi: Int?
    var lastSeen: Date
}

class DroneBluetoothScanner: NSObject, ObservableObject, CBCentralManagerDelegate {
    @Published var discoveredDrones: [DiscoveredDrone] = []
    @Published var isScanning = false
    
    private var centralManager: CBCentralManager!
    private var dronesDict: [String: DiscoveredDrone] = [:]
    
    override init() {
        super.init()
        centralManager = CBCentralManager(delegate: self, queue: nil)
    }
    
    func startScanning() {
        let serviceUUID = CBUUID(string: "0000FFFA-0000-1000-8000-00805F9B34FB")
        centralManager.scanForPeripherals(
            withServices: [serviceUUID],
            options: [CBCentralManagerScanOptionAllowDuplicatesKey: true]
        )
        isScanning = true
    }
    
    func stopScanning() {
        centralManager.stopScan()
        isScanning = false
    }
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        if central.state == .poweredOn && isScanning {
            startScanning()
        }
    }
    
    func centralManager(_ central: CBCentralManager,
                       didDiscover peripheral: CBPeripheral,
                       advertisementData: [String : Any],
                       rssi RSSI: NSNumber) {
        
        guard let serviceData = advertisementData[CBAdvertisementDataServiceDataKey] as? [CBUUID: Data],
              let odidUUID = CBUUID(string: "0000FFFA-0000-1000-8000-00805F9B34FB"),
              let data = serviceData[odidUUID] else {
            return
        }
        
        let messageData = data.dropFirst(2)
        let macAddress = peripheral.identifier.uuidString
        
        do {
            let message = try ODIDMessageParser.parse(data: messageData)
            
            if let basicID = message as? BasicIDMessage {
                var drone = dronesDict[macAddress] ?? DiscoveredDrone(
                    id: macAddress,
                    uasID: basicID.uasID,
                    lastSeen: Date()
                )
                drone.uasID = basicID.uasID
                drone.rssi = RSSI.intValue
                drone.lastSeen = Date()
                dronesDict[macAddress] = drone
                
            } else if let location = message as? LocationMessage {
                if var drone = dronesDict[macAddress] {
                    drone.lastLocation = location
                    drone.rssi = RSSI.intValue
                    drone.lastSeen = Date()
                    dronesDict[macAddress] = drone
                }
            }
            
            // Update published list
            discoveredDrones = Array(dronesDict.values).sorted {
                $0.lastSeen > $1.lastSeen
            }
            
        } catch {
            print("Parse error: \(error)")
        }
    }
}
```

## Example 5: Logging and Analytics

```swift
import SwiftOpenDroneID
import Foundation

class DroneAnalytics {
    struct DroneStatistics {
        var messageCount: Int = 0
        var firstSeen: Date?
        var lastSeen: Date?
        var locations: [LocationMessage] = []
        var maxAltitude: Double?
        var maxSpeed: Double?
    }
    
    private var statistics: [String: DroneStatistics] = [:]
    
    func recordMessage(_ message: ODIDMessage, macAddress: String) {
        var stats = statistics[macAddress] ?? DroneStatistics()
        stats.messageCount += 1
        stats.lastSeen = Date()
        
        if stats.firstSeen == nil {
            stats.firstSeen = Date()
        }
        
        if let location = message as? LocationMessage {
            stats.locations.append(location)
            
            if let alt = location.geodeticalAltitude {
                if stats.maxAltitude == nil || alt > stats.maxAltitude! {
                    stats.maxAltitude = alt
                }
            }
            
            if let speed = location.speedHorizontal {
                if stats.maxSpeed == nil || speed > stats.maxSpeed! {
                    stats.maxSpeed = speed
                }
            }
        }
        
        statistics[macAddress] = stats
    }
    
    func getStatistics(for macAddress: String) -> DroneStatistics? {
        return statistics[macAddress]
    }
    
    func generateReport() -> String {
        var report = "=== Drone Analytics Report ===\n\n"
        report += "Total drones detected: \(statistics.count)\n\n"
        
        for (macAddress, stats) in statistics {
            report += "Drone: \(macAddress)\n"
            report += "  Messages: \(stats.messageCount)\n"
            report += "  First seen: \(stats.firstSeen?.description ?? "N/A")\n"
            report += "  Last seen: \(stats.lastSeen?.description ?? "N/A")\n"
            report += "  Max altitude: \(stats.maxAltitude?.description ?? "N/A")m\n"
            report += "  Max speed: \(stats.maxSpeed?.description ?? "N/A")m/s\n"
            report += "  Location records: \(stats.locations.count)\n\n"
        }
        
        return report
    }
    
    func exportToJSON() throws -> Data {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        
        // Convert to JSON-friendly structure
        let exportData = statistics.mapValues { stats in
            [
                "messageCount": stats.messageCount,
                "firstSeen": stats.firstSeen?.timeIntervalSince1970 ?? 0,
                "lastSeen": stats.lastSeen?.timeIntervalSince1970 ?? 0,
                "maxAltitude": stats.maxAltitude ?? 0,
                "maxSpeed": stats.maxSpeed ?? 0,
                "locationCount": stats.locations.count
            ]
        }
        
        return try encoder.encode(exportData)
    }
}

// Usage
let analytics = DroneAnalytics()

// Record messages as they arrive
let metadata = ODIDMetadata(macAddress: "AA:BB:CC:DD:EE:FF", source: .bluetoothLegacy)
let message = try ODIDMessageParser.parse(data: messageData)
analytics.recordMessage(message, macAddress: metadata.macAddress)

// Generate report
print(analytics.generateReport())

// Export to JSON
let jsonData = try analytics.exportToJSON()
try jsonData.write(to: URL(fileURLWithPath: "drone_analytics.json"))
```
