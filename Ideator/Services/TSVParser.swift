import Foundation

enum TSVParser {
    static func parse(tsv: String, flexibleCategory: FlexibleCategory) -> [Prompt] {
        let lines = tsv.components(separatedBy: .newlines)
        let dataLines = lines.dropFirst().filter { !$0.isEmpty }
        return dataLines.compactMap { line in
            let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty else { return nil }
            let parts = trimmed.components(separatedBy: "\t")
            let text = parts.first?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            guard !text.isEmpty else { return nil }

            var help: String?
            var slug: String?

            if parts.count > 2 {
                // 3-column format: text \t help \t slug
                let helpRaw = parts[1].trimmingCharacters(in: .whitespacesAndNewlines)
                help = helpRaw.isEmpty ? nil : helpRaw
                let slugRaw = parts[2].trimmingCharacters(in: .whitespacesAndNewlines)
                slug = slugRaw.isEmpty ? nil : slugRaw
            } else if parts.count > 1 {
                // 2-column format: text \t "(help text) slug"
                let raw = parts[1].trimmingCharacters(in: .whitespacesAndNewlines)
                if let closeParenRange = raw.range(of: ")", options: .backwards),
                   raw.hasPrefix("(") {
                    help = String(raw[raw.startIndex...closeParenRange.lowerBound])
                    let remainder = raw[closeParenRange.upperBound...].trimmingCharacters(in: .whitespaces)
                    slug = remainder.isEmpty ? nil : remainder
                } else {
                    help = raw.isEmpty ? nil : raw
                }
            }

            return Prompt(
                text: text,
                flexibleCategory: flexibleCategory,
                suggestedCount: 10,
                help: help,
                slug: slug
            )
        }
    }
}

