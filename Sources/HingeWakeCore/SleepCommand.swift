public enum SleepCommand: Equatable, Sendable {
    case enable
    case disable

    public var executablePath: String { "/usr/bin/pmset" }

    public var expectedSetting: SleepSetting {
        switch self {
        case .enable:
            return .enabled
        case .disable:
            return .disabled
        }
    }

    public var arguments: [String] {
        switch self {
        case .enable:
            return ["-a", "disablesleep", "1"]
        case .disable:
            return ["-a", "disablesleep", "0"]
        }
    }
}
