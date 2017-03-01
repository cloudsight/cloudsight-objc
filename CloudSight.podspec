Pod::Spec.new do |s|
  s.name         = "CloudSight"
  s.version      = "1.0.4"
  s.summary      = "CloudSight image recognition API interface in Objective-C"

  s.description  = <<-DESC
                   CloudSight is a simple web API for image recognition.  This library is
                   an implementation in Objective-C for developing applications that leverage
                   the CloudSight image recognition API, and is derived from the CamFind iOS app.
                   DESC

  s.homepage     = "http://cloudsightapi.com"
  s.license      = { :type => "MIT" }
  s.authors      = { "Bradford Folkens" => "brad@cloudsightapi.com" }
  s.social_media_url = "http://twitter.com/CloudSightAPI"

  s.ios.deployment_target = "6.0"
  s.osx.deployment_target = "10.8"

  s.source = { :git => "https://github.com/cloudsight/cloudsight-objc.git", :tag => s.version }
  s.requires_arc = true

  s.source_files  = "CloudSight/*.{h,m}"
  #s.public_header_files = "CloudSight/*.h"

  s.dependency 'BFOAuth', '~> 1.0'
  s.dependency 'RequestUtils', '~> 1.1'

  s.frameworks = 'CoreLocation', 'CoreGraphics'
end
