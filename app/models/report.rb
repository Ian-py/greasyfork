class Report < ApplicationRecord
  REASON_SPAM = 'spam'.freeze
  REASON_ABUSE = 'abuse'.freeze
  REASON_ILLEGAL = 'illegal'.freeze

  REASON_TEXT = {
    REASON_SPAM => 'spam',
    REASON_ABUSE => 'abusive or hateful content',
    REASON_ILLEGAL => 'malware or illegal content',
  }.freeze

  RESULT_DISMISSED = 'dismissed'.freeze
  RESULT_UPHELD = 'upheld'.freeze

  scope :unresolved, -> { where(result: nil) }

  belongs_to :item, polymorphic: true
  belongs_to :reporter, class_name: 'User', inverse_of: :reports_as_reporter

  validates :reason, inclusion: { in: [REASON_SPAM, REASON_ABUSE, REASON_ILLEGAL] }, presence: true

  def dismiss!
    update!(result: RESULT_DISMISSED)
  end

  def uphold!(moderator:, variant: nil)
    case item
    when User
      item.ban!(moderator: moderator, reason: "In response to report ##{id}", ban_related: true)
    when Comment
      item.poster.ban!(moderator: moderator, reason: "In response to report ##{id}", ban_related: true) if variant == 'ban'
      item.destroy!
    else
      raise "Unknown report item #{item}"
    end
    update!(result: RESULT_UPHELD)
  end

  def reason_text
    REASON_TEXT[reason]
  end
end
