# frozen_string_literal: true

require 'spec_helper'

RSpec.describe FastlaneMetrics do
  subject(:metrics) { described_class.new('test_lane') }

  describe '#add_metric' do
    it 'добавляет произвольную метрику' do
      metrics.add_metric(:custom_key, 'custom_value')
      expect(metrics.metrics[:custom_key]).to eq('custom_value')
    end
  end

  describe '#finish' do
    it 'устанавливает end_time и вычисляет длительность' do
      expect { metrics.finish }.to change(metrics, :end_time).from(nil)

      expect(metrics.metrics[:duration_seconds]).to be_a(Numeric)
      expect(metrics.metrics[:duration_formatted]).to be_a(String)
    end
  end

  describe '#format_duration' do
    it 'форматирует секунды' do
      expect(metrics.format_duration(5.4)).to eq('5.4 сек')
    end

    it 'форматирует минуты' do
      expect(metrics.format_duration(125)).to eq('2 мин 5 сек')
    end

    it 'форматирует часы' do
      expect(metrics.format_duration(3725)).to eq('1 ч 2 мин')
    end
  end

  describe '#save_to_file' do
    it 'сохраняет метрики во временный файл' do
      Dir.mktmpdir do |dir|
        file_path = File.join(dir, 'metrics.json')
        metrics.finish
        metrics.save_to_file(file_path)

        expect(File.exist?(file_path)).to be true
        data = JSON.parse(File.read(file_path, encoding: 'UTF-8'))
        expect(data).to be_an(Array)
        expect(data.length).to eq(1)
        expect(data.first['lane']).to eq('test_lane')
      end
    end

    it 'хранит не более 100 последних записей' do
      Dir.mktmpdir do |dir|
        file_path = File.join(dir, 'metrics.json')

        105.times do |i|
          m = described_class.new("lane_#{i}")
          m.finish
          m.save_to_file(file_path)
        end

        data = JSON.parse(File.read(file_path, encoding: 'UTF-8'))
        expect(data.length).to eq(100)
        expect(data.first['lane']).to eq('lane_5')
        expect(data.last['lane']).to eq('lane_104')
      end
    end
  end
end
