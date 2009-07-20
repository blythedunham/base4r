Gem::Specification.new do |s|
  s.name = %q{sms_on_rails}
  s.version = "0.2.0.4"
 
  s.required_rubygems_version = Gem::Requirement.new(">= 1.2") if s.respond_to? :required_rubygems_version=
  s.authors = ["Blythe Dunham"]base4r
  s.date = %q{2009-07-20}
  s.description = %q{Ruby interface to google base api}
  s.email = %q{blythe@snowgiraffe.com}
  s.extra_rdoc_files = ["lib/sms_on_rails/activerecord_extensions/acts_as_deliverable.rb", "lib/sms_on_rails/activerecord_extensions/acts_as_substitutable.rb", "lib/sms_on_rails/activerecord_extensions/has_a_sms_service_provider.rb", "lib/sms_on_rails/activerecord_extensions/lockable_record.rb", "lib/sms_on_rails/all_models.rb", "lib/sms_on_rails/model_support/draft.rb", "lib/sms_on_rails/model_support/outbound.rb", "lib/sms_on_rails/model_support/phone_carrier.rb", "lib/sms_on_rails/model_support/phone_number.rb", "lib/sms_on_rails/model_support/phone_number_associations.rb", "lib/sms_on_rails/schema_helper.rb", "lib/sms_on_rails/service_providers/base.rb", "lib/sms_on_rails/service_providers/clickatell.rb", "lib/sms_on_rails/service_providers/dummy.rb", "lib/sms_on_rails/service_providers/email_gateway.rb", "lib/sms_on_rails/service_providers/email_gateway_support/errors.rb", "lib/sms_on_rails/service_providers/email_gateway_support/sms_mailer/sms_through_gateway.erb", "lib/sms_on_rails/service_providers/email_gateway_support/sms_mailer.rb", "lib/sms_on_rails/util/sms_error.rb", "lib/sms_on_rails.rb", "lib/smsonrails.rb", "README", "README.rdoc", "tasks/sms_on_rails_tasks.rake"]
  s.files = FileList["{bin,lib}/**/*"].to_a
  s.has_rdoc = true
  s.homepage = %q{http://github.com/blythedunham/base4r}
  s.rdoc_options = ["--line-numbers", "--inline-source", "--title", "Sms_on_rails", "--main", "README"]
  s.require_paths = ["lib"]
  s.rubyforge_project = %q{base4r}
  s.rubygems_version = %q{1.3.1}
  s.summary = %q{Ruby interface to google base api}
  s.test_files = ["test/*.rb"]
  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 2
 
    if Gem::Version.new(Gem::RubyGemsVersion) >= Gem::Version.new('1.2.0') then
    else
    end
  else
  end
end