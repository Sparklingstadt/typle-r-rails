class ApplicationMailer < ActionMailer::Base
  default from: ENV.fetch("MAIL_FROM", "Typle <no-reply@typle.localhost>")
  layout "mailer"
end
