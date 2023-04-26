inhibit_all_warnings!

target 'MiniAppBuilder' do
  platform :macos, '10.14'

  use_frameworks!
  pod 'STPrivilegedTask', :git => 'https://github.com/rileytestut/STPrivilegedTask.git'
  pod 'ArgumentParserKit'
  # pod 'Sparkle'

end


post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '12.2'
    end
  end
end