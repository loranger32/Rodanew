require "fileutils"

ENV_EMAIL = "MY_EMAIL=example_user@example.com"
ENV_NAME = "MY_NAME=example_user"
ENV_PG_CREDENTIALS = "PG_CREDENTIALS=\"example:secret\""

desc "create example app with rodauth"
task :example_rodauth do
  FileUtils.cd("examples") do
    system("#{ENV_EMAIL} #{ENV_NAME} #{ENV_PG_CREDENTIALS} rodanew with_rodauth --no-git")
  end
end

desc "create example app without rodauth"
task :example_no_rodauth do
  FileUtils.cd("examples") do
    system("#{ENV_PG_CREDENTIALS} rodanew without_rodauth --no_rodauth --no-git")
  end
end

desc "create_example apps"
task examples: [:example_rodauth, :example_no_rodauth]
