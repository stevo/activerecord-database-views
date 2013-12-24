# activerecord-database-views [![Code Climate](https://codeclimate.com/repos/52b9755ee30ba0073d0155b9/badges/49e598060c1ac3936100/gpa.png)](https://codeclimate.com/repos/52b9755ee30ba0073d0155b9/feed)


Allows database views to be stored as sql files and be easily applyable

Installation
------------

Just add following line to your `Gemfile`

```ruby
gem 'activerecord-database-views'
```

and run `bundle install`

Usage
-----

Place your SQL that view will be generated from into `db\views` directory (*The actual view name will be the same as file name*), i.e.

```sql
-- db\views\reverse_users.sql
SELECT * FROM users ORDER BY users.id DESC
```

Then run console (`console c`) and execute...

```ruby
ActiveRecord::DatabaseViews.reload!
```

...to reload all defined views.

You can test them out by

```ruby
ActiveRecord::Base.connection.execute('SELECT * FROM reverse_users').to_a
```

or just attach them to a model file

```ruby
class ReverseUser < ActiveRecord::Base
end
```

and run

```ruby
ReverseUser.all
```

### How to run some code with views dropped

This is sometimes necessary in case of some changing migrations

```ruby
ActiveRecord::DatabaseViews.without do
    # some code that has to be executed with views dropped
end
```

### How to reload views automatically after migrations

Add new file `hooks.rake` under `lib\tasks` and copy following code

```ruby
db_tasks = %w[db:migrate db:rollback db:schema:load]

namespace :reload_views do
  db_tasks.each do |task_name|
    task task_name => %w[environment db:load_config] do
      ActiveRecord::DatabaseViews.reload!
    end
  end
end

db_tasks.each do |task_name|
  Rake::Task[task_name].enhance do
    Rake::Task["reload_views:#{task_name}"].invoke
  end
end
```

As a bonus you will be able to reload views using rake task as well, i.e. `rake reload_views:db:migrate`
