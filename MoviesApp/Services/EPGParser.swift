import Foundation

class XMLTVParser: NSObject, XMLParserDelegate {
    private var programs: [EPGProgram] = []
    
    private var currentElement = ""
    private var currentChannelId = ""
    private var currentStart = ""
    private var currentStop = ""
    private var currentTitle = ""
    private var currentDesc = ""
    
    private let dateFormatter: DateFormatter = {
        let df = DateFormatter()
        df.dateFormat = "yyyyMMddHHmmss Z"
        return df
    }()
    
    func parse(data: Data) -> [EPGProgram] {
        let parser = XMLParser(data: data)
        parser.delegate = self
        parser.parse()
        return programs
    }
    
    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String] = [:]) {
        currentElement = elementName
        
        if elementName == "programme" {
            currentChannelId = attributeDict["channel"] ?? ""
            currentStart = attributeDict["start"] ?? ""
            currentStop = attributeDict["stop"] ?? ""
            currentTitle = ""
            currentDesc = ""
        }
    }
    
    func parser(_ parser: XMLParser, foundCharacters string: String) {
        let trimmed = string.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty { return }
        
        switch currentElement {
        case "title":
            currentTitle += string
        case "desc":
            currentDesc += string
        default:
            break
        }
    }
    
    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        if elementName == "programme" {
            if let startDate = dateFormatter.date(from: currentStart),
               let stopDate = dateFormatter.date(from: currentStop) {
                let program = EPGProgram(
                    channelId: currentChannelId,
                    start: startDate,
                    stop: stopDate,
                    title: currentTitle.trimmingCharacters(in: .whitespacesAndNewlines),
                    description: currentDesc.isEmpty ? nil : currentDesc.trimmingCharacters(in: .whitespacesAndNewlines)
                )
                programs.append(program)
            }
        }
        currentElement = ""
    }
}
