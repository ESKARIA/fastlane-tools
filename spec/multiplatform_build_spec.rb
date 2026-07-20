# frozen_string_literal: true

require 'spec_helper'
require 'ripper'

# Fastfile_build/Fastfile_macos написаны на DSL Fastlane (lane/platform/
# build_app/...), недоступном вне полноценного запуска Fastlane — поэтому,
# по аналогии с fastfile_macos_spec.rb, здесь проверяется только синтаксис и
# структурные свойства исходника (regex), не поведение. Чистая логика
# (multiplatform_scheme?) протестирована отдельно в multiplatform_scheme_spec.rb.
RSpec.describe 'Мультиплатформенная поддержка (multiplatform_scheme?) в build-лейнах' do
  let(:build_path) { File.expand_path('../fastlane/Fastfile_build', __dir__) }
  let(:macos_path) { File.expand_path('../fastlane/Fastfile_macos', __dir__) }
  let(:build_source) { File.read(build_path) }
  let(:macos_source) { File.read(macos_path) }

  it 'оба файла синтаксически валидны' do
    expect(Ripper.sexp(build_source)).not_to be_nil
    expect(Ripper.sexp(macos_source)).not_to be_nil
  end

  describe 'Fastfile_build (lane :build, iOS)' do
    it 'читает режим через multiplatform_scheme?(options)' do
      expect(build_source).to match(/multiplatform\s*=\s*multiplatform_scheme\?\(options\)/)
    end

    it 'пропускает set_version_for_target/sync_build_number_for_other_targets в мультиплатформенном режиме (unless multiplatform)' do
      expect(build_source).to match(/unless\s+multiplatform\b[\s\S]{0,400}set_version_for_target/)
    end

    it 'задаёт xcargs с MARKETING_VERSION/CURRENT_PROJECT_VERSION только если multiplatform' do
      expect(build_source).to match(/if\s+multiplatform\b[\s\S]{0,200}build_params\[:xcargs\]\s*=.*MARKETING_VERSION.*CURRENT_PROJECT_VERSION/)
    end

    it 'опционально принимает sdk:/destination: через options/ENV (IOS_SDK/IOS_DESTINATION)' do
      expect(build_source).to match(/options\[:sdk\]\s*\|\|\s*ENV\['IOS_SDK'\]/)
      expect(build_source).to match(/options\[:destination\]\s*\|\|\s*ENV\['IOS_DESTINATION'\]/)
    end

    it 'не задаёт build_params[:sdk]/[:destination] безусловно (не ломает обычные однoplatform-сборки)' do
      # sdk/destination должны присваиваться через `unless ..._sdk.to_s.empty?`
      # (или аналогичную условную конструкцию), не голым `build_params[:sdk] = ios_sdk` без guard.
      expect(build_source).to match(/build_params\[:sdk\]\s*=\s*ios_sdk\s+unless\s+ios_sdk\.to_s\.empty\?/)
    end

    it 'не меняет имена/сигнатуры существующих lane (version, build)' do
      expect(build_source).to match(/lane\s+:version\s+do/)
      expect(build_source).to match(/lane\s+:build\s+do\s*\|options\|/)
    end
  end

  describe 'Fastfile_macos (lane :build)' do
    it 'читает режим через multiplatform_scheme?(options)' do
      expect(macos_source).to match(/multiplatform\s*=\s*multiplatform_scheme\?\(options\)/)
    end

    it 'пропускает set_version_for_target в мультиплатформенном режиме (unless multiplatform)' do
      expect(macos_source).to match(/unless\s+multiplatform\b[\s\S]{0,200}set_version_for_target/)
    end

    it 'задаёт xcargs только если multiplatform' do
      expect(macos_source).to match(/build_params\[:xcargs\]\s*=.*MARKETING_VERSION.*CURRENT_PROJECT_VERSION.*if\s+multiplatform/)
    end

    it 'уже поддерживала sdk:/destination: (MAC_SDK/MAC_DESTINATION, тикет 01) — не регрессировало' do
      expect(macos_source).to match(/options\[:sdk\]\s*\|\|\s*ENV\['MAC_SDK'\]/)
      expect(macos_source).to match(/options\[:destination\]\s*\|\|\s*ENV\['MAC_DESTINATION'\]/)
    end

    it 'не меняет lane :build сигнатуру' do
      expect(macos_source).to match(/lane\s+:build\s+do\s*\|options\|/)
    end
  end
end
