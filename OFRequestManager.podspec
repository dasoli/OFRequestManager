Pod::Spec.new do |s|
  s.name                  = "OFRequestManager"
  s.version               = "0.1"
  s.summary               = "User friendly RequestManager on top of AFNetworking 3.x"
  s.homepage              = "https://github.com/dasoli/OFRequestManager.git"
  s.authors               = { "Oliver Franke" => "ofranke@web.de" }
  s.license	              = { :type => 'MIT' }

  s.source                = { :git => "https://github.com/dasoli/OFRequestManager.git", :branch => "master", :tag => "#{s.version}" }

  s.ios.deployment_target = "7.1"
  s.requires_arc          = true

  s.source_files          = "OFRequestManager"
  s.public_header_files   = "OFRequestManager/*.h"
  s.private_header_files  = "OFRequestManager/*+Private.h"

  s.dependency "AFNetworking", "~> 3.1.0"

end
