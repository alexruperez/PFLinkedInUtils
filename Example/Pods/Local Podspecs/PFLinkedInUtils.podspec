Pod::Spec.new do |s|
  s.name             = "PFLinkedInUtils"
  s.version          = "0.1.5"
  s.summary          = "The PFLinkedInUtils class provides utility functions for working with LinkedIn in a Parse application."
  s.description      = <<-DESC
											 The PFLinkedInUtils class provides utility functions for working with LinkedIn in a Parse application.

											 This class is currently for iOS only.

											 ![PFLinkedInUtils Screenshot](https://raw.githubusercontent.com/alexruperez/PFLinkedInUtils/master/screenshot.png)
                       DESC
  s.homepage         = "https://github.com/alexruperez/PFLinkedInUtils"
  s.screenshots      = "https://raw.githubusercontent.com/alexruperez/PFLinkedInUtils/master/screenshot.png"
  s.license          = 'MIT'
  s.author           = { "alexruperez" => "contact@alexruperez.com" }
  s.source           = { :git => "https://github.com/alexruperez/PFLinkedInUtils.git", :tag => s.version.to_s }
  s.social_media_url = 'https://twitter.com/alexruperez'
	
  s.platform     = :ios, '6.0'
  s.requires_arc = true
	
  s.source_files = 'Pod/Classes'
  s.resource_bundles = {
    'PFLinkedInUtils' => ['Pod/Assets/*.png']
  }
	
  s.dependency 'Parse', '~> 1.6'
  s.dependency 'IOSLinkedInAPI', '~> 2.0'
end
