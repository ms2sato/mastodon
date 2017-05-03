class AllUsersConfirmer
  def execute!
    User.all.each do |user|
      begin
        puts("id: #{user.id}")
        if user.confirmed_at.blank?
          user.skip_confirmation!
          user.save!
        end
      rescue => e
        puts("failed!")
        puts(user.inspect)
        puts(e.message)
        puts(e.backtrace.join("\n"))
      end
    end
  end
end
