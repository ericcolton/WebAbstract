#
# Be sure to run `pod lib lint NAME.podspec' to ensure this is a
# valid spec and remove all comments before submitting the spec.
#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#
Pod::Spec.new do |s|
  s.name             = "WebAbstract"
  s.version          = "0.1.0"
  s.summary          = "Organizes and maintains xPath-based HTML parse instructions in Objective-C"
  s.description      = <<-DESC

                       WebAbstract provides an organized way to configure and maintain parse instructions in property lists using xPath and/or regular expressions should you find yourself needing to parse HTML directly in Objective-C.  I wrote this module for use in 'Gymclass', an iOS project.
                       DESC
  s.homepage         = "https://github.com/ericcolton/WebAbstract"
  s.license          = 'MIT'
  s.author           = { "Eric Colton" => "ericcolton@gmail.com" }
  s.source           = { :git => "https://github.com/ericcolton/WebAbstract.git", :tag => "0.1.0" }

  s.platform     = :ios

  s.ios.deployment_target = "6.0"
  s.requires_arc = true

  s.dependency "hpple", "~> 0.2"

  s.source_files = 'WebAbstract/*{.h,.m}'

  s.library = 'xml2'

  s.public_header_files = 'WebAbstract/*.h'

  def s.copy_header_mapping(from)
    from.relative_path_from(Pathname.new('Code'))
  end
end
