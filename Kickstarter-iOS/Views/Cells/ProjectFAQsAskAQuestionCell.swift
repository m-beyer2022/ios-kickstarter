import Library
import Prelude
import UIKit

final class ProjectFAQsAskAQuestionCell: UITableViewCell, ValueCell {
  // MARK: - Properties

  private lazy var messageImageView: UIImageView = {
    UIImageView(frame: .zero)
      |> \.translatesAutoresizingMaskIntoConstraints .~ false
  }()

  private lazy var rootStackView = {
    UIStackView(frame: .zero)
      |> \.translatesAutoresizingMaskIntoConstraints .~ false
  }()

  private lazy var titleTextLabel: UILabel = {
    UILabel(frame: .zero)
      |> \.translatesAutoresizingMaskIntoConstraints .~ false
  }()

  // MARK: - Lifecycle

  override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
    super.init(style: style, reuseIdentifier: reuseIdentifier)

    self.bindStyles()
    self.configureViews()
  }

  required init?(coder _: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  // MARK: - Styles

  override func bindStyles() {
    super.bindStyles()

    _ = self
      |> baseTableViewCellStyle()

    _ = self.messageImageView
      |> messageImageViewStyle

    _ = self.rootStackView
      |> rootStackViewStyle

    _ = self.titleTextLabel
      |> titleTextLabelStyle
  }

  // MARK: - Configuration

  func configureWith(value _: Void) {
    return
  }

  private func configureViews() {
    _ = (self.rootStackView, self.contentView)
      |> ksr_addSubviewToParent()
      |> ksr_constrainViewToMarginsInParent()

    _ = ([self.messageImageView, self.titleTextLabel, UIView()], self.rootStackView)
      |> ksr_addArrangedSubviewsToStackView()
  }
}

// MARK: - Styles

private let messageImageViewStyle: ImageViewStyle = { imageView in
  imageView
    |> \.backgroundColor .~ .ksr_support_100
    |> \.contentMode .~ .scaleAspectFit
    |> \.image .~ image(named: "icon_message")
    |> \.layer.cornerRadius .~ Styles.grid(1)
}

private let rootStackViewStyle: StackViewStyle = { stackView in
  stackView
    |> \.axis .~ .horizontal
    |> \.layoutMargins .~ .init(topBottom: Styles.grid(3), leftRight: Styles.grid(1))
    |> \.insetsLayoutMarginsFromSafeArea .~ false
    |> \.isLayoutMarginsRelativeArrangement .~ true
    |> \.spacing .~ Styles.grid(1)
}

// TODO: - Internationalize strings
private let titleTextLabelStyle: LabelStyle = { label in
  label
    |> \.font .~ UIFont.ksr_callout().bolded
    |> \.numberOfLines .~ 1
    |> \.textColor .~ .ksr_create_700
    |> \.text .~ "Ask a question"
}
