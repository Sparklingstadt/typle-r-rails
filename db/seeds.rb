# A demo account with an official pack followed (ID demo), for development. Since typle-r v2.59.0 the only logins are
# Sparklingstadt ID and GitHub, so it has no password: open it with the made-up local login of development
# (LOCAL_DEVELOPMENT_LOGIN=1 bin/rails server, then the button on /signin), as typle-r's authorizeLocal.
# Not made in production (db:prepare seeds a new database there too) unless SEED_DEMO=1 asks for it.
return if Rails.env.production? && ENV["SEED_DEMO"] != "1"

user = User.find_or_create_by!(login_id: "demo")
OfficialCatalog.follow(user, "pack-vim-beginner")
