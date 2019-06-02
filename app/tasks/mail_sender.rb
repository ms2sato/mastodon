class MailSender

  def dummy
    names = ['test1', 'test2', 'test3']
    domain = "example.com"

    names.each do |name|
      a  = Account.where(username: name).first_or_create!(username: name)
      User.where(email: "#{name}@#{domain}").first_or_initialize(email: "#{name}@#{domain}", password: 'password', password_confirmation: 'password', confirmed_at: Time.now.utc, admin: false, account: a).save!
    end
  end

  def send(dry_run = true)
    puts "dry_run: #{dry_run}"

    User.find_each do |user|
      next if user.email.end_with?("@github")

      puts "mail to: #{user.email}"
      UserMailer.last_mail(user).deliver_later unless dry_run
    end
  end
end
