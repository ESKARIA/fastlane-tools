# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'parse_provisioning_udid / mac_device_display_name' do
  describe 'parse_provisioning_udid' do
    it 'извлекает UDID из типичного вывода system_profiler' do
      output = <<~OUT
        Hardware:

            Hardware Overview:

              Model Name: MacBook Pro
              Model Identifier: MacBookPro18,3
              Chip: Apple M1 Pro
              Hardware UUID: 12345678-1234-1234-1234-123456789ABC
              Provisioning UDID: 00008103-000A2D8E3C28001E
              Activation Lock Status: Enabled
      OUT

      expect(parse_provisioning_udid(output)).to eq('00008103-000A2D8E3C28001E')
    end

    it 'работает при минимальном пробеле после двоеточия' do
      expect(parse_provisioning_udid('Provisioning UDID:00008103-000A2D8E3C28001E')).to eq('00008103-000A2D8E3C28001E')
    end

    it 'возвращает nil, если строка Provisioning UDID отсутствует' do
      output = <<~OUT
        Hardware:

            Hardware Overview:

              Model Name: MacBook Pro
              Hardware UUID: 12345678-1234-1234-1234-123456789ABC
      OUT

      expect(parse_provisioning_udid(output)).to be_nil
    end

    it 'возвращает nil для пустого/nil ввода' do
      expect(parse_provisioning_udid('')).to be_nil
      expect(parse_provisioning_udid(nil)).to be_nil
    end

    it 'возвращает nil для повреждённого/некорректного значения UDID' do
      output = "Provisioning UDID: \nOther: value"
      expect(parse_provisioning_udid(output)).to be_nil
    end

    it 'обрезает завершающие пробелы вокруг UDID' do
      expect(parse_provisioning_udid("Provisioning UDID:   ABCDEF-123456  \n")).to eq('ABCDEF-123456')
    end
  end

  describe 'mac_device_display_name' do
    it 'возвращает имя компьютера, если оно непустое' do
      expect(mac_device_display_name("Emil's MacBook Pro", '00008103-000A2D8E3C28001E')).to eq("Emil's MacBook Pro")
    end

    it 'обрезает пробелы вокруг имени компьютера' do
      expect(mac_device_display_name('  Emil MacBook  ', '00008103-000A2D8E3C28001E')).to eq('Emil MacBook')
    end

    it 'использует фоллбэк "Mac <последние 6 символов udid>", если имя компьютера пустое' do
      expect(mac_device_display_name('', '00008103-000A2D8E3C28001E')).to eq('Mac 28001E')
    end

    it 'использует фоллбэк, если имя компьютера состоит только из пробелов' do
      expect(mac_device_display_name('   ', '00008103-000A2D8E3C28001E')).to eq('Mac 28001E')
    end

    it 'использует фоллбэк, если имя компьютера nil' do
      expect(mac_device_display_name(nil, '00008103-000A2D8E3C28001E')).to eq('Mac 28001E')
    end

    it 'для UDID короче 6 символов [-6..] возвращает nil (та же семантика Ruby, что и в Messenger-источнике)' do
      # "AB12"[-6..] выходит за границы строки → nil → to_s → "" — это унаследованное
      # поведение оригинальной реализации (apps/ios-macos/fastlane/Fastfile), не баг здесь.
      expect(mac_device_display_name('', 'AB12')).to eq('Mac ')
    end

    it 'корректно строит фоллбэк для UDID ровно из 6 символов' do
      expect(mac_device_display_name('', 'ABCDEF')).to eq('Mac ABCDEF')
    end

    it 'корректно строит фоллбэк для длинного UDID (типичный формат Apple Silicon)' do
      expect(mac_device_display_name(nil, '00008103-000A2D8E3C28001E')).to eq('Mac 28001E')
    end
  end
end
