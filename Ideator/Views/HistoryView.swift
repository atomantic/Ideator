import SwiftUI

struct HistoryView: View {
    let promptViewModel: PromptViewModel
    @State private var completedLists: [IdeaList] = []
    @State private var selectedList: IdeaList?
    @State private var searchText = ""
    @State private var selectedFlexibleCategory: FlexibleCategory?
    @State private var viewMode: ViewMode = .list
    @State private var lastViewModeBeforeSearch: ViewMode?
    @State private var calendarMonth: Date = Date()
    @State private var daySelection: DaySelection?
    
    init(promptViewModel: PromptViewModel) {
        self.promptViewModel = promptViewModel
    }
    
    var filteredLists: [IdeaList] {
        var lists = completedLists
        
        if let flexCategory = selectedFlexibleCategory {
            lists = lists.filter { $0.prompt.flexibleCategory.id == flexCategory.id }
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
                        } else {
                            // Wrap calendar in a List to align layout behavior with List mode
                            List {
                                Section {
                                    HistoryCalendarView(
                                        month: $calendarMonth,
                                        listsByDay: groupListsByDay(filteredLists),
                                        onSelectList: { list in selectedList = list },
                                        onSelectDay: { date in
                                            daySelection = DaySelection(date: date)
                                        }
                                    )
                                    .padding(.horizontal, 12)
                                    .listRowInsets(EdgeInsets())
                                    .listRowSeparator(.hidden)
                                }
                            }
                            .listStyle(PlainListStyle())
                            .scrollContentBackground(.hidden)
                            .sheet(item: $daySelection) { item in
                                let date = item.date
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
            .navigationTitle("History")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(
                text: $searchText,
                placement: .navigationBarDrawer(displayMode: .always),
                prompt: "Search ideas..."
            )
            .safeAreaInset(edge: .top) {
                if !completedLists.isEmpty {
                    VStack(spacing: 0) {
                        headerControls
                    }
                    .background(.ultraThinMaterial)
                }
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        // All categories option
                        Button(action: {
                            selectedFlexibleCategory = nil
                        }) {
                            HStack {
                                Label("All Categories", systemImage: "square.grid.2x2")
                                if selectedFlexibleCategory == nil {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.blue)
                                }
                            }
                        }
                        
                        Divider()
                        
                        // Group categories by pack
                        let groupedCategories = promptViewModel.getCategoriesGroupedByPack()
                        ForEach(Array(groupedCategories.enumerated()), id: \.offset) { _, group in
                            Section(group.packName ?? "Core") {
                                ForEach(group.categories, id: \.id) { flexCategory in
                                    Button(action: {
                                        selectedFlexibleCategory = flexCategory
                                    }) {
                                        HStack {
                                            Label(flexCategory.name, systemImage: flexCategory.icon)
                                            if selectedFlexibleCategory?.id == flexCategory.id {
                                                Image(systemName: "checkmark")
                                                    .foregroundColor(.blue)
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    } label: {
                        HStack(spacing: 4) {
                            if let selectedCategory = selectedFlexibleCategory {
                                Image(systemName: selectedCategory.icon)
                                    .foregroundColor(selectedCategory.colorValue)
                                Text(selectedCategory.name)
                                    .font(.caption)
                            } else {
                                Text("All")
                                    .font(.caption)
                            }
                            Image(systemName: "chevron.down")
                                .font(.caption2)
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color(UIColor.systemGray5))
                        .cornerRadius(8)
                    }
                }
            }
            .onAppear {
                loadHistory()
            }
            .onChange(of: searchText) { newValue in
                if newValue.isEmpty {
                    if let prev = lastViewModeBeforeSearch {
                        viewMode = prev
                        lastViewModeBeforeSearch = nil
                    }
                } else {
                    if viewMode != .list {
                        lastViewModeBeforeSearch = viewMode
                        viewMode = .list
                    }
                }
            }
            .sheet(item: $selectedList) { list in
                IdeaListDetailView(ideaList: list) { updatedList in
                    loadHistory()
                    selectedList = updatedList
                }
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
            .disabled(!searchText.isEmpty)
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "clock.arrow.circlepath")
                .font(.system(size: 80))
                .foregroundColor(.gray)
                .accessibilityHidden(true)
            
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
    
    
    private func loadHistory() {
        completedLists = PersistenceManager.shared.loadCompleted()
            .sorted { ($0.modifiedDate) > ($1.modifiedDate) }
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
        Calendar.current.dateInterval(of: .month, for: month)
            ?? DateInterval(start: month, end: month)
    }

    private var days: [Date?] {
        let calendar = Calendar.current
        let start = monthInterval.start
        guard let range = calendar.range(of: .day, in: .month, for: start) else {
            return []
        }
        let firstWeekday = calendar.component(.weekday, from: start) // 1..7
        let leadingEmpty = (firstWeekday - calendar.firstWeekday + 7) % 7
        let total = leadingEmpty + range.count
        return (0..<total).map { index in
            if index < leadingEmpty { return nil }
            let dayOffset = index - leadingEmpty
            return calendar.date(byAdding: .day, value: dayOffset, to: start)
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
                    .buttonStyle(.plain)
                Spacer()
                Text(month, format: .dateTime.year().month(.wide))
                    .font(.headline)
                    .id(monthInterval.start)
                Spacer()
                Button { changeMonth(1) } label: { Image(systemName: "chevron.right") }
                    .buttonStyle(.plain)
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
            let isToday = date.map { Calendar.current.isDateInToday($0) } ?? false
            VStack(spacing: 4) {
                if let date {
                    let hasLists = !lists.isEmpty
                    Text("\(Calendar.current.component(.day, from: date))")
                        .font(.callout)
                        .fontWeight(hasLists ? .semibold : .regular)
                        .foregroundColor(hasLists ? .primary : .secondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 2)
                    Circle()
                        .fill(hasLists ? Color.accentColor : Color.clear)
                        .frame(width: 6, height: 6)
                        .accessibilityHidden(true)
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
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(Color.blue.opacity(0.6), lineWidth: 1)
                    .opacity(isToday ? 1 : 0)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(date == nil)
    }
}

private struct DaySelection: Identifiable, Equatable {
    let date: Date
    var id: String { Self.key(for: date) }
    static func key(for date: Date) -> String {
        let day = Calendar.current.startOfDay(for: date)
        return ISO8601DateFormatter().string(from: day)
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
                    Image(systemName: ideaList.prompt.flexibleCategory.icon)
                        .foregroundColor(ideaList.prompt.flexibleCategory.colorValue)
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


