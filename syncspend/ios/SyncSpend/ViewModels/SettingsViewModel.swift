import Foundation
import Observation
import SwiftUI

@Observable
public final class SettingsViewModel {
    public var service = SpacetimeService.shared
    
    public var hostURL: String {
        get { service.hostURL }
        set { service.hostURL = newValue }
    }
    
    public var databaseName: String {
        get { service.databaseName }
        set { service.databaseName = newValue }
    }
    
    public init() {}
}
