import Foundation

public protocol SpacetimeWebSocketDelegate: AnyObject {
    func webSocketDidReceiveIdentity(identity: String, token: String)
    func webSocketDidApplySubscription(rows: [String: [[Any]]])
    func webSocketDidReceiveTransaction(update: TransactionUpdateMessage)
    func webSocketStateDidChange(to state: WebSocketConnectionState)
}

public final class SpacetimeWebSocketClient: @unchecked Sendable {
    public static let shared = SpacetimeWebSocketClient()
    
    private var webSocketTask: URLSessionWebSocketTask?
    private var urlSession: URLSession
    public var hostURL: String = "https://maincloud.spacetimedb.com"
    public var databaseName: String = "ad-guitar-1941"
    private var authToken: String?
    
    public weak var delegate: SpacetimeWebSocketDelegate?
    public private(set) var state: WebSocketConnectionState = .disconnected {
        didSet {
            delegate?.webSocketStateDidChange(to: state)
        }
    }
    
    private var reconnectAttempt = 0
    private let maxReconnectDelay: TimeInterval = 30.0
    private var isIntentionallyClosed = false
    private var pingTimer: Task<Void, Never>?
    private var listenTask: Task<Void, Never>?
    
    public init(
        hostURL: String = "https://maincloud.spacetimedb.com",
        databaseName: String = "ad-guitar-1941"
    ) {
        self.hostURL = hostURL
        self.databaseName = databaseName
        let config = URLSessionConfiguration.default
        config.waitsForConnectivity = true
        self.urlSession = URLSession(configuration: config)
    }
    
    public func connect(authToken: String?) {
        self.authToken = authToken
        self.isIntentionallyClosed = false
        self.reconnectAttempt = 0
        startConnection()
    }
    
    private func startConnection() {
        let wsScheme = hostURL.hasPrefix("https") ? "wss" : "ws"
        let base = hostURL.replacingOccurrences(of: "https://", with: "").replacingOccurrences(of: "http://", with: "")
        
        guard let url = URL(string: "\(wsScheme)://\(base)/v1/database/\(databaseName)/subscribe") else {
            print("SpacetimeWebSocketClient: Bad WebSocket URL for host \(hostURL)")
            return
        }
        
        var request = URLRequest(url: url)
        request.setValue("v1.json.spacetimedb", forHTTPHeaderField: "Sec-WebSocket-Protocol")
        if let token = authToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        self.webSocketTask = urlSession.webSocketTask(with: request)
        self.state = .connecting
        self.webSocketTask?.resume()
        
        startListening()
        startPingTimer()
    }
    
    private func startListening() {
        listenTask?.cancel()
        listenTask = Task { [weak self] in
            while !Task.isCancelled {
                guard let self = self, let task = self.webSocketTask else { break }
                do {
                    let message = try await task.receive()
                    self.handleMessage(message)
                } catch {
                    self.handleDisconnection(error: error)
                    break
                }
            }
        }
    }
    
    public func handleMessage(_ message: URLSessionWebSocketTask.Message) {
        switch message {
        case .string(let text):
            guard let data = text.data(using: .utf8),
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                return
            }
            routeProtocolMessage(json)
        case .data(let data):
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                routeProtocolMessage(json)
            }
        @unknown default:
            break
        }
    }
    
    public func routeProtocolMessage(_ json: [String: Any]) {
        if let identObj = json["IdentityToken"] as? [String: Any],
           let ident = identObj["identity"] as? String,
           let tok = identObj["token"] as? String {
            self.state = .connected(identity: ident)
            delegate?.webSocketDidReceiveIdentity(identity: ident, token: tok)
            sendSubscriptionQueries()
        } else if let subApplied = json["SubscribeApplied"] as? [String: Any],
                  let rows = subApplied["rows"] as? [String: [[Any]]] {
            self.state = .subscribed
            delegate?.webSocketDidApplySubscription(rows: rows)
        } else if let txObj = json["TransactionUpdate"] as? [String: Any] {
            if let payload = TransactionUpdateMessage.parse(from: txObj) {
                delegate?.webSocketDidReceiveTransaction(update: payload)
            }
        }
    }
    
    public func sendSubscriptionQueries() {
        let queries = [
            "SELECT * FROM my_expenses;",
            "SELECT * FROM my_categories;"
        ]
        let message: [String: Any] = [
            "Subscribe": [
                "query_strings": queries
            ]
        ]
        if let data = try? JSONSerialization.data(withJSONObject: message),
           let string = String(data: data, encoding: .utf8) {
            webSocketTask?.send(.string(string)) { error in
                if let error = error {
                    print("SpacetimeWebSocketClient: Subscription query failed: \(error)")
                }
            }
        }
    }
    
    private func startPingTimer() {
        pingTimer?.cancel()
        pingTimer = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(25))
                guard let self = self else { break }
                self.sendPing()
            }
        }
    }
    
    public func sendPing() {
        webSocketTask?.sendPing { error in
            if let error = error {
                print("SpacetimeWebSocketClient: Ping failed: \(error)")
            }
        }
    }
    
    private func handleDisconnection(error: Error) {
        guard !isIntentionallyClosed else { return }
        pingTimer?.cancel()
        reconnectAttempt += 1
        let delay = min(pow(2.0, Double(reconnectAttempt)), maxReconnectDelay)
        self.state = .reconnecting(attempt: reconnectAttempt)
        
        Task { [weak self] in
            try? await Task.sleep(for: .seconds(delay))
            guard let self = self, !self.isIntentionallyClosed else { return }
            self.startConnection()
        }
    }
    
    public func disconnect() {
        isIntentionallyClosed = true
        pingTimer?.cancel()
        listenTask?.cancel()
        webSocketTask?.cancel(with: .goingAway, reason: nil)
        self.state = .disconnected
    }
}
