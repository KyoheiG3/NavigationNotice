Pod::Spec.new do |s|
  s.name         = "NavigationNotice"
  s.version      = "2.0.0"
  s.summary      = "Customizable and interactive animated notification UI control."
  s.homepage     = "https://github.com/KyoheiG3/NavigationNotice"
  s.license      = { :type => "MIT", :file => "LICENSE" }
  s.author       = { "Kyohei Ito" => "je.suis.kyohei@gmail.com" }
  s.swift_version = '4.2'
  s.platform     = :ios, "8.0"
  s.source       = { :git => "https://github.com/KyoheiG3/NavigationNotice.git", :tag => s.version.to_s }
  s.source_files  = "NavigationNotice/**/*.{h,swift}"
  s.requires_arc = true
  s.frameworks = "UIKit"
end
