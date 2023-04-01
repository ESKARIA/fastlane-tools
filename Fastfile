# Uncomment the line if you want fastlane to automatically update itself
# update_fastlane

CACHE_DIR = Dir.mktmpdir('fastlane_tools_cache').freeze
Dir.glob(File.join(CACHE_DIR, '*Fastfile')).each { |fastfile| import fastfile }

default_platform(:ios)

APP_IDENTIFIER              = ENV['APP_IDENTIFIER']

DERIVED_PATH                = "build"
CRASHLYTICS_PATH            = "./SourcePackages/checkouts/firebase-ios-sdk/Crashlytics/upload-symbols"

### metadata ###
DATA_META_PATH              = "./fastlane/metadata"
DATA_SCREEN_PATH            = "./fastlane/screenshots"

### Project ###
MAIN_PROJECT_FILE           = ENV['MAIN_TARGET'] + ".xcodeproj"
MAIN_TARGET                 = ENV['MAIN_TARGET']

### Appstore keys ###
APPSTORE_KEY_ID             = ENV['APPSTORE_KEY_ID']
APPSTORE_ISSUER_ID          = ENV['APPSTORE_ISSUER_ID']
APPSTORE_KEY_CONTENT        = ENV['APPSTORE_KEY_CONTENT']

CI_PROJECT_DIR              = ENV['CI_PROJECT_DIR']

BUILD_NUMBER                = ENV['BUILD_NUMBER']
APPMETRICA_KEY              = ENV['APPMETRICA_KEY']

api_key = app_store_connect_api_key(key_id: APPSTORE_KEY_ID,
                                    issuer_id: APPSTORE_ISSUER_ID,
                                    key_content: APPSTORE_KEY_CONTENT,
                                    in_house: false,
                                    is_key_content_base64: true)

before_all do
    # update_fastlane
    clear_keychain
    if ENV['CI']
        clear_derived_data
        UI.message("Run on remote CI machine")
        clear_derived_data(derived_data_path: DERIVED_PATH)
        
    end
end

after_all do 
    # clear_keychain
end

lane :clear_keychain do 
    sh("security default-keychain -d user -s ~/Library/Keychains/login.keychain-db || true")
    sh("security delete-keychain ~/Library/Keychains/fastlane_tmp_keychain-db || true")
    sh("rm -rf ~/Library/MobileDevice/Provisioning\ Profiles/*.mobileprovision || true")
end

lane :create_tmp_keychain do
    name = "fastlane_tmp_keychain"
    # delete_keychain(name: name) if File.exist? File.expand_path("~/Library/Keychains/#{name}-db")
    # setup_ci
end

def ensure_temp_keychain(name)
    delete_keychain(name: name) if File.exist? File.expand_path("~/Library/Keychains/#{name}-db")
    create_keychain(name: name, password: KEYCHAIN_PASSWORD, default_keychain: true, unlock: true, timeout: 0, lock_when_sleeps: false)
end

def send_information(action_text:, title_text:, version_text:, error_text:, success_bool:)

end

# error block is executed when a error occurs
error do |lane, exception, options|
  if is_ci
    build_number = get_build_number.to_s
    version_number = get_version_number(xcodeproj: MAIN_PROJECT_FILE, target: MAIN_TARGET)

    send_information(
      action_text: "[ERROR] ❌:", 
      title_text: "#{MAIN_TARGET}", 
      version_text: "version: #{version_number.to_s} build #{build_number.to_s}", 
      error_text: "Error: #{exception.to_s}", 
      success_bool: false)
  end
end

desc "Information about start"
lane :starting do |options|

  info_message = options[:test] ? "[TESTS] 🛠" : "[DEPLOY] 🛠" 
  version_number = get_version_number(xcodeproj: MAIN_PROJECT_FILE, target: MAIN_TARGET)
  build_number = latest_testflight_build_number(api_key: api_key, app_identifier: APP_IDENTIFIER).to_i + 1

  send_information(
    action_text: info_message, 
    title_text: "#{MAIN_TARGET}", 
    version_text: "version: #{version_number.to_s} build #{build_number.to_s}", 
    error_text: "", 
    success_bool: true)
end