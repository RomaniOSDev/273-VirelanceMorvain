import Foundation

enum AppLinks: String {
    case privacy = "https://virelance273morvain.site/privacy/359/"
    case terms = "https://virelance273morvain.site/terms/359"

    var url: URL {
        URL(string: rawValue)!
    }
}
