Pod::Spec.new do |s|
  s.name = 'FKUIKit'
  s.version = '0.45.0'
  s.summary = 'FKKit UIKit components: buttons, tab bar, presentation, skeleton, toast, and more.'
  s.description = <<-DESC
    Reusable UIKit building blocks from FKKit (Badge, BlurView, Button,
    CornerShadow, Divider, EmptyState, ExpandableText, MultiPicker,
    PresentationController, Refresh, Skeleton, TabBar, TextField, Toast).
    Depends on FKEmptyStateCoreLite (same repository and tag).
  DESC
  s.homepage = 'https://github.com/feng-zhang0712/FKKit'
  s.license = { :type => 'MIT', :file => 'LICENSE' }
  s.author = { 'Feng Zhang' => 'https://github.com/feng-zhang0712' }
  s.source = { :git => 'https://github.com/feng-zhang0712/FKKit.git', :tag => s.version.to_s }
  s.platform = :ios, '15.0'
  s.swift_version = '6.0'
  s.requires_arc = true

  s.dependency 'FKEmptyStateCoreLite', s.version.to_s

  s.source_files = 'Sources/FKUIKit/**/*.swift'
  s.exclude_files = 'Sources/FKUIKit/Components/EmptyState/CoreLite/**/*'
end
