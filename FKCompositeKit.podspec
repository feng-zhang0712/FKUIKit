Pod::Spec.new do |s|
  s.name = 'FKCompositeKit'
  s.version = '0.45.0'
  s.summary = 'FKKit composite module: list coordination and shared controller/cell foundations.'
  s.description = <<-DESC
    Higher-level compositions built on FKCoreKit and FKUIKit: list state and
    pagination helpers, base table/collection cells, and base view controller utilities.
  DESC
  s.homepage = 'https://github.com/feng-zhang0712/FKKit'
  s.license = { :type => 'MIT', :file => 'LICENSE' }
  s.author = { 'Feng Zhang' => 'https://github.com/feng-zhang0712' }
  s.source = { :git => 'https://github.com/feng-zhang0712/FKKit.git', :tag => s.version.to_s }
  s.platform = :ios, '15.0'
  s.swift_version = '6.0'
  s.requires_arc = true

  s.dependency 'FKCoreKit', s.version.to_s
  s.dependency 'FKUIKit', s.version.to_s

  s.source_files = 'Sources/FKCompositeKit/**/*.swift'
end
