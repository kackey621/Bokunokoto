class ConsoleMailer < ApplicationMailer
  default to: "dev-test@example.local", from: "system-console@example.local"

  def sample
    mail(subject: "Bokunokoto system console test email")
  end
end
