# A demo account with an official pack followed: ID demo, password password123.
user = User.find_or_create_by!(login_id: "demo") { |u| u.password = "password123" }
OfficialCatalog.follow(user, "pack-vim-beginner")
