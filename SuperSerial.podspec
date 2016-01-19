#
# Be sure to run `pod lib lint SuperSerial.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = "SuperSerial"
  s.version          = "0.1.2"
  s.summary          = "Serialization for Swift value types."

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!  
s.description      = "Serialization for Swift value types (structs in particular) and objects."

  s.homepage         = "https://github.com/pourhadi/SuperSerial"
  s.license          = 'MIT'
  s.author           = { "Daniel Pourhadi" => "dan@pourhadi.com" }
  s.source           = { :git => "https://github.com/pourhadi/SuperSerial.git", :tag => s.version.to_s }

  s.platform     = :ios, '8.0'
  s.requires_arc = true

  s.source_files = 'Pod/Classes/**/*'
  s.resource_bundles = {
    'SuperSerial' => ['Pod/Assets/*.png']
  }

end
