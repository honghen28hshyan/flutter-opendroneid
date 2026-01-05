import Foundation

/// Metadata associated with an OpenDroneID message
public struct ODIDMetadata {
    public let macAddress: String
    public let source: MessageSource
    public let rssi: Int?
    public let btName: String?
    public let frequency: Int?
    public let centerFreq0: Int?
    public let centerFreq1: Int?
    public let channelWidthMhz: Int?
    public let primaryPhy: BluetoothPhy?
    public let secondaryPhy: BluetoothPhy?
    
    public init(
        macAddress: String,
        source: MessageSource,
        rssi: Int? = nil,
        btName: String? = nil,
        frequency: Int? = nil,
        centerFreq0: Int? = nil,
        centerFreq1: Int? = nil,
        channelWidthMhz: Int? = nil,
        primaryPhy: BluetoothPhy? = nil,
        secondaryPhy: BluetoothPhy? = nil
    ) {
        self.macAddress = macAddress
        self.source = source
        self.rssi = rssi
        self.btName = btName
        self.frequency = frequency
        self.centerFreq0 = centerFreq0
        self.centerFreq1 = centerFreq1
        self.channelWidthMhz = channelWidthMhz
        self.primaryPhy = primaryPhy
        self.secondaryPhy = secondaryPhy
    }
}

/// Payload containing raw data and metadata
public struct ODIDPayload {
    public let rawData: Data
    public let receivedTimestamp: Int64
    public let metadata: ODIDMetadata
    
    public init(rawData: Data, receivedTimestamp: Int64, metadata: ODIDMetadata) {
        self.rawData = rawData
        self.receivedTimestamp = receivedTimestamp
        self.metadata = metadata
    }
}

/// Received OpenDroneID message with metadata
public struct ReceivedODIDMessage {
    public let odidMessage: ODIDMessage
    public let metadata: ODIDMetadata
    public let receivedTimestamp: Date
    
    public init(odidMessage: ODIDMessage, metadata: ODIDMetadata, receivedTimestamp: Date) {
        self.odidMessage = odidMessage
        self.metadata = metadata
        self.receivedTimestamp = receivedTimestamp
    }
}
