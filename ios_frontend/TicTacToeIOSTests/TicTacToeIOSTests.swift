import XCTest
@testable import TicTacToeIOS

final class TicTacToeIOSTests: XCTestCase {
    func testResetClearsBoard() {
        let vm = GameViewModel()
        vm.tapCell(at: 0)
        vm.tapCell(at: 1)
        vm.reset()
        XCTAssertEqual(vm.cellTitle(at: 0), "")
        XCTAssertEqual(vm.cellTitle(at: 1), "")
    }
}
