namespace :sid do
  desc 'Link a Sparklingstadt ID to an account: bin/rails "sid:link[<sub>,<login ID or github:<id>>]" (typle-r\'s npm run sid:link)'
  task :link, %i[sub account] => :environment do |_task, args|
    sub = SidLink.parse_sub(args[:sub])
    if sub.nil? || args[:account].blank?
      abort '使い方: bin/rails "sid:link[<sub>,<アカウント>]"（sub は sid: 付きでもよい。アカウントはログイン ID か github:<数字>）'
    end
    answer = SidLink.link(sub, args[:account])
    puts "#{SidLink::MESSAGES.fetch(answer)}（sid:#{sub} → #{args[:account]}、DB: #{SidLink.database_label}）"
    exit 1 unless answer == :linked
  end
end
