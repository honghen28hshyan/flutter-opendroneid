import Foundation

/// Base protocol for all OpenDroneID messages
public protocol ODIDMessage {
    var messageType: MessageType { get }
}

/// Basic ID Message - Contains UAS identification
public struct BasicIDMessage: ODIDMessage {
    public let messageType: MessageType = .basicID
    public let uaType: UAType
    public let idType: IDType
    public let uasID: String
    
    public init(uaType: UAType, idType: IDType, uasID: String) {
        self.uaType = uaType
        self.idType = idType
        self.uasID = uasID
    }
}

/// Location Message - Contains UAS location and velocity
public struct LocationMessage: ODIDMessage {
    public let messageType: MessageType = .location
    public let status: OperationalStatus
    public let heightType: HeightType
    public let direction: Double?
    public let speedHorizontal: Double?
    public let speedVertical: Double?
    public let latitude: Double
    public let longitude: Double
    public let pressureAltitude: Double?
    public let geodeticalAltitude: Double?
    public let height: Double?
    public let horizontalAccuracy: HorizontalAccuracy
    public let verticalAccuracy: VerticalAccuracy
    public let baroAccuracy: VerticalAccuracy
    public let speedAccuracy: SpeedAccuracy
    public let timestamp: Double?
    public let timestampAccuracy: TimestampAccuracy
    
    public init(
        status: OperationalStatus,
        heightType: HeightType,
        direction: Double?,
        speedHorizontal: Double?,
        speedVertical: Double?,
        latitude: Double,
        longitude: Double,
        pressureAltitude: Double?,
        geodeticalAltitude: Double?,
        height: Double?,
        horizontalAccuracy: HorizontalAccuracy,
        verticalAccuracy: VerticalAccuracy,
        baroAccuracy: VerticalAccuracy,
        speedAccuracy: SpeedAccuracy,
        timestamp: Double?,
        timestampAccuracy: TimestampAccuracy
    ) {
        self.status = status
        self.heightType = heightType
        self.direction = direction
        self.speedHorizontal = speedHorizontal
        self.speedVertical = speedVertical
        self.latitude = latitude
        self.longitude = longitude
        self.pressureAltitude = pressureAltitude
        self.geodeticalAltitude = geodeticalAltitude
        self.height = height
        self.horizontalAccuracy = horizontalAccuracy
        self.verticalAccuracy = verticalAccuracy
        self.baroAccuracy = baroAccuracy
        self.speedAccuracy = speedAccuracy
        self.timestamp = timestamp
        self.timestampAccuracy = timestampAccuracy
    }
}

/// Self ID Message - Contains operator description
public struct SelfIDMessage: ODIDMessage {
    public let messageType: MessageType = .selfID
    public let descriptionType: UInt8
    public let operationDescription: String
    
    public init(descriptionType: UInt8, operationDescription: String) {
        self.descriptionType = descriptionType
        self.operationDescription = operationDescription
    }
}

/// System Message - Contains operator location and system information
public struct SystemMessage: ODIDMessage {
    public let messageType: MessageType = .system
    public let operatorLocationType: OperatorLocationType
    public let classificationType: ClassificationType
    public let operatorLatitude: Double?
    public let operatorLongitude: Double?
    public let areaCount: UInt8?
    public let areaRadius: UInt8?
    public let areaCeiling: Double?
    public let areaFloor: Double?
    public let category: EUCategory?
    public let classValue: EUClass?
    public let operatorAltitudeGeo: Double?
    public let timestamp: UInt32?
    
    public init(
        operatorLocationType: OperatorLocationType,
        classificationType: ClassificationType,
        operatorLatitude: Double?,
        operatorLongitude: Double?,
        areaCount: UInt8?,
        areaRadius: UInt8?,
        areaCeiling: Double?,
        areaFloor: Double?,
        category: EUCategory?,
        classValue: EUClass?,
        operatorAltitudeGeo: Double?,
        timestamp: UInt32?
    ) {
        self.operatorLocationType = operatorLocationType
        self.classificationType = classificationType
        self.operatorLatitude = operatorLatitude
        self.operatorLongitude = operatorLongitude
        self.areaCount = areaCount
        self.areaRadius = areaRadius
        self.areaCeiling = areaCeiling
        self.areaFloor = areaFloor
        self.category = category
        self.classValue = classValue
        self.operatorAltitudeGeo = operatorAltitudeGeo
        self.timestamp = timestamp
    }
}

/// Operator ID Message - Contains operator ID
public struct OperatorIDMessage: ODIDMessage {
    public let messageType: MessageType = .operatorID
    public let operatorIdType: UInt8
    public let operatorId: String
    
    public init(operatorIdType: UInt8, operatorId: String) {
        self.operatorIdType = operatorIdType
        self.operatorId = operatorId
    }
}

/// Authentication Message - Contains authentication data
public struct AuthMessage: ODIDMessage {
    public let messageType: MessageType = .auth
    public let authType: AuthType
    public let dataPage: UInt8
    public let lastPageIndex: UInt8
    public let length: UInt8
    public let timestamp: UInt32
    public let authData: Data
    
    public init(
        authType: AuthType,
        dataPage: UInt8,
        lastPageIndex: UInt8,
        length: UInt8,
        timestamp: UInt32,
        authData: Data
    ) {
        self.authType = authType
        self.dataPage = dataPage
        self.lastPageIndex = lastPageIndex
        self.length = length
        self.timestamp = timestamp
        self.authData = authData
    }
}

/// Message Pack - Contains multiple messages
public struct MessagePackMessage: ODIDMessage {
    public let messageType: MessageType = .messagePack
    public let messages: [ODIDMessage]
    
    public init(messages: [ODIDMessage]) {
        self.messages = messages
    }
}
