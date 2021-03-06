Pod::Spec.new do |s|
  s.name             = "SuperSerial"
  s.version          = "0.1.8"
  s.summary          = "JSON serialization/deserialization for Swift object & value types, with automatic stored-property inferrance in structs."


s.description      = "JSON serialization/deserialization for Swift value types (structs in particular) and objects, with automatic stored-property inferrance using Swift Mirror."

  s.homepage         = "https://github.com/pourhadi/SuperSerial"
  s.license          = 'MIT'
  s.author           = { "Daniel Pourhadi" => "dan@pourhadi.com" }
  s.source           = { :git => "https://github.com/pourhadi/SuperSerial.git", :tag => s.version.to_s }

  s.platform     = :ios, '8.0'
  s.requires_arc = true
  s.documentation_url = "http://pourhadi.github.io/SuperSerialDocumentation/"
  s.source_files = 'Pod/Classes/**/*'
  s.resource_bundles = {
    'SuperSerial' => ['Pod/Assets/*.png']
  }

end
