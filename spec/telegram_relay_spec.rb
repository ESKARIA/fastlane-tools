# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'telegram_relay_enabled?' do
  around do |example|
    old_env = ENV.to_hash
    example.run
    ENV.replace(old_env)
  end

  it 'выключен, если TELEGRAM_USE_RELAY не установлен' do
    ENV.delete('TELEGRAM_USE_RELAY')
    expect(telegram_relay_enabled?).to be(false)
  end

  it 'выключен, если TELEGRAM_USE_RELAY не "true"' do
    ENV['TELEGRAM_USE_RELAY'] = 'yes'
    expect(telegram_relay_enabled?).to be(false)
  end

  it 'откатывается на прямой API, если не заданы TELEGRAM_RELAY_BASE_URL/TELEGRAM_RELAY_API_KEY' do
    ENV['TELEGRAM_USE_RELAY'] = 'true'
    ENV.delete('TELEGRAM_RELAY_BASE_URL')
    ENV.delete('TELEGRAM_RELAY_API_KEY')
    expect(telegram_relay_enabled?).to be(false)
  end

  it 'включен, если все переменные заданы' do
    ENV['TELEGRAM_USE_RELAY'] = 'true'
    ENV['TELEGRAM_RELAY_BASE_URL'] = 'https://relay.example.com'
    ENV['TELEGRAM_RELAY_API_KEY'] = 'tgp_test'
    expect(telegram_relay_enabled?).to be(true)
  end
end

RSpec.describe 'telegram_relay_send_message / telegram_relay_edit_message' do
  around do |example|
    old_env = ENV.to_hash
    example.run
    ENV.replace(old_env)
  end

  before do
    ENV['TELEGRAM_USE_RELAY'] = 'true'
    ENV['TELEGRAM_RELAY_BASE_URL'] = 'https://relay.example.com'
    ENV['TELEGRAM_RELAY_API_KEY'] = 'tgp_test'
  end

  # Двойник http-ответа: у Net::HTTPResponse есть #code (String) и #body.
  def fake_response(code, body)
    instance_double(Net::HTTPResponse, code: code, body: body)
  end

  it 'возвращает telegram_message_id после успешной доставки' do
    send_response = fake_response('202', '{"message_id":"outbox-uuid-1"}')
    status_response = fake_response('200', '{"status":"delivered","telegram_message_id":456}')

    http = instance_double(Net::HTTP, request: nil)
    allow(Net::HTTP).to receive(:new).and_return(http)
    allow(http).to receive(:use_ssl=)
    allow(http).to receive(:read_timeout=)
    allow(http).to receive(:open_timeout=)
    allow(http).to receive(:request).and_return(send_response, status_response)

    result = telegram_relay_send_message('hello', chat_id: '123')

    expect(result).to eq(456)
  end

  it 'возвращает nil, если relay сообщил, что доставка не удалась' do
    send_response = fake_response('202', '{"message_id":"outbox-uuid-2"}')
    # "failed" — терминальный статус, поэтому wait_for_status возвращает его
    # сразу, без реального ожидания/sleep.
    failed_response = fake_response('200', '{"status":"failed"}')

    http = instance_double(Net::HTTP, request: nil)
    allow(Net::HTTP).to receive(:new).and_return(http)
    allow(http).to receive(:use_ssl=)
    allow(http).to receive(:read_timeout=)
    allow(http).to receive(:open_timeout=)
    allow(http).to receive(:request).and_return(send_response, failed_response)

    result = telegram_relay_send_message('hello', chat_id: '123')

    expect(result).to be_nil
  end

  it 'возвращает nil, если POST /send вернул не-2xx' do
    error_response = fake_response('401', '{"error":"invalid or missing api key"}')

    http = instance_double(Net::HTTP, request: nil)
    allow(Net::HTTP).to receive(:new).and_return(http)
    allow(http).to receive(:use_ssl=)
    allow(http).to receive(:read_timeout=)
    allow(http).to receive(:open_timeout=)
    allow(http).to receive(:request).and_return(error_response)

    result = telegram_relay_send_message('hello', chat_id: '123')

    expect(result).to be_nil
  end

  it 'edit_telegram_message возвращает true, когда relay подтвердил доставку правки' do
    send_response = fake_response('202', '{"message_id":"outbox-uuid-3"}')
    status_response = fake_response('200', '{"status":"delivered"}')

    http = instance_double(Net::HTTP, request: nil)
    allow(Net::HTTP).to receive(:new).and_return(http)
    allow(http).to receive(:use_ssl=)
    allow(http).to receive(:read_timeout=)
    allow(http).to receive(:open_timeout=)
    allow(http).to receive(:request).and_return(send_response, status_response)

    expect(edit_telegram_message(456, 'updated text', chat_id: '123')).to be(true)
  end
end
