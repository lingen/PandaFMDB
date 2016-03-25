#
# Be sure to run `pod lib lint PandaFMDB.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = "PandaFMDB"
  s.version          = "0.1.1"
  s.summary          = "PandaFMDB对FMDB的封装库"

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!
  s.description      = <<-DESC
    FMDB是SQLite上最强大的工具，本库仅基于多个项目实践，封装FMDB，以便做到开箱即用
                       DESC

  s.homepage         = "https://github.com/openpandaOrg/PandaFMDB"
  # s.screenshots     = "www.example.com/screenshots_1", "www.example.com/screenshots_2"
  s.license          = 'MIT'
  s.author           = { "lingen.liu" => "lingen.liu@gmail.com" }
  s.source           = { :git => "https://github.com/openpandaOrg/PandaFMDB.git", :tag => s.version.to_s }
  # s.social_media_url = 'https://twitter.com/<TWITTER_USERNAME>'

  s.platform     = :ios, '7.0'
  s.requires_arc = true

  s.source_files = 'Pod/Classes/**/*'
  s.resource_bundles = {
    'PandaFMDB' => ['Pod/Assets/*.png']
  }

    s.public_header_files = 'Pod/Classes/**/*.h'
  # s.frameworks = 'UIKit', 'MapKit'
    s.dependency 'FMDB/SQLCipher'

end
