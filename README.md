# Rodanew

[Roda](http://roda.jeremyevans.net/index.html) - [Sequel](http://sequel.jeremyevans.net/) - [Rodauth](http://rodauth.jeremyevans.net/) app generator, built with [Thor](https://github.com/rails/thor).

It uses `Thor::Group` and `Thor::Actions` features.

# Why ?

Roda, Sequel and Rodauth allow you to load plugins to add only the features you need.

To get quickly started, you can use or create a template repo, like [this one from Jeremy Evans](https://github.com/jeremyevans/roda-sequel-stack), and customize it according to your needs.

But most of the times, I like to start with a full authentication setup with Rodauth and Bootstrap 5, and the ability to (slightly) customize it at app creation time when I need something more simple.

And it's not that difficult to do with a command line utility like Thor.

# Examples

You can check the two generated setups in the examples directory, one with rodauth setup, the other without.

# Do you want to use it ?

Probably not. Roda, Sequel and Rodauth are highly customizable and my current setup won't probably suit your needs.

But it gives you an idea of how you can create your own.

# Installation

Simply download the repo where you see fit.

# Setup

## Required

- Install the `thor` gem
- make the `rodanew.rb` file executable : `$ chmod +x rodanew.rb` 
- create a symlink from a directory in your `PATH` that points to `path/to/your/rodanew/repo/rodanew.rb`
- create two Postgresql databases, one for development and for the tests. Names MUST be `app_name_development` and `app_name_test`

## Optional

If you intend to use Rodauth, the following `ENV` variables must be set :
- MY_EMAIL : the email address the app sends an email to when a new user signs up
- MY_NAME : your user name, used in the seed data to create the seed accounts. It's also used in the Licence.

Also if you want to use Rodauth, both DB's need the [citext extension](https://www.postgresql.org/docs/15/citext.html).

If you don't use a specific postgresql user for your database (like in tests and development), set the following `ENV` variable :
- PG_CREDENTIALS : `your_pg_username:your_pg_password`

If the databases belongs to a specific user, it must have the same name as your project, and you need to provide the password as an option when creating the app (see below).

# Usage

Assuming the symlink you created is `rodanew` :

- `cd` in the directory where you want to create your app

- `$ rodanew the_name_of_your_app` with no other options basically :
  - creates an app named `the_name_of_your_app` with Roda, Sequel (Postgresql adapter), Rodauth and Bootstrap setup
  - creates Rakefile with basic tasks
  - creates test files to test Rodauth setup
  - uses the value of the ENV variable `PG_CREDENTIALS` , `MY_EMAIL` and `MY_NAME` to populate the `.env` file
  - run `bundle install` automatically after app creation
  - initialize a git repo

- options are :
  - `--db-password` : use this password in the `.env` file, instead of using the one on the `ENV["PG_CREDENTIALS"]`. It then assumes that the Postgresql username is the same as the app name
  - `--no-rodauth` : don't setup Rodauth. It doesn't create the specific rodauth test file either, and doesn't require any specific `ENV` variable being set
  - `--no-bs` : don't use Bootstrap. The layout file won't require it
  - `--no-git` : don't create a git repo

If you use Rodauth, `cd` into your newly created app and run :
- `$ rake db:migrate`
- `$ rake db:seed` (optional)
- `$ rake` (runs the tests to confirm the Rodauth setup is working)

Otherwise just run :
- `$ rake` (runs the tests, that simply test there is a working Home page)

# Other examples

Here are some other roda app generators that I'm aware of :

- [GregTemplates/roda_app](https://github.com/GregTemplates/roda_app)
- [roda_api_generator](https://github.com/napice/roda_api_generator)

If you know another one, you're welcome to add it.

# Test

A basic rake `test` task is provided. It creates two apps (with and without Rodauth) in the /tmp directory. It runs the migrations for the Rodauth app, and then runs the tests. For the app without Rodauth, it simply runs the tests (no migration).

After testing, both app directories are removed.

Tests assumes a postgresql database named `rodagen_test`, with citext extension, and the `ENV` variable `PG_CREDENTIALS` being set.

# Licence

MIT
