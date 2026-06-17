# frozen_string_literal: true
# UfukWidget app-extension target'ını projeye ekler.
# xcodeproj gem ile çalışır. Idempotent: target zaten varsa çıkar.

require "xcodeproj"

PROJECT = "Vakit.xcodeproj"
WIDGET_NAME = "UfukWidget"
APP_TARGET_NAME = "Vakit"
TEAM = "8XPP7Z37GF"
APP_GROUP = "group.com.fatihdisci.vakit.shared"

proj = Xcodeproj::Project.open(PROJECT)

if proj.targets.any? { |t| t.name == WIDGET_NAME }
  puts "✋ '#{WIDGET_NAME}' zaten var, atlanıyor."
  exit 0
end

app = proj.targets.find { |t| t.name == APP_TARGET_NAME } or abort("App target bulunamadı")

# 1) Widget target (app extension, iOS 17)
widget = proj.new_target(:app_extension, WIDGET_NAME, :ios, "17.0")

# 2) Paylaşılan kod: mevcut 'Shared' synchronized group'u widget'a da bağla.
shared_sync = proj.objects.find do |o|
  o.isa == "PBXFileSystemSynchronizedRootGroup" && o.display_name == "Shared"
end or abort("Shared sync group bulunamadı")
widget.file_system_synchronized_groups ||= []
widget.file_system_synchronized_groups << shared_sync

# 3) Widget kaynak dosyası: UfukWidget/UfukWidget.swift (explicit ref)
group = proj.main_group.find_subpath(WIDGET_NAME, true)
group.set_source_tree("<group>")
group.set_path(WIDGET_NAME)

swift_ref = group.new_reference("UfukWidget.swift")
widget.source_build_phase.add_file_reference(swift_ref)

# Info.plist + entitlements navigator referansları (build phase'e EKLENMEZ)
group.new_reference("Info.plist")
group.new_reference("UfukWidget.entitlements")

# 4) Build settings (Debug + Release)
widget.build_configurations.each do |config|
  s = config.build_settings
  s["PRODUCT_BUNDLE_IDENTIFIER"] = "com.vakit.app.widget"
  s["PRODUCT_NAME"] = "$(TARGET_NAME)"
  s["INFOPLIST_FILE"] = "#{WIDGET_NAME}/Info.plist"
  s["GENERATE_INFOPLIST_FILE"] = "NO"
  s["CODE_SIGN_ENTITLEMENTS"] = "#{WIDGET_NAME}/#{WIDGET_NAME}.entitlements"
  s["CODE_SIGN_STYLE"] = "Automatic"
  s["DEVELOPMENT_TEAM"] = TEAM
  s["IPHONEOS_DEPLOYMENT_TARGET"] = "17.0"
  s["SWIFT_VERSION"] = "5.0"
  s["TARGETED_DEVICE_FAMILY"] = "1"
  s["MARKETING_VERSION"] = "1.0.0"
  s["CURRENT_PROJECT_VERSION"] = "6"
  s["SKIP_INSTALL"] = "YES"
  s["ENABLE_PREVIEWS"] = "YES"
  s["SWIFT_EMIT_LOC_STRINGS"] = "YES"
  s["LD_RUNPATH_SEARCH_PATHS"] = [
    "$(inherited)",
    "@executable_path/Frameworks",
    "@executable_path/../../Frameworks",
  ]
  s["SWIFT_ACTIVE_COMPILATION_CONDITIONS"] = "DEBUG" if config.name == "Debug"
  s["SWIFT_OPTIMIZATION_LEVEL"] = "-Onone" if config.name == "Debug"
end

# 5) App target → widget dependency + embed (Copy Files / PlugIns)
app.add_dependency(widget)

embed = app.copy_files_build_phases.find { |p| p.symbol_dst_subfolder_spec == :plug_ins }
embed ||= app.new_copy_files_build_phase("Embed Foundation Extensions")
embed.symbol_dst_subfolder_spec = :plug_ins
embed.dst_path = ""
unless embed.files_references.include?(widget.product_reference)
  bf = embed.add_file_reference(widget.product_reference)
  bf.settings = { "ATTRIBUTES" => ["RemoveHeadersOnCopy"] }
end

proj.save
puts "✅ '#{WIDGET_NAME}' target eklendi."
