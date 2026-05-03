Pod::Spec.new do |s|
  s.name             = 'FKEmptyStateCoreLite'
  s.version          = '0.45.0'
  s.summary          = 'Foundation-only EmptyState resolver, i18n, and type factory for FKUIKit.'
  s.description      = <<-DESC
    Lightweight, UIKit-free subset of EmptyState: semantic resolution, i18n,
    and FKEmptyStateType factory. Linked by FKUIKit when integrating via CocoaPods.
  DESC
  s.homepage         = 'https://github.com/feng-zhang0712/FKKit'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'Feng Zhang' => 'https://github.com/feng-zhang0712' }
  s.source           = { :git => 'https://github.com/feng-zhang0712/FKKit.git', :tag => s.version.to_s }
  s.platform         = :ios, '15.0'
  s.swift_version    = '6.0'
  s.requires_arc     = true

  s.source_files     = 'Sources/FKUIKit/Components/EmptyState/CoreLite/**/*.swift'
end
