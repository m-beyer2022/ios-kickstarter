import Foundation
@testable import KsApi
@testable import Library
import Prelude
import ReactiveExtensions_TestHelpers
import ReactiveSwift
import XCTest

internal final class PaymentMethodsViewModelTests: TestCase {
  private let vm = PaymentMethodsViewModel()
  private let userTemplate = GraphUser.template |> \.storedCards .~ GraphUserCreditCard.template
  private let editButtonIsEnabled = TestObserver<Bool, Never>()
  private let editButtonTitle = TestObserver<String, Never>()
  private let errorLoadingPaymentMethods = TestObserver<String, Never>()
  private let goToAddCardScreenWithIntent = TestObserver<AddNewCardIntent, Never>()
  private let paymentMethods = TestObserver<[GraphUserCreditCard.CreditCard], Never>()
  private let presentBanner = TestObserver<String, Never>()
  private let reloadData = TestObserver<Void, Never>()
  private let showAlert = TestObserver<String, Never>()
  private let tableViewIsEditing = TestObserver<Bool, Never>()

  internal override func setUp() {
    super.setUp()

    self.vm.outputs.editButtonIsEnabled.observe(self.editButtonIsEnabled.observer)
    self.vm.outputs.editButtonTitle.observe(self.editButtonTitle.observer)
    self.vm.outputs.errorLoadingPaymentMethods.observe(self.errorLoadingPaymentMethods.observer)
    self.vm.outputs.goToAddCardScreenWithIntent.observe(self.goToAddCardScreenWithIntent.observer)
    self.vm.outputs.paymentMethods.observe(self.paymentMethods.observer)
    self.vm.outputs.presentBanner.observe(self.presentBanner.observer)
    self.vm.outputs.reloadData.observe(self.reloadData.observer)
    self.vm.outputs.showAlert.observe(self.showAlert.observer)
    self.vm.outputs.tableViewIsEditing.observe(self.tableViewIsEditing.observer)
  }

  func testPaymentMethodsFetch_OnViewDidLoad() {
    let response = UserEnvelope<GraphUser>(me: userTemplate)
    let apiService = MockService(fetchGraphUserResult: .success(response))

    withEnvironment(apiService: apiService) {
      self.vm.inputs.viewDidLoad()

      self.reloadData.assertDidEmitValue()

      self.scheduler.advance()

      self.paymentMethods.assertValues([GraphUserCreditCard.template.storedCards])
    }
  }

  func testPaymentMethodsFetch_errorFetchingPaymentMethods() {
    let apiService = MockService(fetchGraphUserResult: .failure(.couldNotParseJSON))

    withEnvironment(apiService: apiService) {
      self.vm.inputs.viewDidLoad()

      self.reloadData.assertDidEmitValue()

      self.scheduler.advance()

      self.errorLoadingPaymentMethods.assertValue(ErrorEnvelope.couldNotParseJSON.localizedDescription)
      self.paymentMethods.assertDidNotEmitValue()
    }
  }

  func testPaymentMethodsFetch_OnAddNewCardSucceeded() {
    let response = UserEnvelope<GraphUser>(me: userTemplate)
    let apiService = MockService(fetchGraphUserResult: .success(response))

    withEnvironment(apiService: apiService) {
      self.paymentMethods.assertValues([])

      self.vm.inputs.addNewCardSucceeded(with: "First card added successfully")

      self.scheduler.advance()

      self.paymentMethods.assertValueCount(1)

      withEnvironment(apiService: apiService) {
        self.vm.inputs.addNewCardSucceeded(with: "Second card added successfully")

        self.scheduler.advance()

        self.paymentMethods.assertValueCount(2)
      }
    }
  }

  func testPaymentMethodsFetch_OnAddNewCardDismissed() {
    let response = UserEnvelope<GraphUser>(me: userTemplate)
    let apiService = MockService(fetchGraphUserResult: .success(response))

    withEnvironment(apiService: apiService) {
      self.paymentMethods.assertValues([])

      self.vm.inputs.addNewCardDismissed()

      self.scheduler.advance()

      self.paymentMethods.assertValues([GraphUserCreditCard.template.storedCards])
    }
  }

  func testEditButtonIsNotEnabled_OnViewDidLoad() {
    self.editButtonIsEnabled.assertDidNotEmitValue()
    self.vm.viewDidLoad()
    self.editButtonIsEnabled.assertValue(false)
  }

  func testEditButtonIsEnabledAndTitle_HasPaymentMethods() {
    let response = UserEnvelope<GraphUser>(me: GraphUser.template)
    let apiService = MockService(fetchGraphUserResult: .success(response))
    withEnvironment(apiService: apiService) {
      self.editButtonIsEnabled.assertDidNotEmitValue()
      self.editButtonTitle.assertDidNotEmitValue()

      self.vm.inputs.viewDidLoad()
      self.editButtonIsEnabled.assertValues([false])
      self.editButtonTitle.assertValues(["Edit"])

      self.scheduler.advance()

      self.editButtonIsEnabled.assertValues([false, true])
      self.editButtonTitle.assertValues(["Edit"])

      self.vm.inputs.editButtonTapped()
      self.editButtonIsEnabled.assertValues([false, true])
      self.editButtonTitle.assertValues(["Edit", "Done"])

      self.vm.inputs.editButtonTapped()
      self.editButtonIsEnabled.assertValues([false, true])
      self.editButtonTitle.assertValues(["Edit", "Done", "Edit"])
    }
  }

  func testEditButtonIsNotEnabled_NoPaymentMethods() {
    let emptyTemplate = GraphUser.template |> \.storedCards .~ .emptyTemplate
    let response = UserEnvelope<GraphUser>(me: emptyTemplate)
    let apiService = MockService(fetchGraphUserResult: .success(response))
    withEnvironment(apiService: apiService) {
      self.editButtonIsEnabled.assertDidNotEmitValue()
      self.vm.inputs.viewDidLoad()

      self.editButtonIsEnabled.assertValues([false])

      self.scheduler.advance()

      self.editButtonIsEnabled.assertValues([false])
    }
  }

  func testEditButtonEnabled_AfterDeletePaymentMethod() {
    guard let card = GraphUserCreditCard.template.storedCards.first else {
      XCTFail("Card should exist")
      return
    }

    let result = DeletePaymentMethodEnvelope(storedCards: [card])
    let response = UserEnvelope<GraphUser>(me: userTemplate)
    let apiService = MockService(
      deletePaymentMethodResult: .success(result),
      fetchGraphUserResult: .success(response)
    )
    withEnvironment(apiService: apiService) {
      self.editButtonIsEnabled.assertDidNotEmitValue()

      self.vm.inputs.viewDidLoad()

      self.editButtonIsEnabled.assertValues([false])

      self.scheduler.advance()

      self.editButtonIsEnabled.assertValues([false, true])

      self.vm.inputs.didDelete(card, visibleCellCount: 1)

      self.editButtonIsEnabled.assertValues([false, true])

      self.scheduler.advance()

      self.editButtonIsEnabled.assertValues([false, true])
    }
  }

  func testEditButtonNotEnabled_AfterDeleteLastPaymentMethod() {
    guard let card = GraphUserCreditCard.template.storedCards.first else {
      XCTFail("Card should exist")
      return
    }

    let result = DeletePaymentMethodEnvelope(storedCards: [])
    let response = UserEnvelope<GraphUser>(me: userTemplate)
    let apiService = MockService(
      deletePaymentMethodResult: .success(result),
      fetchGraphUserResult: .success(response)
    )
    withEnvironment(apiService: apiService) {
      self.editButtonIsEnabled.assertDidNotEmitValue()

      self.vm.inputs.viewDidLoad()

      self.editButtonIsEnabled.assertValues([false])

      self.scheduler.advance()

      self.editButtonIsEnabled.assertValues([false, true])

      self.vm.inputs.didDelete(card, visibleCellCount: 0)

      self.editButtonIsEnabled.assertValues([false, true, false])

      self.scheduler.advance()

      self.editButtonIsEnabled.assertValues([false, true, false])
    }
  }

  func testGoToAddCardScreenEmits_WhenAddNewCardIsTapped() {
    self.goToAddCardScreenWithIntent.assertValueCount(0)

    self.vm.inputs.paymentMethodsFooterViewDidTapAddNewCardButton()

    self.goToAddCardScreenWithIntent.assertValues([.settings], "Should emit after tapping button")
  }

  func testTableViewIsEditing_isFalse_WhenAddNewCardIsPresented() {
    self.tableViewIsEditing.assertValueCount(0)

    self.vm.inputs.viewDidLoad()
    self.vm.inputs.editButtonTapped()

    self.tableViewIsEditing.assertValues([false, true])

    self.vm.inputs.addNewCardPresented()

    self.tableViewIsEditing.assertValues([false, true, false])
  }

  func testPresentMessageBanner() {
    self.presentBanner.assertValues([])

    self.vm.inputs.addNewCardSucceeded(with: Strings.Got_it_your_changes_have_been_saved())

    self.presentBanner.assertValues([Strings.Got_it_your_changes_have_been_saved()])
  }

  func testDeletePaymentMethod() {
    guard let card = GraphUserCreditCard.template.storedCards.first else {
      XCTFail("Card should exist")
      return
    }

    let result = DeletePaymentMethodEnvelope(storedCards: GraphUserCreditCard.template.storedCards)
    let response = UserEnvelope<GraphUser>(me: userTemplate)
    let apiService = MockService(
      deletePaymentMethodResult: .success(result),
      fetchGraphUserResult: .success(response)
    )
    withEnvironment(apiService: apiService) {
      self.vm.inputs.viewDidLoad()

      self.scheduler.advance()

      self.tableViewIsEditing.assertValues([false])
      self.showAlert.assertValues([])
      self.paymentMethods.assertValues([GraphUserCreditCard.template.storedCards])

      self.vm.inputs.editButtonTapped()

      self.tableViewIsEditing.assertValues([false, true], "Editing mode enabled")
      self.showAlert.assertValues([])
      self.paymentMethods.assertValues([GraphUserCreditCard.template.storedCards])

      self.vm.inputs.didDelete(card, visibleCellCount: 1)
      self.scheduler.advance()

      self.tableViewIsEditing.assertValues([false, true], "Editing mode remains enabled")
      self.showAlert.assertValues([], "No errors emitted")
      self.paymentMethods.assertValues(
        [GraphUserCreditCard.template.storedCards],
        "Emits once"
      )
    }
  }

  func testDeletePaymentMethod_Error() {
    guard let card = GraphUserCreditCard.template.storedCards.first else {
      XCTFail("Card should exist")
      return
    }

    let response = UserEnvelope<GraphUser>(me: userTemplate)
    let apiService = MockService(
      deletePaymentMethodResult: .failure(.invalidInput),
      fetchGraphUserResult: .success(response)
    )
    withEnvironment(apiService: apiService) {
      self.vm.inputs.viewDidLoad()

      self.scheduler.advance()

      self.tableViewIsEditing.assertValues([false])
      self.showAlert.assertValues([])
      self.paymentMethods.assertValues([GraphUserCreditCard.template.storedCards])

      self.vm.inputs.editButtonTapped()

      self.tableViewIsEditing.assertValues([false, true], "Editing mode enabled")
      self.showAlert.assertValues([])
      self.paymentMethods.assertValues([GraphUserCreditCard.template.storedCards])

      self.vm.inputs.didDelete(card, visibleCellCount: 1)
      self.scheduler.advance()

      self.tableViewIsEditing.assertValues([false, true], "Editing mode remains enabled")
      self.showAlert.assertValues([
        "Something went wrong and we were unable to remove your payment method, please try again."
      ])
      self.paymentMethods.assertValues(
        [GraphUserCreditCard.template.storedCards, GraphUserCreditCard.template.storedCards],
        "Emits again to reload the tableview after an error occurred"
      )
    }
  }

  func testDeletePaymentMethod_SuccessThenError() {
    guard let card = GraphUserCreditCard.template.storedCards.first else {
      XCTFail("Card should exist")
      return
    }

    let result1 = DeletePaymentMethodEnvelope(storedCards: [card, card])
    let response = UserEnvelope<GraphUser>(me: userTemplate)
    let apiService1 = MockService(
      deletePaymentMethodResult: .success(result1),
      fetchGraphUserResult: .success(response)
    )
    withEnvironment(apiService: apiService1) {
      self.vm.inputs.viewDidLoad()

      self.scheduler.advance()

      self.tableViewIsEditing.assertValues([false])
      self.showAlert.assertValues([])
      self.paymentMethods.assertValues([GraphUserCreditCard.template.storedCards])
      self.editButtonIsEnabled.assertValues([false, true], "Edit button enabled, we have cards")

      self.vm.inputs.editButtonTapped()

      self.tableViewIsEditing.assertValues([false, true], "Editing mode enabled")
      self.showAlert.assertValues([])
      self.paymentMethods.assertValues([GraphUserCreditCard.template.storedCards])

      self.vm.inputs.didDelete(card, visibleCellCount: 1)
      self.editButtonIsEnabled.assertValues([false, true], "Editing button remains enabled")

      self.scheduler.advance()

      self.tableViewIsEditing.assertValues([false, true], "Editing mode remains enabled")
      self.showAlert.assertValues([])
    }

    let response2 = UserEnvelope<GraphUser>(me: userTemplate)
    let apiService2 = MockService(
      deletePaymentMethodResult: .failure(.invalidInput),
      fetchGraphUserResult: .success(response2)
    )

    withEnvironment(apiService: apiService2) {
      self.vm.inputs.didDelete(card, visibleCellCount: 0)

      self.editButtonIsEnabled.assertValues(
        [false, true, false], "Editing button disabled as last card removed"
      )
      self.tableViewIsEditing.assertValues([false, true, false], "Editing mode disabled as last card removed")

      self.scheduler.advance()
      self.showAlert.assertValues([
        "Something went wrong and we were unable to remove your payment method, please try again."
      ])
      self.paymentMethods.assertValues(
        [GraphUserCreditCard.template.storedCards, result1.storedCards],
        "Emits again with the results from the last successful deletion to reload the tableview after an error occurred"
      )

      self.vm.addNewCardDismissed()
      self.scheduler.advance()

      self.editButtonIsEnabled.assertValues(
        [false, true, false, true], "Editing mode disabled as last card removal failed"
      )
      self.tableViewIsEditing.assertValues(
        [false, true, false], "Editing mode reenabled as last card removal failed"
      )
      self.paymentMethods.assertValues(
        [
          GraphUserCreditCard.template.storedCards,
          result1.storedCards,
          GraphUserCreditCard.template.storedCards
        ],
        "Cards are refreshed normally"
      )
    }
  }
}
