# frozen_string_literal: true

require 'spec_helper'
require 'ripper'

# Fastfile_macos написан на DSL Fastlane (platform/lane/match/build_app/...),
# который недоступен вне полноценного запуска Fastlane (в отличие от чистого
# Ruby в Fastfile_helpers, которое load'ится в spec_helper). Поэтому здесь, по
# аналогии с fastfile_macos_direct_spec.rb, проверяется только то, что не
# требует реального DSL: синтаксис, состав lane, и структурные свойства
# исходного текста (regex по методам mac_generate_match/mac_install_match/build).
RSpec.describe 'Fastfile_macos' do
  let(:module_path) { File.expand_path('../fastlane/Fastfile_macos', __dir__) }
  let(:source) { File.read(module_path) }

  def method_body(source, method_name)
    match = source.match(/^def #{method_name}\(.*?\n(.*?)^end$/m)
    raise "Метод #{method_name} не найден" unless match

    match[1]
  end

  it 'существует' do
    expect(File.exist?(module_path)).to be(true)
  end

  it 'синтаксически валиден' do
    expect(Ripper.sexp(source)).not_to be_nil
  end

  it 'объявлен внутри platform :mac' do
    expect(source).to match(/platform\s+:mac\s+do/)
  end

  %i[
    match_generate_dev
    match_generate_appstore
    match_install_dev
    match_install_appstore
    nuke_development
    nuke_appstore
    build
    upload_testflight
    upload_appstore
  ].each do |lane_name|
    it "объявляет lane :#{lane_name}" do
      expect(source).to match(/lane\s+:#{lane_name}\s+do/)
    end
  end

  it 'не объявляет лишних lane сверх ожидаемых 9' do
    declared_lanes = source.scan(/lane\s+:([a-zA-Z_][a-zA-Z0-9_]*)\s+do/).flatten.map(&:to_sym)
    expected_lanes = %i[
      match_generate_dev
      match_generate_appstore
      match_install_dev
      match_install_appstore
      nuke_development
      nuke_appstore
      build
      upload_testflight
      upload_appstore
    ]

    expect(declared_lanes.sort).to eq(expected_lanes.sort)
  end

  # ----------------------------------------------------------------------
  # Item 1: два отдельных вызова match вместо одного с двумя типами cert
  # ----------------------------------------------------------------------

  describe 'mac_generate_match — двухшаговая генерация installer-сертификата' do
    let(:body) { method_body(source, 'mac_generate_match') }

    it 'содержит ровно два вызова match(...)' do
      expect(body.scan(/\bmatch\(/).count).to eq(2)
    end

    it 'additional_cert_types и skip_provisioning_profiles: true встречаются вместе, во втором вызове' do
      expect(body).to match(/additional_cert_types:\s*\['mac_installer_distribution'\]/)
      expect(body).to match(/skip_provisioning_profiles:\s*true/)

      # Оба ключа должны быть в одном and том же match(...) вызове (merge-блоке),
      # а не в базовом первом вызове.
      installer_call = body[/match\(\*\*base_params\.merge\(\s*(.*?)\)\)/m, 1]
      expect(installer_call).to match(/additional_cert_types/)
      expect(installer_call).to match(/skip_provisioning_profiles:\s*true/)
    end

    it 'базовый вызов match(**base_params) не содержит additional_cert_types' do
      base_call_source = body[/match\(\*\*base_params\)\n/]
      expect(base_call_source).not_to be_nil
    end
  end

  describe 'mac_install_match — двухшаговая установка installer-сертификата' do
    let(:body) { method_body(source, 'mac_install_match') }

    it 'содержит ровно два вызова match(...)' do
      expect(body.scan(/\bmatch\(/).count).to eq(2)
    end

    it 'additional_cert_types и skip_provisioning_profiles: true встречаются вместе, во втором вызове' do
      installer_call = body[/match\(\*\*base_params\.merge\(\s*(.*?)\)\)/m, 1]
      expect(installer_call).to match(/additional_cert_types/)
      expect(installer_call).to match(/skip_provisioning_profiles:\s*true/)
    end
  end

  # ----------------------------------------------------------------------
  # Item 2: регистрация текущего Mac как provisioning-устройства
  # ----------------------------------------------------------------------

  it 'вызывает register_devices( — регистрация устройства подключена' do
    expect(source).to match(/register_devices\(/)
  end

  it 'match_generate_dev вызывает mac_register_this_device до генерации профиля' do
    lane_body = source[/lane\s+:match_generate_dev\s+do.*?^  end$/m]
    expect(lane_body).to match(/mac_register_this_device/)
    expect(lane_body).to match(/mac_generate_match\(type:\s*'development'/)

    register_index = lane_body.index('mac_register_this_device')
    generate_index = lane_body.index("mac_generate_match(type: 'development'")
    expect(register_index).to be < generate_index
  end

  it 'match_install_dev НЕ вызывает mac_register_this_device (readonly lane)' do
    lane_body = source[/lane\s+:match_install_dev\s+do.*?^  end$/m]
    expect(lane_body).not_to match(/mac_register_this_device/)
  end

  # ----------------------------------------------------------------------
  # Item 3: build lane — configurable sdk/destination
  # ----------------------------------------------------------------------

  describe 'lane :build — sdk/destination' do
    let(:lane_body) { source[/lane\s+:build\s+do.*?\n  end\n/m] }

    it 'резолвит build_sdk из options[:sdk] / ENV[\'MAC_SDK\'] / дефолта \'macosx\'' do
      expect(lane_body).to match(/build_sdk\s*=\s*options\[:sdk\]\s*\|\|\s*ENV\['MAC_SDK'\]\s*\|\|\s*'macosx'/)
    end

    it 'резолвит build_destination из options[:destination] / ENV[\'MAC_DESTINATION\'] / дефолта' do
      expect(lane_body).to match(%r{build_destination\s*=\s*options\[:destination\]\s*\|\|\s*ENV\['MAC_DESTINATION'\]\s*\|\|\s*'generic/platform=macOS'})
    end

    it 'передаёт sdk: и destination: в build_params' do
      expect(lane_body).to match(/sdk:\s*build_sdk/)
      expect(lane_body).to match(/destination:\s*build_destination/)
    end
  end
end
