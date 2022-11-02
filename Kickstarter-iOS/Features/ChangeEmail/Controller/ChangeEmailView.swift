import Library
import SwiftUI

@available(iOS 15.0, *)
struct ChangeEmailView: View {
  @State var emailText: String
  @State private var newEmailText = ""
  @State private var passwordText = ""
  @SwiftUI.Environment(\.defaultMinListRowHeight) var minListRow

  init(emailText: String) {
    self.emailText = emailText
  }

  var body: some View {
    List {
      Color(.ksr_support_100)
        .frame(width: .infinity, height: minListRow, alignment: .center)
        .listRowSeparator(.hidden)
        .listRowInsets(EdgeInsets())

      VStack(alignment: .center, spacing: 0) {
        entryField(
          titleText: Strings.Current_email(),
          placeholderText: "",
          secureField: false,
          valueText: $emailText
        )
        .currentEmail()
        Color(.ksr_cell_separator).frame(width: .infinity, height: 1)
      }
      .listRowSeparator(.hidden)
      .listRowInsets(EdgeInsets())

      Color(.ksr_support_100)
        .frame(width: .infinity, height: minListRow, alignment: .center)
        .listRowSeparator(.hidden)
        .listRowInsets(EdgeInsets())

      VStack(alignment: .center, spacing: 0) {
        entryField(
          titleText: Strings.New_email(),
          placeholderText: Strings.login_placeholder_email(),
          secureField: false,
          valueText: $newEmailText
        )
        .newEmail()
        entryField(
          titleText: Strings.Current_password(),
          placeholderText: Strings.login_placeholder_password(),
          secureField: true,
          valueText: $passwordText
        )
        .currentPassword()
        Color(.ksr_cell_separator).frame(width: .infinity, height: 1)
      }
      .listRowSeparator(.hidden)
      .listRowInsets(EdgeInsets())
    }
    .navigationTitle(Strings.Change_email())
    .background(Color(.ksr_support_100))
    .listStyle(.plain)
  }

  @ViewBuilder
  private func entryField(titleText: String,
                          placeholderText: String,
                          secureField: Bool,
                          valueText: Binding<String>) -> some View {
    HStack {
      Text(titleText)
        .frame(
          maxWidth: .infinity,
          alignment: .leading
        )
        .font(Font(UIFont.ksr_body()))
        .foregroundColor(Color(.ksr_support_700))
      Spacer()

      newEntryField(secureField: secureField, placeholderText: placeholderText, valueText: valueText)
    }
    .padding(12)
    .accessibilityElement(children: .combine)
    .accessibilityLabel(titleText)
  }

  @ViewBuilder
  private func newEntryField(secureField: Bool,
                             placeholderText: String,
                             valueText: Binding<String>) -> some View {
    if secureField {
      SecureField(
        "",
        text: valueText,
        prompt: Text(placeholderText).foregroundColor(Color(.ksr_support_400))
      )
    } else {
      TextField(
        "",
        text: valueText,
        prompt:
        Text(placeholderText).foregroundColor(Color(.ksr_support_400))
      )
    }
  }
}

@available(iOS 15.0, *)
struct EntryFieldModifier: ViewModifier {
  let keyboardType: UIKeyboardType
  let textColor: Color
  let submitLabel: SubmitLabel
  let editable: Bool
  let titleText: String

  func body(content: Content) -> some View {
    content
      .frame(
        maxWidth: .infinity,
        alignment: .trailing
      )
      .keyboardType(self.keyboardType)
      .font(Font(UIFont.ksr_body()))
      .foregroundColor(self.textColor)
      .lineLimit(1)
      .multilineTextAlignment(.trailing)
      .submitLabel(self.submitLabel)
      .disabled(!self.editable)
      .accessibilityElement()
      .accessibilityLabel(self.titleText)
  }
}

@available(iOS 15.0, *)
extension View {
  func currentEmail(keyboardType: UIKeyboardType = .default,
                    textColor: Color = Color(.ksr_support_700),
                    submitLabel: SubmitLabel = .return,
                    editable: Bool = false,
                    titleText: String = Strings.Current_email()) -> some View {
    modifier(EntryFieldModifier(
      keyboardType: keyboardType,
      textColor: textColor,
      submitLabel: submitLabel,
      editable: editable,
      titleText: titleText
    ))
  }

  func newEmail(keyboardType: UIKeyboardType = .emailAddress,
                textColor: Color = Color(.ksr_support_400),
                submitLabel: SubmitLabel = .return,
                editable: Bool = true,
                titleText: String = Strings.New_email()) -> some View {
    modifier(EntryFieldModifier(
      keyboardType: keyboardType,
      textColor: textColor,
      submitLabel: submitLabel,
      editable: editable,
      titleText: titleText
    ))
  }

  func currentPassword(keyboardType: UIKeyboardType = .default,
                       textColor: Color = Color(.ksr_support_400),
                       submitLabel: SubmitLabel = .done,
                       editable: Bool = true,
                       titleText: String = Strings.Current_password()) -> some View {
    modifier(EntryFieldModifier(
      keyboardType: keyboardType,
      textColor: textColor,
      submitLabel: submitLabel,
      editable: editable,
      titleText: titleText
    ))
  }
}
