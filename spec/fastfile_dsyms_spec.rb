# frozen_string_literal: true

require 'spec_helper'

unless Object.private_method_defined?(:desc)
  def desc(*)
    nil
  end
end

unless Object.private_method_defined?(:lane)
  def lane(*)
    nil
  end
end

load File.expand_path('../fastlane/Fastfile_dsyms', __dir__)

RSpec.describe '#spool_and_upload_dsyms' do
  let(:workspace) { Dir.mktmpdir('fastlane-dsym-spec-') }
  let(:spool) { "#{workspace}-spool" }
  let(:helper_path) { File.join(workspace, 'helper') }

  around do |example|
    original_env = %w[APP_VERSION BUILD_NUMBER CI_PIPELINE_ID CI_PIPELINE_IID CI_JOB_ID].to_h do |key|
      [key, ENV[key]]
    end
    example.run
  ensure
    original_env.each do |key, value|
      value.nil? ? ENV.delete(key) : ENV[key] = value
    end
    FileUtils.rm_rf([workspace, spool])
  end

  before do
    FileUtils.mkdir_p(File.join(workspace, 'fastlane', 'artifacts'))
    File.write(helper_path, 'test helper')
    stub_const('APP_IDENTIFIER', 'com.example.primary')
    stub_const('APPMETRICA_KEY', 'test-key')
    stub_const('HELPER_PATH', helper_path)
    ENV['APP_VERSION'] = '1.2.3'
    ENV['BUILD_NUMBER'] = '42'
    ENV['CI_PIPELINE_ID'] = 'pipeline-100'
    ENV['CI_PIPELINE_IID'] = '100'
    ENV['CI_JOB_ID'] = 'job-200'
  end

  def write_archive(name, contents = 'dSYM bytes')
    path = File.join(workspace, 'fastlane', 'artifacts', name)
    File.binwrite(path, contents)
    path
  end

  def entry_dirs
    Dir.glob(File.join(spool, 'entry-*')).select { |path| File.directory?(path) }
  end

  def invoke
    Dir.chdir(workspace) { spool_and_upload_dsyms(spool) }
  end

  # Fastlane provides this action at runtime; define it in the isolated spec
  # context so RSpec can verify and stub the helper call.
  def sh(*_args, **_options)
    true
  end

  def stub_successful_commands
    allow(self).to receive(:sh) { true }
  end

  it 'atomically enqueues an archive and deduplicates a retry of the same pipeline' do
    write_archive('App.dSYM.zip')
    FileUtils.rm_f(helper_path)

    2.times { invoke }

    expect(entry_dirs.length).to eq(1)
    entry_dir = entry_dirs.first
    manifest = JSON.parse(File.read(File.join(entry_dir, 'manifest.json')))
    expect(File.file?(File.join(entry_dir, 'archive.dSYM.zip'))).to be(true)
    expect(manifest).to include(
      'app_id' => 'com.example.primary',
      'target_artifact_basename' => nil,
      'version' => '1.2.3',
      'build' => '42',
      'pipeline_id' => 'pipeline-100',
      'pipeline_iid' => '100',
      'job_id' => 'job-200',
      'original_archive_name' => 'App.dSYM.zip'
    )
    expect(manifest['sha256']).to match(/\A[0-9a-f]{64}\z/)
    expect(File.stat(entry_dir).mode & 0o777).to eq(0o700)
    expect(File.stat(File.join(entry_dir, 'archive.dSYM.zip')).mode & 0o777).to eq(0o600)
    expect(Dir.glob(File.join(spool, '.pending-*'))).to be_empty
  end

  it 'removes the complete entry directory only after helper success' do
    write_archive('App.dSYM.zip')
    stub_successful_commands

    expect(invoke).to be(true)
    expect(entry_dirs).to be_empty
  end

  it 'retains failed uploads, warns, and continues with later entries' do
    write_archive('First.dSYM.zip', 'first')
    write_archive('Second.dSYM.zip', 'second')
    helper_calls = 0
    allow(self).to receive(:sh) do |command, **_options|
      if command.start_with?(helper_path)
        helper_calls += 1
        raise 'provider unavailable' if helper_calls == 1
      end
      true
    end
    allow(UI).to receive(:important)

    expect(invoke).to be(true)
    expect(helper_calls).to eq(2)
    expect(entry_dirs.length).to eq(1)
    expect(UI).to have_received(:important).with(/запись оставлена в очереди/).once
  end

  it 'uploads only entries for the current primary app' do
    write_archive('Primary.dSYM.zip')
    FileUtils.rm_f(helper_path)
    invoke
    primary_entry = entry_dirs.first
    FileUtils.rm_f(File.join(workspace, 'fastlane', 'artifacts', 'Primary.dSYM.zip'))

    stub_const('APP_IDENTIFIER', 'com.example.secondary')
    write_archive('Secondary.dSYM.zip', 'secondary')
    File.write(helper_path, 'test helper')
    stub_successful_commands
    invoke

    expect(File.directory?(primary_entry)).to be(true)
    expect(entry_dirs.length).to eq(1)
    expect(JSON.parse(File.read(File.join(primary_entry, 'manifest.json')))['app_id']).to eq('com.example.primary')
  end

  it 'waits for the process-safe spool lock before processing entries' do
    FileUtils.mkdir_p(spool)
    lock_path = File.join(spool, '.lock')
    File.open(lock_path, File::RDWR | File::CREAT, 0o600) do |lock|
      lock.flock(File::LOCK_EX)
      worker = Thread.new { invoke }
      sleep 0.05
      waiting_for_lock = worker.alive?
      lock.flock(File::LOCK_UN)
      worker.join
      expect(waiting_for_lock).to be(true)
      expect(worker.value).to be(false)
    end
  end
end
