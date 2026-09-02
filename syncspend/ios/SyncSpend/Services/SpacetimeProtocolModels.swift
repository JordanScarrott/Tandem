import Foundation

public enum WebSocketConnectionState: Equatable, Sendable {
    case disconnected
    case connecting
    case connected(identity: String)
    case subscribed
    case reconnecting(attempt: Int)
    
    public var isConnected: Bool {
        switch self {
        case .connected, .subscribed:
            return true
        default:
            return false
        }
    }
}

public enum TableRowOperation: Sendable {
    case insert(row: [Any])
    case delete(row: [Any])
}

public struct TableUpdate: Sendable {
    public let tableName: String
    public let tableId: Int?
    public let operations: [TableRowOperation]
    
    public init(tableName: String, tableId: Int? = nil, operations: [TableRowOperation]) {
        self.tableName = tableName
        self.tableId = tableId
        self.operations = operations
    }
}

public struct TransactionUpdateMessage: Sendable {
    public let status: String
    public let callerIdentity: String?
    public let reducerName: String?
    public let timestampMicros: Int64
    public let tableUpdates: [TableUpdate]
    
    public init(
        status: String,
        callerIdentity: String?,
        reducerName: String?,
        timestampMicros: Int64,
        tableUpdates: [TableUpdate]
    ) {
        self.status = status
        self.callerIdentity = callerIdentity
        self.reducerName = reducerName
        self.timestampMicros = timestampMicros
        self.tableUpdates = tableUpdates
    }
    
    /// Parses a TransactionUpdate JSON dictionary from the SpacetimeDB v1.json.spacetimedb protocol
    public static func parse(from dict: [String: Any]) -> TransactionUpdateMessage? {
        let status = dict["status"] as? String ?? "committed"
        let caller = dict["caller_identity"] as? String
        let reducer = dict["reducer_name"] as? String
        
        let tsMicros: Int64
        if let ts = dict["timestamp"] as? NSNumber {
            tsMicros = ts.int64Value
        } else {
            tsMicros = Int64(Date().timeIntervalSince1970 * 1_000_000.0)
        }
        
        var tableUpdates: [TableUpdate] = []
        
        // SpacetimeDB delivers updates in `table_updates` or `tables`
        let rawTableUpdates = (dict["table_updates"] as? [[String: Any]]) ?? (dict["tables"] as? [[String: Any]]) ?? []
        
        for tu in rawTableUpdates {
            guard let tableName = tu["table_name"] as? String ?? tu["name"] as? String else { continue }
            let tableId = (tu["table_id"] as? NSNumber)?.intValue
            
            var ops: [TableRowOperation] = []
            
            // Format 1: `table_row_operations`: [{"op": "insert"|"delete", "row": [...]}]
            if let rowOps = tu["table_row_operations"] as? [[String: Any]] {
                for ro in rowOps {
                    guard let opType = ro["op"] as? String, let row = ro["row"] as? [Any] else { continue }
                    if opType == "insert" {
                        ops.append(.insert(row: row))
                    } else if opType == "delete" {
                        ops.append(.delete(row: row))
                    }
                }
            }
            
            // Format 2: `inserts`: [[...]], `deletes`: [[...]]
            if let inserts = tu["inserts"] as? [[Any]] {
                for row in inserts {
                    ops.append(.insert(row: row))
                }
            }
            if let deletes = tu["deletes"] as? [[Any]] {
                for row in deletes {
                    ops.append(.delete(row: row))
                }
            }
            
            tableUpdates.append(TableUpdate(tableName: tableName, tableId: tableId, operations: ops))
        }
        
        return TransactionUpdateMessage(
            status: status,
            callerIdentity: caller,
            reducerName: reducer,
            timestampMicros: tsMicros,
            tableUpdates: tableUpdates
        )
    }
}
