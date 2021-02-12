Steps to open console

Run `BUNDLE_GEMFILE=gemfiles/ar-3.2_mysql2.gemfile bundle exec rake console`.
Inside console, 
```
require 'active_record'
require 'mysql2'
ActiveRecord::Base.establish_connection(
    :adapter  => 'mysql2',
    :host     => '127.0.0.1',
    :database => 'lhm',
    :username => 'root',
    :port     => 3306
)
adapter = ActiveRecord::Base.connection
Lhm.setup(adapter)
```
