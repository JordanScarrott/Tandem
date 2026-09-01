import Foundation
import Observation
import SwiftUI

@Observable
public final class SettingsViewModel {
    public var service = SpacetimeService.shared
    
    public var userProfile: UserProfileItem?
    public var isLoadingProfile: Bool = false
    public var isSavingProfile: Bool = false
    public var errorMessage: String?
    
    public var hostURL: String {
        get { service.hostURL }
        set { service.hostURL = newValue }
    }
    
    public var databaseName: String {
        get { service.databaseName }
        set { service.databaseName = newValue }
    }
    
    public init() {}
    
    public func loadProfile() async {
        isLoadingProfile = true
        do {
            self.userProfile = try await service.fetchUserProfile()
        } catch {
            print("SettingsViewModel: Failed to load profile: \(error)")
        }
        isLoadingProfile = false
    }
    
    public func updateProfile(displayName: String, billingCycleStartDay: UInt8) async -> Bool {
        isSavingProfile = true
        errorMessage = nil
        do {
            try await service.updateUserProfile(
                displayName: displayName,
                billingCycleStartDay: billingCycleStartDay
            )
            await loadProfile()
            isSavingProfile = false
            return true
        } catch {
            isSavingProfile = false
            errorMessage = error.localizedDescription
            return false
        }
    }
}
