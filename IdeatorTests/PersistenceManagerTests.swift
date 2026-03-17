import XCTest
@testable import Ideator

final class PersistenceManagerTests: XCTestCase {
    private var manager: PersistenceManager!

    override func setUp() {
        super.setUp()
        manager = PersistenceManager.shared
        manager.clearAll()
    }

    override func tearDown() {
        manager.clearAll()
        super.tearDown()
    }

    // MARK: - Helpers

    private func makePrompt(text: String = "Test prompt") -> Prompt {
        let cat = FlexibleCategory(id: "test", name: "Test", icon: "star", color: "blue", packId: nil, packName: nil)
        return Prompt(text: text, flexibleCategory: cat)
    }

    private func makeIdeaList(promptText: String = "Test prompt", ideas: [String] = ["Idea 1"], isComplete: Bool = false) -> IdeaList {
        let prompt = makePrompt(text: promptText)
        return IdeaList(prompt: prompt, ideas: ideas, isComplete: isComplete)
    }

    // MARK: - Drafts

    func testSaveDraft_loadDrafts_roundTrip() {
        let draft = makeIdeaList(promptText: "Draft prompt", ideas: ["Alpha"])
        manager.saveDraft(draft)

        let loaded = manager.loadDrafts()
        XCTAssertEqual(loaded.count, 1)
        XCTAssertEqual(loaded[0].id, draft.id)
        XCTAssertEqual(loaded[0].ideas, ["Alpha"])
    }

    func testDeleteDraft_removesCorrectItem() {
        let draft1 = makeIdeaList(promptText: "First")
        let draft2 = makeIdeaList(promptText: "Second")
        manager.saveDraft(draft1)
        manager.saveDraft(draft2)
        XCTAssertEqual(manager.loadDrafts().count, 2)

        manager.deleteDraft(withId: draft1.id)

        let remaining = manager.loadDrafts()
        XCTAssertEqual(remaining.count, 1)
        XCTAssertEqual(remaining[0].id, draft2.id)
    }

    func testGetDraft_returnsMatchingDraft() {
        let prompt = makePrompt(text: "Specific prompt")
        let draft = IdeaList(prompt: prompt, ideas: ["Match me"])
        manager.saveDraft(draft)

        let found = manager.getDraft(for: prompt)
        XCTAssertEqual(found?.id, draft.id)
        XCTAssertEqual(found?.ideas, ["Match me"])
    }

    func testGetDraft_returnsNilWhenNoMatch() {
        let prompt = makePrompt(text: "Missing prompt")
        let result = manager.getDraft(for: prompt)
        XCTAssertNil(result)
    }

    // MARK: - Completed

    func testSaveCompleted_loadCompleted_roundTrip() {
        let list = makeIdeaList(promptText: "Completed prompt", ideas: ["Done"], isComplete: true)
        manager.saveCompleted(list)

        let loaded = manager.loadCompleted()
        XCTAssertEqual(loaded.count, 1)
        XCTAssertEqual(loaded[0].id, list.id)
        XCTAssertEqual(loaded[0].isComplete, true)
    }

    func testSaveCompleted_removesDraft() {
        let list = makeIdeaList(promptText: "WIP", ideas: ["Draft idea"])
        manager.saveDraft(list)
        XCTAssertEqual(manager.loadDrafts().count, 1)

        var completed = list
        completed.isComplete = true
        manager.saveCompleted(completed)

        XCTAssertEqual(manager.loadDrafts().count, 0)
        XCTAssertEqual(manager.loadCompleted().count, 1)
    }

    func testDeleteCompleted_removesCorrectItem() {
        let list1 = makeIdeaList(promptText: "First done")
        let list2 = makeIdeaList(promptText: "Second done")
        manager.saveCompleted(list1)
        manager.saveCompleted(list2)
        XCTAssertEqual(manager.loadCompleted().count, 2)

        manager.deleteCompleted(withId: list1.id)

        let remaining = manager.loadCompleted()
        XCTAssertEqual(remaining.count, 1)
        XCTAssertEqual(remaining[0].id, list2.id)
    }

    // MARK: - Custom Prompts

    func testSaveCustomPrompt_deduplicatesByText() {
        let prompt = makePrompt(text: "Unique idea")
        manager.saveCustomPrompt(prompt)
        manager.saveCustomPrompt(prompt)

        let loaded = manager.loadCustomPrompts()
        XCTAssertEqual(loaded.count, 1)
    }

    func testSaveCustomPrompt_allowsDifferentText() {
        let prompt1 = makePrompt(text: "Idea A")
        let prompt2 = makePrompt(text: "Idea B")
        manager.saveCustomPrompt(prompt1)
        manager.saveCustomPrompt(prompt2)

        let loaded = manager.loadCustomPrompts()
        XCTAssertEqual(loaded.count, 2)
    }

    // MARK: - clearAll

    func testClearAll_removesEverything() {
        manager.saveDraft(makeIdeaList(promptText: "Draft"))
        manager.saveCompleted(makeIdeaList(promptText: "Completed"))
        manager.saveCustomPrompt(makePrompt(text: "Custom"))

        manager.clearAll()

        XCTAssertEqual(manager.loadDrafts().count, 0)
        XCTAssertEqual(manager.loadCompleted().count, 0)
        XCTAssertEqual(manager.loadCustomPrompts().count, 0)
    }
}
