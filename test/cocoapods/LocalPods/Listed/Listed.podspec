# Lists its source folders in file system order, as the podspec of react-native-permissions does, so its checksum
# in Podfile.lock differs between hosts and the image must accept that
Pod::Spec.new do |s|
  s.name = 'Listed'
  s.version = '1.0.0'
  s.summary = 'Local pod of the licensed-action fixture'
  s.homepage = 'https://github.com/robgee86/licensed-action'
  s.license = { :type => 'MIT', :file => 'LICENSE' }
  s.author = 'licensed-action'
  s.source = { :git => 'https://github.com/robgee86/licensed-action.git' }
  s.platform = :ios, '15.0'
  folders = Dir.entries(File.join(__dir__, 'Sources')).reject { |entry| entry.start_with?('.') }
  s.source_files = folders.map { |folder| "Sources/#{folder}/*.h" }
end
