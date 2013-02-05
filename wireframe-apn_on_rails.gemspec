# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{wireframe-apn_on_rails}
  s.version = "0.3.0.201302051600"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["ryan"]
  s.date = %q{2011-02-14}
  s.description = %q{apn_on_rails was developed by: ryan}
  s.email = %q{mark@markbates.com}
  s.extra_rdoc_files = ["README", "LICENSE"]
  s.files = ["lib/apn_on_rails/apn_on_rails.rb", "lib/apn_on_rails/app/models/apn/base.rb", "lib/apn_on_rails/app/models/apn/device.rb", "lib/apn_on_rails/app/models/apn/notification.rb", "lib/apn_on_rails/libs/connection.rb", "lib/apn_on_rails/libs/feedback.rb", "lib/apn_on_rails/tasks/apn.rake", "lib/apn_on_rails/tasks/db.rake", "lib/apn_on_rails.rb", "lib/apn_on_rails_tasks.rb", "README", "LICENSE", "generators/apn_migrations_generator.rb", "generators/templates/apn_migrations/001_create_apn_devices.rb", "generators/templates/apn_migrations/002_create_apn_notifications.rb", "generators/templates/apn_migrations/003_alter_apn_devices.rb", "generators/templates/apn_migrations/004_add_payload_to_notifications.rb"]
  s.homepage = %q{http://www.metabates.com}
  s.require_paths = ["lib"]
  s.rubyforge_project = %q{magrathea}
  s.rubygems_version = %q{1.5.2}
  s.summary = %q{apn_on_rails}

  if s.respond_to? :specification_version then
    s.specification_version = 3

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<configatron>, [">= 0"])
      s.add_runtime_dependency(%q<activerecord>, [">= 0"])
    else
      s.add_dependency(%q<configatron>, [">= 0"])
      s.add_dependency(%q<activerecord>, [">= 0"])
    end
  else
    s.add_dependency(%q<configatron>, [">= 0"])
    s.add_dependency(%q<activerecord>, [">= 0"])
  end
end
