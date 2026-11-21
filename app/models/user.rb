class User < ApplicationRecord
  has_secure_password validations: false
  has_many :sessions, dependent: :destroy
  has_many :packs, -> { order(:position, :id) }, dependent: :destroy
  has_many :word_lists, dependent: :destroy
  has_many :practice_records, dependent: :destroy
  has_many :devices, -> { order(:id) }, dependent: :destroy

  MAX_PASSWORD = 72

  normalizes :login_id, with: ->(value) { value.strip.downcase }
  normalizes :email, with: ->(value) { value.strip.downcase.presence }

  with_options unless: :guest? do
    validates :login_id, presence: true, uniqueness: true, length: { in: 3..32 },
      format: { with: /\A[a-z0-9_-]+\z/, message: :login_id_format }
    validates :password, presence: true, on: :create, if: -> { github_uid.blank? }
    # typle-r's rules: 10 characters or more, and not the ID (72 is bcrypt's limit).
    validates :password, length: { in: 10..MAX_PASSWORD }, confirmation: true, allow_nil: true
    validate :password_is_not_the_id
  end
  validates :email, uniqueness: true, allow_nil: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  # typle-r's sign-up asks for an address (GitHub accounts come without one).
  validates :email, presence: true, on: :registration

  generates_token_for :password_reset, expires_in: 30.minutes do
    password_salt&.last(10)
  end
  generates_token_for :email_confirmation, expires_in: 1.day do
    email
  end

  scope :accounts, -> { where(guest: false) }

  def self.create_guest! = create!(guest: true)

  def typing_options
    { ignoreAccents: ignore_accents, ignoreCase: ignore_case }
  end

  def email_confirmed? = email.present? && email_confirmed_at.present?

  def display_name = guest? ? nil : login_id

  def interest_ids = Interests.decode(interests)

  private
    def password_is_not_the_id
      errors.add(:password, :same_as_login_id) if password.present? && login_id.present? && password.casecmp?(login_id)
    end
end
