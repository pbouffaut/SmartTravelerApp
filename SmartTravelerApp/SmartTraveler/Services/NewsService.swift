import Foundation
import Combine

struct NewsItem: Identifiable {
    let id = UUID()
    let title: String
    let description: String
    let source: String
    let link: String
    let pubDate: Date?
    var translatedTitle: String?
    var translatedDescription: String?
}

class NewsService: ObservableObject {
    @Published var articles: [NewsItem] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    func fetchNews(for city: String, countryCode: String) {
        guard !city.isEmpty else { return }
        isLoading = true
        errorMessage = nil

        let query = "\(city) \(countryCode)".addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? city
        let urlString = "https://news.google.com/rss/search?q=\(query)&hl=en&gl=\(countryCode)&ceid=\(countryCode):en"

        guard let url = URL(string: urlString) else {
            isLoading = false
            return
        }

        URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            DispatchQueue.main.async {
                self?.isLoading = false

                if let error {
                    self?.errorMessage = error.localizedDescription
                    return
                }

                guard let data else {
                    self?.errorMessage = "No data received"
                    return
                }

                let parser = RSSParser()
                let items = parser.parse(data: data)
                self?.articles = items
            }
        }.resume()
    }
}

// MARK: - RSS Parser

private class RSSParser: NSObject, XMLParserDelegate {
    private var items: [NewsItem] = []
    private var currentElement = ""
    private var currentTitle = ""
    private var currentDescription = ""
    private var currentLink = ""
    private var currentPubDate = ""
    private var currentSource = ""
    private var isInsideItem = false

    func parse(data: Data) -> [NewsItem] {
        let parser = XMLParser(data: data)
        parser.delegate = self
        parser.parse()
        return items
    }

    func parser(_ parser: XMLParser, didStartElement elementName: String,
                namespaceURI: String?, qualifiedName: String?,
                attributes: [String: String] = [:]) {
        currentElement = elementName
        if elementName == "item" {
            isInsideItem = true
            currentTitle = ""
            currentDescription = ""
            currentLink = ""
            currentPubDate = ""
            currentSource = ""
        }
        if elementName == "source" {
            currentSource = attributes["url"] ?? ""
        }
    }

    func parser(_ parser: XMLParser, foundCharacters string: String) {
        guard isInsideItem else { return }
        switch currentElement {
        case "title": currentTitle += string
        case "description": currentDescription += string
        case "link": currentLink += string
        case "pubDate": currentPubDate += string
        case "source": currentSource = string
        default: break
        }
    }

    func parser(_ parser: XMLParser, didEndElement elementName: String,
                namespaceURI: String?, qualifiedName: String?) {
        if elementName == "item" {
            isInsideItem = false

            let dateFormatter = DateFormatter()
            dateFormatter.locale = Locale(identifier: "en_US_POSIX")
            dateFormatter.dateFormat = "EEE, dd MMM yyyy HH:mm:ss Z"
            let date = dateFormatter.date(from: currentPubDate.trimmingCharacters(in: .whitespacesAndNewlines))

            // Clean HTML from description
            let cleanDesc = currentDescription
                .replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)
                .trimmingCharacters(in: .whitespacesAndNewlines)

            let item = NewsItem(
                title: currentTitle.trimmingCharacters(in: .whitespacesAndNewlines),
                description: cleanDesc,
                source: currentSource.trimmingCharacters(in: .whitespacesAndNewlines),
                link: currentLink.trimmingCharacters(in: .whitespacesAndNewlines),
                pubDate: date
            )
            items.append(item)
        }
    }
}
