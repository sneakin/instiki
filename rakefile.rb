require 'rake'
require 'rake/clean'
require 'rake/testtask'
require 'rake/rdoctask'
require 'rake/packagetask'

$VERBOSE = nil
TEST_CHANGES_SINCE = Time.now - 600

# Standard Rails tasks

desc 'Run all tests'
task :default => [:test_units, :test_functional]

desc 'Require application environment.'
task :environment do
  unless defined? RAILS_ROOT
    require File.dirname(__FILE__) + '/config/environment'
  end
end

desc 'Generate API documentatio, show coding stats'
task :doc => [ :appdoc, :stats ]

# Look up tests for recently modified sources.
def recent_tests(source_pattern, test_path, touched_since = 10.minutes.ago)
  FileList[source_pattern].map do |path|
    if File.mtime(path) > touched_since
      test = "#{test_path}/#{File.basename(path, '.rb')}_test.rb"
      test if File.exists?(test)
    end
  end.compact
end

desc 'Test recent changes.'
Rake::TestTask.new(:recent) do |t|
  since = TEST_CHANGES_SINCE
  touched = FileList['test/**/*_test.rb'].select { |path| File.mtime(path) > since } +
    recent_tests('app/models/*.rb', 'test/unit', since) +
    recent_tests('app/controllers/*.rb', 'test/functional', since)

  t.libs << 'test'
  t.verbose = true
  t.test_files = touched.uniq
end

desc 'Run the unit tests in test/unit'
Rake::TestTask.new('test_units') { |t|
  t.libs << 'test'
  t.pattern = 'test/unit/**/*_test.rb'
  t.verbose = true
}

desc 'Run the functional tests in test/functional'
Rake::TestTask.new('test_functional') { |t|
  t.libs << 'test'
  t.pattern = 'test/functional/**/*_test.rb'
  t.verbose = true
}

desc 'Generate documentation for the application'
Rake::RDocTask.new('appdoc') { |rdoc|
  rdoc.rdoc_dir = 'doc/app'
  rdoc.title    = 'Rails Application Documentation'
  rdoc.options << '--line-numbers --inline-source'
  rdoc.rdoc_files.include('doc/README_FOR_APP')
  rdoc.rdoc_files.include('app/**/*.rb')
}

desc 'Generate documentation for the Rails framework'
Rake::RDocTask.new("apidoc") { |rdoc|
  rdoc.rdoc_dir = 'doc/api'
  rdoc.title    = 'Rails Framework Documentation'
  rdoc.options << '--line-numbers --inline-source'
  rdoc.rdoc_files.include('README')
  rdoc.rdoc_files.include('CHANGELOG')
  rdoc.rdoc_files.include('vendor/rails/railties/CHANGELOG')
  rdoc.rdoc_files.include('vendor/rails/railties/MIT-LICENSE')
  rdoc.rdoc_files.include('vendor/rails/activerecord/README')
  rdoc.rdoc_files.include('vendor/rails/activerecord/CHANGELOG')
  rdoc.rdoc_files.include('vendor/rails/activerecord/lib/active_record/**/*.rb')
  rdoc.rdoc_files.exclude('vendor/rails/activerecord/lib/active_record/vendor/*')
  rdoc.rdoc_files.include('vendor/rails/actionpack/README')
  rdoc.rdoc_files.include('vendor/rails/actionpack/CHANGELOG')
  rdoc.rdoc_files.include('vendor/rails/actionpack/lib/action_controller/**/*.rb')
  rdoc.rdoc_files.include('vendor/rails/actionpack/lib/action_view/**/*.rb')
  rdoc.rdoc_files.include('vendor/rails/actionmailer/README')
  rdoc.rdoc_files.include('vendor/rails/actionmailer/CHANGELOG')
  rdoc.rdoc_files.include('vendor/rails/actionmailer/lib/action_mailer/base.rb')
  rdoc.rdoc_files.include('vendor/rails/actionwebservice/README')
  rdoc.rdoc_files.include('vendor/rails/actionwebservice/ChangeLog')
  rdoc.rdoc_files.include('vendor/rails/actionwebservice/lib/action_web_service/**/*.rb')
  rdoc.rdoc_files.include('vendor/rails/activesupport/README')
  rdoc.rdoc_files.include('vendor/rails/activesupport/lib/active_support/**/*.rb')
}

desc 'Report code statistics (KLOCs, etc) from the application'
task :stats => [ :environment ] do
  require 'code_statistics'
  CodeStatistics.new(
    ['Helpers', 'app/helpers'], 
    ['Controllers', 'app/controllers'], 
    ['APIs', 'app/apis'],
    ['Components', 'components'],
    ['Functionals', 'test/functional'],
    ['Models', 'app/models'],
    ['Units', 'test/unit']
  ).to_s
end

# Additional tasks (not standard Rails)

CLEAN << 'pkg' << 'storage/2500' << 'doc' << 'html'

begin
  require 'rubygems'
  require 'rake/gempackagetask'
rescue Exception
  nil
end

if defined? GemPackageTask
  gemspec = eval(File.read('instiki.gemspec'))
  Rake::GemPackageTask.new(gemspec) do |p|
    p.gem_spec = gemspec
    p.need_tar = true
    p.need_zip = true
  end

  # PKG_VERSION is defined in instiki.gemspec
  Rake::PackageTask.new('instiki', gemspec.version) do |p|
    p.need_tar = true
    p.need_zip = true
    # the list of glob expressions for files comes from instiki.gemspec
    p.package_files.include($__instiki_source_patterns) 
  end
  
  # Create a task to build the RDOC documentation tree.
  rd = Rake::RDocTask.new("rdoc") { |rdoc|
    rdoc.rdoc_dir = 'html'
    rdoc.title = 'Instiki -- The Wiki'
    rdoc.options << '--line-numbers --inline-source --main README'
    rdoc.rdoc_files.include(gemspec.files)
    rdoc.main = 'README'
  }
else
  puts 'Warning: without Rubygems packaging tasks are not available'
end

# Shorthand aliases
desc 'Shorthand for test_unit'
task :tu => :test_unit

desc 'Shorthand for test_functional'
task :tf => :test_functional
