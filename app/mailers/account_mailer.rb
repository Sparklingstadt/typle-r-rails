# typle-r's mails (src/server/mail.ts, messages/*/mail.json): their subjects and bodies, with the link or the ID put in.
class AccountMailer < ApplicationMailer
  def password_reset(user)
    send_mail user, :reset, link: edit_password_url(token: user.generate_token_for(:password_reset))
  end

  def login_id_reminder(user)
    send_mail user, :loginIds, ids: user.login_id
  end

  def email_confirmation(user)
    send_mail user, :verify, link: verify_email_url(token: user.generate_token_for(:email_confirmation))
  end

  private
    def send_mail(user, kind, **values)
      @body = I18n.t("typle.mail.#{kind}.body", **values)
      mail to: user.email, subject: I18n.t("typle.mail.#{kind}.subject") do |format|
        format.text { render plain: @body }
      end
    end
end
