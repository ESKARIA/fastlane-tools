# frozen_string_literal: true

source 'https://rubygems.org'

git_source(:github) { |repo_name| "https://github.com/#{repo_name}" }

gem 'excon', '~> 1.5.0'
gem 'fastlane'
gem 'psych'
gem 'rdoc', '~> 7.2'
gem 'rubocop'
gem 'rubyzip'

group :development, :test do
  gem 'rspec'
end

plugins_path = File.join(File.dirname(__FILE__), 'fastlane', 'Pluginfile')
eval_gemfile(plugins_path) if File.exist?(plugins_path)
