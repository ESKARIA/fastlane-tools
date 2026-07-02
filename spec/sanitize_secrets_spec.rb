# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'sanitize_secrets' do
  around do |example|
    old_env = ENV.to_hash
    example.run
    ENV.replace(old_env)
  end

  it 'маскирует значения известных секретных ENV-переменных' do
    ENV['TELEGRAM_BOT_TOKEN'] = 'supersecrettoken'
    ENV['MATCH_PASSWORD'] = 'matchpass123'

    text = 'Ошибка: supersecrettoken использован с matchpass123'
    result = sanitize_secrets(text)

    expect(result).not_to include('supersecrettoken')
    expect(result).not_to include('matchpass123')
    expect(result).to include('***')
  end

  it 'маскирует строки, похожие на telegram bot token' do
    text = 'token: 123456789:AAExxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx конец'
    result = sanitize_secrets(text)

    expect(result).not_to include('123456789:AAExxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx')
    expect(result).to include('***')
  end

  it 'не изменяет обычный текст без секретов' do
    ENV.delete('TELEGRAM_BOT_TOKEN')
    ENV.delete('APPSTORE_KEY_CONTENT')
    ENV.delete('MATCH_PASSWORD')
    ENV.delete('APPMETRICA_KEY')

    text = 'Обычное сообщение об успешной сборке версии 1.2.3'
    expect(sanitize_secrets(text)).to eq(text)
  end
end
