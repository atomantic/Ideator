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
            let help = parts.count > 1 ? parts[1].trimmingCharacters(in: .whitespacesAndNewlines) : nil
            let slugRaw = parts.count > 2 ? parts[2].trimmingCharacters(in: .whitespacesAndNewlines) : nil
            let slug = (slugRaw?.isEmpty == true) ? nil : slugRaw
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

