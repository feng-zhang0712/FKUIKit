Pod::Spec.new do |s|
  s.name             = 'FKCoreKit'
  s.version          = '0.45.0'
  s.summary          = 'FKKit core module: networking, storage, security, utilities, and extensions.'
  s.description      = <<-DESC
    Foundation layer for the FKKit family: async helpers, business utilities,
    file I/O, logging, networking, permissions, security, storage, and the
    FKCoreKit Extension helpers (Foundation / CoreGraphics / UIKit).
  DESC
  s.homepage         = 'https://github.com/feng-zhang0712/FKKit'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'Feng Zhang' => 'https://github.com/feng-zhang0712' }
  s.source           = { :git => 'https://github.com/feng-zhang0712/FKKit.git', :tag => s.version.to_s }
  s.platform         = :ios, '15.0'
  s.swift_version    = '6.0'
  s.requires_arc     = true

  s.source_files     = 'Sources/FKCoreKit/**/*.swift'
end
