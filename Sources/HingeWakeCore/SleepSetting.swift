public enum SleepSetting: Equatable, Sendable {
    case enabled
    case disabled
    case unknown

    public static let queryArguments = ["-g"]

    public static func parse(pmsetOutput: String) -> SleepSetting {
        enum ParsePhase {
            case beforeSystemWide
            case systemWide
            case currentSettings
        }

        var phase = ParsePhase.beforeSystemWide
        var sawValidSleepSetting = false
        var sawValidDisplaySleepSetting = false
        var sawValidWakeOnNetworkSetting = false
        var disableSleepSetting: SleepSetting?

        for line in pmsetOutput.split(whereSeparator: \Character.isNewline) {
            let trimmed = line.drop(while: { $0.isWhitespace })
            if trimmed == "System-wide power settings:" {
                guard phase == .beforeSystemWide else { return .unknown }
                phase = .systemWide
                continue
            }
            if trimmed == "Currently in use:" {
                guard phase == .systemWide else { return .unknown }
                phase = .currentSettings
                continue
            }

            let fields = line.split(whereSeparator: \Character.isWhitespace)
            guard fields.count >= 2 else { continue }

            if fields[0] == "SleepDisabled" {
                guard phase == .systemWide else { return .unknown }
                let candidate: SleepSetting
                if fields[1] == "1" {
                    candidate = .enabled
                } else if fields[1] == "0" {
                    candidate = .disabled
                } else {
                    return .unknown
                }

                if let disableSleepSetting, disableSleepSetting != candidate {
                    return .unknown
                }
                disableSleepSetting = candidate
                continue
            }

            if fields[0] == "sleep" {
                guard phase == .currentSettings else { return .unknown }
                guard fields[1] == "0" || fields[1] == "1" else { return .unknown }
                sawValidSleepSetting = true
            } else if fields[0] == "displaysleep" {
                guard phase == .currentSettings else { return .unknown }
                guard let value = Int(fields[1]), value >= 0 else { return .unknown }
                sawValidDisplaySleepSetting = true
            } else if fields[0] == "womp" {
                guard phase == .currentSettings else { return .unknown }
                guard fields[1] == "0" || fields[1] == "1" else { return .unknown }
                sawValidWakeOnNetworkSetting = true
            }
        }

        guard phase == .currentSettings,
              sawValidSleepSetting,
              sawValidDisplaySleepSetting,
              sawValidWakeOnNetworkSetting else {
            return .unknown
        }
        return disableSleepSetting ?? .disabled
    }
}
