# A demo account with an official pack followed: ID demo, password password123.
# Not made in production (db:prepare seeds a new database there too) unless SEED_DEMO=1 asks for it.
return if Rails.env.production? && ENV["SEED_DEMO"] != "1"

user = User.find_or_create_by!(login_id: "demo") { |u| u.password = "password123" }
OfficialCatalog.follow(user, "pack-vim-beginner")
