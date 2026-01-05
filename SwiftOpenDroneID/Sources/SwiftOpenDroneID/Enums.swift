import Foundation

/// Higher priority drains battery but receives more data
public enum ScanPriority: Int {
    case high = 0
    case low = 1
}

/// ODID Message Source
public enum MessageSource: Int {
    case bluetoothLegacy = 0
    case bluetoothLongRange = 1
    case wifiNan = 2
    case wifiBeacon = 3
    case unknown = 4
}

/// State of the Bluetooth adapter
public enum BluetoothState: Int {
    case unknown = 0
    case resetting = 1
    case unsupported = 2
    case unauthorized = 3
    case poweredOff = 4
    case poweredOn = 5
}

/// State of the Wifi adapter
public enum WifiState: Int {
    case disabling = 0
    case disabled = 1
    case enabling = 2
    case enabled = 3
}

/// Bluetooth PHY type
public enum BluetoothPhy: Int {
    case none = 0
    case phy1M = 1
    case phy2M = 2
    case phyLECoded = 3
    case unknown = 4
}

/// OpenDroneID Message Type
public enum MessageType: UInt8 {
    case basicID = 0x0
    case location = 0x1
    case auth = 0x2
    case selfID = 0x3
    case system = 0x4
    case operatorID = 0x5
    case messagePack = 0xF
    case invalid = 0xFF
}

/// UA Type for Basic ID
public enum UAType: UInt8 {
    case none = 0
    case aeroplane = 1
    case helicopterOrMultirotor = 2
    case gyroplane = 3
    case hybridLift = 4
    case ornithopter = 5
    case glider = 6
    case kite = 7
    case freeBalloon = 8
    case captiveBalloon = 9
    case airship = 10
    case freeFallOrParachute = 11
    case rocket = 12
    case tetheredPoweredAircraft = 13
    case groundObstacle = 14
    case other = 15
}

/// ID Type for Basic ID
public enum IDType: UInt8 {
    case none = 0
    case serialNumber = 1
    case cadRegistrationID = 2
    case utmAssignedUUID = 3
    case specificSessionID = 4
}

/// Operational Status
public enum OperationalStatus: UInt8 {
    case undeclared = 0
    case ground = 1
    case airborne = 2
    case emergency = 3
    case remoteIDSystemFailure = 4
}

/// Height Type
public enum HeightType: UInt8 {
    case aboveTakeoff = 0
    case agl = 1
}

/// Horizontal Accuracy
public enum HorizontalAccuracy: UInt8 {
    case unknown = 0
    case lessThan10m = 1
    case lessThan3m = 2
    case lessThan1m = 3
    case lessThan03m = 4
    case lessThan01m = 5
    case lessThan003m = 6
}

/// Vertical Accuracy
public enum VerticalAccuracy: UInt8 {
    case unknown = 0
    case lessThan150m = 1
    case lessThan45m = 2
    case lessThan25m = 3
    case lessThan10m = 4
    case lessThan3m = 5
    case lessThan1m = 6
}

/// Speed Accuracy
public enum SpeedAccuracy: UInt8 {
    case unknown = 0
    case lessThan10mPerS = 1
    case lessThan3mPerS = 2
    case lessThan1mPerS = 3
    case lessThan03mPerS = 4
}

/// Timestamp Accuracy
public enum TimestampAccuracy: UInt8 {
    case unknown = 0
    case lessThan01s = 1
    case lessThan02s = 2
    case lessThan03s = 3
    case lessThan04s = 4
    case lessThan05s = 5
    case lessThan06s = 6
    case lessThan07s = 7
    case lessThan08s = 8
    case lessThan09s = 9
    case lessThan1s = 10
    case lessThan15s = 11
    case greaterThan15s = 12
}

/// Operator Location Type
public enum OperatorLocationType: UInt8 {
    case takeoff = 0
    case liveGNSS = 1
    case fixed = 2
}

/// Classification Type
public enum ClassificationType: UInt8 {
    case undeclared = 0
    case eu = 1
}

/// EU Category
public enum EUCategory: UInt8 {
    case undefined = 0
    case open = 1
    case specific = 2
    case certified = 3
}

/// EU Class
public enum EUClass: UInt8 {
    case undefined = 0
    case class0 = 1
    case class1 = 2
    case class2 = 3
    case class3 = 4
    case class4 = 5
    case class5 = 6
    case class6 = 7
}

/// Authentication Type
public enum AuthType: UInt8 {
    case none = 0
    case ubsSignature = 1
    case networkRemoteID = 2
    case specificAuthentication = 3
}
