import Foundation
import Combine
import FirebaseRemoteConfig

@MainActor
class ConfigManager: ObservableObject {
    static let shared = ConfigManager()
    
    private init() {}
    
    func fetchRemoteUrl() async -> String? {
        let remoteConfig = RemoteConfig.remoteConfig()
        let settings = RemoteConfigSettings()
        settings.minimumFetchInterval = 0
        remoteConfig.configSettings = settings
        
        do {
            let status = try await remoteConfig.fetchAndActivate()

            let candidateKeys = ["baseFeature"]
            for key in candidateKeys {
                let value = remoteConfig[key].stringValue.trimmingCharacters(in: .whitespacesAndNewlines)

                if !value.isEmpty, URL(string: value) != nil {
                    return value
                }
            }

            return nil
        } catch {
            return nil
        }
    }
}
