import Foundation

enum Balk: Error {
    case emptyCourse(at: String)
    case crookedGate(at: String)
    case refused(stage: String)
    case faulted(cooldown: TimeInterval)
    case rungClosed(httpCode: Int)
    case scratched(reason: String)
    case smudged(at: String)

    var isSealed: Bool {
        switch self {
        case .rungClosed, .scratched:
            return true
        default:
            return false
        }
    }
}
