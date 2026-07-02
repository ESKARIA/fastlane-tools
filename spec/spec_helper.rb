# frozen_string_literal: true

# spec_helper.rb
#
# Fastfile_helpers - не обычный Ruby-класс, а файл, рассчитанный на загрузку
# внутри Fastlane (с доступной DSL: UI, action-методы вроде testflight и т.д.).
# Чтобы протестировать чистую логику без запуска настоящего Fastlane, здесь
# определяются минимальные заглушки окружения, а сам файл загружается через load.

require 'rspec'
require 'fileutils'
require 'tmpdir'

# Гарантируем UTF-8 при чтении файлов независимо от локали окружения (CI может
# запускаться с LANG=C / POSIX) — иначе File.read внутри FastlaneMetrics#save_to_file
# падает на кириллице и тихо проглатывается rescue-блоком.
Encoding.default_external = Encoding::UTF_8
Encoding.default_internal = Encoding::UTF_8

# Заглушка UI.* — методы, которые вызывает Fastfile_helpers.
module UI
  def self.message(*); end
  def self.important(*); end
  def self.success(*); end
  def self.error(*); end
  def self.header(*); end

  def self.user_error!(msg)
    raise msg.to_s
  end
end

# Заглушка action `testflight`, которую переопределяют/мокают в спеках
# для upload_with_testflight_retry.
def testflight(**_params)
  nil
end

HELPERS_PATH = File.expand_path('../fastlane/Fastfile_helpers', __dir__)

# Загружаем Fastfile_helpers сразу при требовании spec_helper (до того, как
# спек-файлы будут выполнять `describe` на верхнем уровне и ссылаться на
# константы вроде FastlaneMetrics / NON_RETRYABLE_TESTFLIGHT_ERRORS).
load HELPERS_PATH

RSpec.configure do |config|
  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end

  config.before do
    $current_metrics = nil
  end
end
