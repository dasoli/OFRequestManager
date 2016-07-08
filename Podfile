workspace 'OFRequestManager'
xcodeproj 'OFRequestManager.xcodeproj'
xcodeproj 'OFRequestManagerDemo/OFRequestManagerDemo.xcodeproj'
inhibit_all_warnings!
platform :ios, '7.1'

target :OFRequestManager do
  target 'RequestManagerTests' do
    inherit! :search_paths
    pod 'AFNetworking'
  end
  pod 'AFNetworking'
  xcodeproj 'OFRequestManager.xcodeproj'
end

target :OFRequestManagerDemo do
  pod 'AFNetworking'
  xcodeproj 'OFRequestManagerDemo/OFRequestManagerDemo.xcodeproj'
end
