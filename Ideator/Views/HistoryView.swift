import SwiftUI

struct HistoryView: View {
    @State private var completedLists: [IdeaList] = []
    @State private var selectedList: IdeaList?
    @State private var searchText = ""
    @State private var selectedCategory: Category?
    @State private var viewMode: ViewMode = .list
    @State private var calendarMonth: Date = Date()
    @State private var selectedDateForDaySheet: Date?
    @State private var showingDaySheet = false
    
    var filteredLists: [IdeaList] {
        var lists = completedLists
        
        if let category = selectedCategory {
            lists = lists.filter { $0.prompt.category == category }
        }
        
        if !searchText.isEmpty {
            lists = lists.filter { list in
                list.prompt.text.localizedCaseInsensitiveContains(searchText) ||
                list.ideas.contains { $0.localizedCaseInsensitiveContains(searchText) }
            }
        }
        
        return lists
    }
    
    var body: some View {
        NavigationStack {
            Group {
                if completedLists.isEmpty {
                    emptyStateView
                } else {
                    VStack(spacing: 0) {
                        if !completedLists.isEmpty {
                            headerControls
                            categoryFilter
                        }
                        
                        if viewMode == .list {
                            List {
                                ForEach(filteredLists) { list in
                                    HistoryRow(ideaList: list) {
                                        selectedList = list
                                    }
                                }
                                .onDelete(perform: deleteLists)
                            }
                            .listStyle(PlainListStyle())
                            .searchable(text: $searchText, prompt: "Search ideas...")
                        } else {
                            HistoryCalendarView(
                                month: $calendarMonth,
                                listsByDay: groupListsByDay(filteredLists),
                                onSelectList: { list in selectedList = list },
                                onSelectDay: { date in
                                    selectedDateForDaySheet = date
                                    showingDaySheet = true
                                }
                            )
                            .padding(.horizontal)
                            .padding(.top, 8)
                            .sheet(isPresented: $showingDaySheet) {
                                if let date = selectedDateForDaySheet {
                                    DayListsSheet(
                                        date: date,
                                        lists: groupListsByDay(filteredLists)[Calendar.current.startOfDay(for: date)] ?? [],
                                        onOpen: { list in selectedList = list }
                                    )
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("History")
            .navigationBarTitleDisplayMode(.large)
            .onAppear {
                loadHistory()
            }
            .sheet(item: $selectedList) { list in
                IdeaListDetailView(ideaList: list)
            }
        }
    }
    
    private var headerControls: some View {
        HStack {
            Picker("View", selection: $viewMode) {
                Text("List").tag(ViewMode.list)
                Text("Calendar").tag(ViewMode.calendar)
            }
            .pickerStyle(.segmented)
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "clock.arrow.circlepath")
                .font(.system(size: 80))
                .foregroundColor(.gray)
            
            Text("No Completed Lists")
                .font(.title2)
                .fontWeight(.bold)
            
            Text("Your completed idea lists will appear here")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
    }
    
    private var categoryFilter: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                FilterChip(
                    title: "All",
                    isSelected: selectedCategory == nil
                ) {
                    selectedCategory = nil
                }
                
                ForEach(Category.allCases, id: \.self) { category in
                    FilterChip(
                        title: category.rawValue,
                        isSelected: selectedCategory == category
                    ) {
                        selectedCategory = category
                    }
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
        }
        .background(Color(UIColor.systemGroupedBackground))
    }
    
    private func loadHistory() {
        completedLists = PersistenceManager.shared.loadCompleted()
            .sorted { $0.createdDate > $1.createdDate }
    }
    
    private func deleteLists(at offsets: IndexSet) {
        for index in offsets {
            PersistenceManager.shared.deleteCompleted(withId: filteredLists[index].id)
        }
        loadHistory()
    }
}

private func completionDay(for list: IdeaList) -> Date {
    // Prefer modifiedDate as completion timestamp; fallback to createdDate
    let date = list.modifiedDate
    return Calendar.current.startOfDay(for: date)
}

private func groupListsByDay(_ lists: [IdeaList]) -> [Date: [IdeaList]] {
    var dict: [Date: [IdeaList]] = [:]
    for list in lists where list.isComplete {
        let day = completionDay(for: list)
        dict[day, default: []].append(list)
    }
    return dict
}

enum ViewMode { case list, calendar }

struct HistoryCalendarView: View {
    @Binding var month: Date
    let listsByDay: [Date: [IdeaList]]
    let onSelectList: (IdeaList) -> Void
    let onSelectDay: (Date) -> Void
    
    private var monthInterval: DateInterval {
        Calendar.current.dateInterval(of: .month, for: month)!
    }
    
    private var days: [Date?] {
        let calendar = Calendar.current
        let start = monthInterval.start
        let range = calendar.range(of: .day, in: .month, for: start)!
        let firstWeekday = calendar.component(.weekday, from: start) // 1..7
        let leadingEmpty = (firstWeekday - calendar.firstWeekday + 7) % 7
        let total = leadingEmpty + range.count
        return (0..<total).map { index in
            if index < leadingEmpty { return nil }
            let dayOffset = index - leadingEmpty
            return calendar.date(byAdding: .day, value: dayOffset, to: start)!
        }
    }
    
    private var weekdaySymbols: [String] {
        let symbols = Calendar.current.shortStandaloneWeekdaySymbols
        // Reorder based on firstWeekday
        let first = Calendar.current.firstWeekday - 1
        return Array(symbols[first...] + symbols[..<first])
    }
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Button { changeMonth(-1) } label: { Image(systemName: "chevron.left") }
                Spacer()
                Text(month, style: .date)
                    .font(.headline)
                    .id(monthInterval.start)
                Spacer()
                Button { changeMonth(1) } label: { Image(systemName: "chevron.right") }
            }
            .padding(.vertical, 4)
            
            // Weekday headers
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 4), count: 7), spacing: 6) {
                ForEach(weekdaySymbols, id: \.self) { wd in
                    Text(wd.uppercased())
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity)
                }
                
                ForEach(Array(days.enumerated()), id: \.offset) { _, date in
                    DayCell(date: date, lists: listsForDay(date)) { d in
                        if let d { onSelectDay(d) }
                    }
                }
            }
        }
    }
    
    private func changeMonth(_ delta: Int) {
        if let newMonth = Calendar.current.date(byAdding: .month, value: delta, to: month) {
            month = newMonth
        }
    }
    
    private func listsForDay(_ date: Date?) -> [IdeaList] {
        guard let date else { return [] }
        let key = Calendar.current.startOfDay(for: date)
        return listsByDay[key] ?? []
    }
}

private struct DayCell: View {
    let date: Date?
    let lists: [IdeaList]
    let onTap: (Date?) -> Void
    
    var body: some View {
        Button {
            onTap(date)
        } label: {
            VStack(spacing: 4) {
                if let date {
                    Text("\(Calendar.current.component(.day, from: date))")
                        .font(.callout)
                        .foregroundColor(.primary)
                        .frame(maxWidth: .infinity)
                    if !lists.isEmpty {
                        Circle()
                            .fill(Color.blue)
                            .frame(width: 6, height: 6)
                    } else {
                        Circle()
                            .fill(Color.clear)
                            .frame(width: 6, height: 6)
                    }
                } else {
                    Text("")
                        .frame(maxWidth: .infinity)
                    Circle()
                        .fill(Color.clear)
                        .frame(width: 6, height: 6)
                }
            }
            .padding(.vertical, 6)
            .frame(minHeight: 36)
        }
        .buttonStyle(.plain)
        .disabled(date == nil)
    }
}

private struct DayListsSheet: View {
    let date: Date
    let lists: [IdeaList]
    let onOpen: (IdeaList) -> Void
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            List(lists) { list in
                HistoryRow(ideaList: list) { onOpen(list) }
            }
            .navigationTitle(date.formatted(date: .abbreviated, time: .omitted))
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

struct HistoryRow: View {
    let ideaList: IdeaList
    let onTap: () -> Void
    
    private var filledIdeas: [String] {
        ideaList.ideas.filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
    }
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: ideaList.prompt.category.icon)
                        .foregroundColor(ideaList.prompt.category.colorValue)
                        .font(.title3)
                    
                    Text(ideaList.prompt.formattedTitle)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                        .font(.caption)
                }
                
                Text(ideaList.createdDate.formatted(date: .long, time: .shortened))
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                if filledIdeas.count > 0 {
                    VStack(alignment: .leading, spacing: 4) {
                        ForEach(Array(filledIdeas.prefix(3).enumerated()), id: \.offset) { index, idea in
                            HStack(alignment: .top, spacing: 4) {
                                Text("\(index + 1).")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .frame(width: 20, alignment: .trailing)
                                
                                Text(idea)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .lineLimit(1)
                            }
                        }
                        
                        if filledIdeas.count > 3 {
                            Text("+ \(filledIdeas.count - 3) more...")
                                .font(.caption)
                                .foregroundColor(.blue)
                        }
                    }
                    .padding(.top, 4)
                }
            }
            .padding(.vertical, 8)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.caption)
                .fontWeight(.medium)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(isSelected ? Color.blue : Color(UIColor.systemGray5))
                .foregroundColor(isSelected ? .white : .primary)
                .clipShape(Capsule())
        }
    }
}

struct IdeaListDetailView: View {
    let ideaList: IdeaList
    @Environment(\.dismiss) private var dismiss
    @State private var showingShareSheet = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    headerSection
                    
                    Divider()
                    
                    ideasSection
                }
                .padding()
            }
            .navigationTitle("Idea List Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingShareSheet = true
                    }) {
                        Image(systemName: "square.and.arrow.up")
                    }
                }
            }
        }
        .sheet(isPresented: $showingShareSheet) {
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let _ = windowScene.windows.first?.rootViewController {
                ShareSheet(activityItems: [ideaList.formattedForExport])
            }
        }
    }
    
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: ideaList.prompt.category.icon)
                    .foregroundColor(ideaList.prompt.category.colorValue)
                    .font(.title)
                
                Text(ideaList.prompt.formattedTitle)
                    .font(.title2)
                    .fontWeight(.bold)
            }
            
            Label(ideaList.prompt.category.rawValue, systemImage: "tag.fill")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Label(
                ideaList.createdDate.formatted(date: .long, time: .shortened),
                systemImage: "calendar"
            )
            .font(.caption)
            .foregroundColor(.secondary)
        }
    }
    
    private var ideasSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Ideas")
                .font(.headline)
            
            ForEach(Array(ideaList.ideas.enumerated()), id: \.offset) { index, idea in
                if !idea.isEmpty {
                    HStack(alignment: .top, spacing: 8) {
                        Text("\(index + 1).")
                            .font(.body)
                            .fontWeight(.medium)
                            .foregroundColor(.secondary)
                            .frame(width: 30, alignment: .trailing)
                        
                        Text(idea)
                            .font(.body)
                            .fixedSize(horizontal: false, vertical: true)
                        
                        Spacer()
                    }
                    .padding(.vertical, 4)
                }
            }
        }
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
