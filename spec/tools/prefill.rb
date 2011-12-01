require "active_record"
require "optparse"
require "yaml"

options = OptionParser.new do |o|
  o.on("-h", "--help",                    "Print the usage")              {|o| puts options.to_s; exit }
end
options.parse(ARGV)

config = YAML.load_file(File.expand_path("../../config/database.yml", __FILE__))
ActiveRecord::Base.establish_connection(config)

ActiveRecord::Base.connection.execute("DROP TABLE IF EXISTS `test`;")
ActiveRecord::Base.connection.execute(%{
  CREATE TABLE `test` (
    `id` int(11) NOT NULL AUTO_INCREMENT,
    `user` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
    `created_at` datetime DEFAULT NULL,
    `updated_at` datetime DEFAULT NULL,
    PRIMARY KEY (`id`)
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;
})
