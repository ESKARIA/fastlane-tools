# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'get_all_app_identifiers / get_primary_app_identifier' do
  around do |example|
    # APP_IDENTIFIER — обычная (не frozen) константа верхнего уровня в Fastfile_helpers.
    # В тестах переопределяем её через remove_const + Object.const_set,
    # чтобы не зависеть от реального Fastfile.
    original = Object.const_get(:APP_IDENTIFIER) if Object.const_defined?(:APP_IDENTIFIER)
    example.run
  ensure
    Object.send(:remove_const, :APP_IDENTIFIER) if Object.const_defined?(:APP_IDENTIFIER)
    Object.const_set(:APP_IDENTIFIER, original) if original
  end

  def set_app_identifier(value)
    Object.send(:remove_const, :APP_IDENTIFIER) if Object.const_defined?(:APP_IDENTIFIER)
    Object.const_set(:APP_IDENTIFIER, value)
  end

  describe 'get_all_app_identifiers' do
    it 'разбирает список идентификаторов через запятую' do
      set_app_identifier('com.app.main,com.app.widget,com.app.watchkit')

      expect(get_all_app_identifiers).to eq(%w[com.app.main com.app.widget com.app.watchkit])
    end

    it 'убирает пробелы и пустые элементы' do
      set_app_identifier('com.app.main, , com.app.widget ,')

      expect(get_all_app_identifiers).to eq(%w[com.app.main com.app.widget])
    end
  end

  describe 'get_primary_app_identifier' do
    it 'возвращает первый идентификатор' do
      set_app_identifier('com.app.main,com.app.widget')

      expect(get_primary_app_identifier).to eq('com.app.main')
    end

    it 'вызывает UI.user_error!, если APP_IDENTIFIER пуст' do
      set_app_identifier('')

      expect { get_primary_app_identifier }.to raise_error(/APP_IDENTIFIER/)
    end
  end
end
