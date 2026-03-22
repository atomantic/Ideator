import XCTest
@testable import Ideator

@MainActor
final class IdeaListViewModelTests: XCTestCase {
    private var vm: IdeaListViewModel!
    private let testPrompt = Prompt(
        text: "Test prompt",
        category: .creative,
        suggestedCount: 3,
        slug: "test-prompt"
    )

    /// Use a unique slug per test run so drafts from prior runs don't pollute state
    private var uniquePrompt: Prompt {
        Prompt(
            text: "Test prompt \(UUID().uuidString.prefix(8))",
            category: .creative,
            suggestedCount: 3,
            slug: "test-prompt-\(UUID().uuidString.prefix(8))"
        )
    }

    override func setUp() {
        super.setUp()
        vm = IdeaListViewModel()
    }

    override func tearDown() {
        if let id = vm.currentIdeaList?.id {
            PersistenceManager.shared.deleteDraft(withId: id)
            PersistenceManager.shared.deleteCompleted(withId: id)
        }
        vm.resetList()
        super.tearDown()
    }

    func testStartNewList_setsCurrentIdeaList() {
        let prompt = uniquePrompt
        vm.startNewList(with: prompt)
        XCTAssertNotNil(vm.currentIdeaList)
        XCTAssertTrue(vm.currentIdeaList?.prompt.text.hasPrefix("Test prompt") ?? false)
        XCTAssertTrue(vm.ideas.isEmpty)
        XCTAssertFalse(vm.isComplete)
    }

    func testAddIdea_appendsToList() {
        vm.startNewList(with: uniquePrompt)
        vm.addIdea("First idea")
        XCTAssertEqual(vm.ideas.count, 1)
        XCTAssertEqual(vm.ideas[0], "First idea")
    }

    func testRemoveIdea_removesFromList() {
        vm.startNewList(with: uniquePrompt)
        vm.addIdea("Keep")
        vm.addIdea("Remove")
        XCTAssertEqual(vm.ideas.count, 2)
        vm.removeIdea(at: 1)
        XCTAssertEqual(vm.ideas, ["Keep"])
    }

    func testRemoveIdea_outOfBounds_doesNotCrash() {
        vm.startNewList(with: uniquePrompt)
        vm.addIdea("Only")
        vm.removeIdea(at: 5)
        XCTAssertEqual(vm.ideas.count, 1)
    }

    func testUpdateIdea_updatesText() {
        vm.startNewList(with: uniquePrompt)
        vm.addIdea("Original")
        vm.updateIdea(at: 0, with: "Updated")
        XCTAssertEqual(vm.ideas[0], "Updated")
    }

    func testUpdateIdea_outOfBounds_doesNotCrash() {
        vm.startNewList(with: uniquePrompt)
        // No ideas added, so index 10 is out of bounds
        vm.updateIdea(at: 10, with: "Nope")
        XCTAssertTrue(vm.ideas.isEmpty)
    }

    func testGetProgress_calculatesCorrectly() {
        vm.startNewList(with: uniquePrompt) // suggestedCount = 3
        XCTAssertEqual(vm.getProgress(), 0.0)

        vm.addIdea("One")
        XCTAssertEqual(vm.getProgress(), 1.0 / 3.0, accuracy: 0.01)

        vm.addIdea("Two")
        vm.addIdea("Three")
        XCTAssertEqual(vm.getProgress(), 1.0, accuracy: 0.01)
    }

    func testCheckIfComplete_returnsTrueWhenEnoughIdeas() {
        vm.startNewList(with: uniquePrompt) // suggestedCount = 3
        XCTAssertFalse(vm.checkIfComplete())

        vm.addIdea("One")
        vm.addIdea("Two")
        XCTAssertFalse(vm.checkIfComplete())

        vm.addIdea("Three")
        XCTAssertTrue(vm.checkIfComplete())
    }

    func testResetList_clearsEverything() {
        vm.startNewList(with: testPrompt)
        vm.addIdea("Test")
        vm.resetList()

        XCTAssertNil(vm.currentIdeaList)
        XCTAssertTrue(vm.ideas.isEmpty)
        XCTAssertFalse(vm.isComplete)
        XCTAssertFalse(vm.showExportSheet)
    }

    func testMarkAsComplete_setsCompletionState() {
        vm.startNewList(with: testPrompt)
        vm.addIdea("One")
        vm.addIdea("Two")
        vm.addIdea("Three")
        vm.markAsComplete()

        XCTAssertTrue(vm.isComplete)
        XCTAssertTrue(vm.currentIdeaList?.isComplete ?? false)
    }
}
