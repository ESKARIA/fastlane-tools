# frozen_string_literal: true

require 'spec_helper'
require 'ripper'

# Fastfile_macos_direct написан на DSL Fastlane (platform/lane/match/build_app/...),
# который недоступен вне полноценного запуска Fastlane (в отличие от чистого
# Ruby в Fastfile_helpers, которое load'ится в spec_helper). Поэтому здесь
# проверяется только то, что не требует реального DSL:
#   - файл синтаксически валиден (парсится Ripper без ошибок);
#   - все 7 новых lane объявлены под ожидаемыми именами внутри `platform :mac`.
RSpec.describe 'Fastfile_macos_direct' do
  let(:module_path) { File.expand_path('../fastlane/Fastfile_macos_direct', __dir__) }
  let(:source) { File.read(module_path) }

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
    match_generate_developer_id
    match_install_developer_id
    match_import_developer_id
    build_direct
    make_dmg
    notarize_dmg
    generate_appcast_feed
    release_direct
  ].each do |lane_name|
    it "объявляет lane :#{lane_name}" do
      expect(source).to match(/lane\s+:#{lane_name}\s+do/)
    end
  end

  it 'не объявляет лишних lane сверх ожидаемых 8' do
    declared_lanes = source.scan(/lane\s+:([a-zA-Z_][a-zA-Z0-9_]*)\s+do/).flatten.map(&:to_sym)
    expected_lanes = %i[
      match_generate_developer_id
      match_install_developer_id
      match_import_developer_id
      build_direct
      make_dmg
      notarize_dmg
      generate_appcast_feed
      release_direct
    ]

    expect(declared_lanes.sort).to eq(expected_lanes.sort)
  end
end
