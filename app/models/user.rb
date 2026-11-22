class User < ApplicationRecord
  has_many :sessions, dependent: :destroy
  has_many :packs, -> { order(:position, :id) }, dependent: :destroy
  has_many :word_lists, dependent: :destroy
  has_many :practice_records, dependent: :destroy
  has_many :devices, -> { order(:id) }, dependent: :destroy

  normalizes :login_id, with: ->(value) { value.strip.downcase }

  # The login ID of GitHub accounts and of the accounts that signed in with an ID and a password before v2.59.0 (they
  # are kept, but can no longer sign in, as in typle-r). An account made by Sparklingstadt ID has none.
  validates :login_id, uniqueness: true, length: { in: 3..32 }, format: { with: /\A[a-z0-9_-]+\z/, message: :login_id_format },
    allow_nil: true, unless: :guest?
  validates :sid_sub, uniqueness: true, format: { with: SidLogin::SUB }, allow_nil: true

  scope :accounts, -> { where(guest: false) }

  def self.create_guest! = create!(guest: true)

  # The account a Sparklingstadt ID login opens: the one its sub is linked to (bin/rails "sid:link[...]"), else the
  # account made for that sub, made now on its first login (typle-r's sid:<sub>), named by the ID. A failure to read
  # the link raises, so that the login fails rather than open an empty account.
  def self.for_sid!(sub, name:)
    user = find_by(sid_sub: sub)
    return create!(sid_sub: sub, name:) unless user
    user.update!(name:) if user.sid_only? && user.name != name
    user
  rescue ActiveRecord::RecordNotUnique
    # Another login of the same ID made it first.
    find_by!(sid_sub: sub)
  end

  def typing_options
    { ignoreAccents: ignore_accents, ignoreCase: ignore_case }
  end

  # An account that only Sparklingstadt ID opens (typle-r's sid:<sub>), not one of another login linked to an ID.
  def sid_only? = sid_sub.present? && github_uid.blank? && password_digest.blank? && login_id.blank?

  # How the account signs in, as typle-r's account menu says it: :sid, :github or :password (an ID, before v2.59.0).
  def login_kind
    if sid_only? then :sid
    elsif github_uid.present? && password_digest.blank? then :github
    else :password
    end
  end

  # Whether the account has saved anything (packs, lists, practice records or devices), which sid:link asks of the
  # accounts it links.
  def saved_data? = packs.exists? || word_lists.exists? || practice_records.exists? || devices.exists?

  def display_name = guest? ? nil : (name.presence || github_login.presence || login_id)

  def interest_ids = Interests.decode(interests)
end
