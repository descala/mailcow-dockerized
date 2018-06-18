#!/usr/bin/env ruby
require 'csv'
require 'awesome_print'

unless ARGV.size == 3
  puts "Usage: #{File.basename($0)} <domain_name> <source_host> <source_password>"
  exit
end

dom=ARGV[0]
src_host=ARGV[1]
src_pass=ARGV[2]

unless File.exist?("#{dom}.csv") and File.exist?("#{dom}_alias.csv")
  puts "Missing required file. Generate #{dom}.csv and #{dom}_alias.csv with:"
  puts "select * from mailbox where domain='#{dom}' and username like '%@%' INTO OUTFILE '/tmp/#{dom}.csv' FIELDS TERMINATED BY ',' ENCLOSED BY '\"' LINES TERMINATED BY '\\n';"
  puts "select * from alias where domain='#{dom}' INTO OUTFILE '/tmp/#{dom}_alias.csv' FIELDS TERMINATED BY ',' ENCLOSED BY '\"' LINES TERMINATED BY '\\n';"
  exit
end

IMAPSYNC_DELETE_SRC=0 # delete1
IMAPSYNC_DELETE_DST=0 # delete2

CSV.foreach("#{dom}.csv") do |mailbox|
  username   = mailbox[0]
  password   = mailbox[1]
  name       = mailbox[2]
  maildir    = mailbox[3]
  quota      = mailbox[4]
  local_part = mailbox[5]
  domain     = mailbox[6]
  _created   = mailbox[7]
  _modified  = mailbox[8]
  active     = mailbox[9]
  puts "INSERT INTO `mailbox` (`username`, `password`, `name`, `maildir`, `quota`, `local_part`, `domain`, `active`) " +
    "VALUES ('#{username}', '{MD5-CRYPT}#{password}', '#{name}', '#{maildir}', '#{quota}', '#{local_part}', '#{domain}', '#{active}');"
  puts "INSERT INTO `quota2` (`username`, `bytes`, `messages`) " +
    "VALUES ('#{username}', '0', '0') ON DUPLICATE KEY UPDATE `bytes` = '0', `messages` = '0';"
  puts "INSERT INTO `user_acl` (`username`) VALUES ('#{username}');"
  puts "INSERT INTO `imapsync` (user2, host1, authmech1, regextrans2, authmd51, domain2, subfolder2, user1, password1, exclude, maxage, " +
    "mins_interval, port1, enc1, delete2duplicates, delete1, delete2, is_running, returned_text, last_run, created, modified, active, maxbytespersecond, automap, skipcrossduplicates) " +
    "VALUES ('#{username}','#{src_host}','PLAIN','',0,'','','#{username}','#{src_pass}','(?i)spam|(?i)junk',0," +
    "'60',143,'TLS',1,#{IMAPSYNC_DELETE_SRC},#{IMAPSYNC_DELETE_DST},0,NULL,NULL,'2018-05-10 11:49:13',NULL,1,'0',1,0);"
end

CSV.foreach("#{dom}_alias.csv") do |aalias| # (alias reserved word)
  address   = aalias[0]
  goto      = aalias[1]
  domain    = aalias[2]
  _created  = aalias[3]
  _modified = aalias[4]
  active    = aalias[5]
  puts "INSERT INTO `alias` (`address`, `goto`, `domain`, `active`) VALUES " +
    "('#{address}', '#{goto}', '#{domain}', '#{active}');"
end
