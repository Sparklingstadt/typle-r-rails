# typle-r's npm run sid:link (scripts/sid-link.cjs), as bin/rails "sid:link[<sub>,<account>]": links a Sparklingstadt ID
# (its sub, with or without sid:) to the account of another login, so that signing in with that ID opens the account.
# The account is named by its login ID, or as github:<GitHub user id>. Refused: an ID or an account that is linked
# already, an account that is not one of another login or has nothing saved (a mistyped one), and an ID whose own
# account (made by its first login, typle-r's sid:<sub>) has saved data, which the link would leave behind.
module SidLink
  MESSAGES = {
    linked: "ひも付けました。",
    sub_linked: "この Sparklingstadt ID は、もうほかのアカウントにひも付いています。",
    account_linked: "このアカウントには、もうほかの Sparklingstadt ID がひも付いています。",
    account_invalid: "ひも付け先は、ログイン ID か github:<数字> で、ほかのログインのアカウントを指定してください。",
    account_empty: "ひも付け先のアカウントに保存したデータがありません。アカウントを確かめてください。",
    sid_has_data: "この Sparklingstadt ID のアカウント（sid:<sub>）に、もう保存したデータがあります。ひも付けると読めなくなるため断りました。"
  }.freeze

  # The sub of text, with or without sid:, or nil when it is not one.
  def self.parse_sub(text)
    sub = text.to_s.strip.delete_prefix("sid:")
    sub.match?(SidLogin::SUB) ? sub : nil
  end

  # The account text names: github:<GitHub user id>, or a login ID.
  def self.find_account(text)
    text = text.to_s.strip
    return User.accounts.find_by(github_uid: text.delete_prefix("github:")) if text.start_with?("github:")
    User.accounts.find_by(login_id: text.downcase) if text.present?
  end

  # Links sub to the account in one transaction. Answers :linked, or why not: :sub_linked, :account_linked,
  # :account_invalid, :account_empty or :sid_has_data. The ID's own account, when it has nothing saved, is removed,
  # as typle-r's sid:<sub> is no longer opened once the ID is linked.
  def self.link(sub, account_text)
    User.transaction do
      account = find_account(account_text)
      next :account_invalid if account.nil? || account.sid_only?
      holder = User.lock.find_by(sid_sub: sub)
      next :sub_linked if holder && !holder.sid_only?
      next :account_linked if account.sid_sub.present?
      next :account_empty unless account.saved_data?
      next :sid_has_data if holder&.saved_data?
      holder&.destroy!
      account.update!(sid_sub: sub)
      :linked
    end
  rescue ActiveRecord::RecordNotUnique, ActiveRecord::RecordInvalid
    # Another run linked the ID between the check and the update.
    :sub_linked
  end

  # The database written to, as adapter host/name without the user or password, so that the result says which one it
  # was (a forgotten DATABASE_URL falls back to the development database).
  def self.database_label(config = ActiveRecord::Base.connection_db_config)
    hash = config.configuration_hash
    host = [hash[:host], hash[:port]].compact.join(":")
    "#{hash[:adapter]} #{host.present? ? "#{host}/#{hash[:database]}" : hash[:database]}"
  end
end
