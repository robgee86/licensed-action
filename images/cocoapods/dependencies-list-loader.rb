# Preloaded by licensed into its pod dependencies call: loads the patched cocoapods-dependencies-list plugin of this
# image into whichever CocoaPods runs, the image's or the one of a repository bundle, so repositories need not add it
plugin = Dir["/var/lib/gems/*/gems/cocoapods-dependencies-list-*/lib"].first

if plugin
  # CocoaPods loads its plugins through CLAide once it is fully loaded, the image's copy joins them right after, also
  # when bundle exec runs pod inside its own Ruby process instead of starting a new one
  load_plugin = Module.new do
    define_method(:load_plugins) do |prefix|
      super(prefix).tap do
        next unless prefix == "cocoapods"

        $LOAD_PATH << plugin unless $LOAD_PATH.include?(plugin)
        require "cocoapods_dependencies_list"
      end
    end
  end

  hook = TracePoint.new(:end) do |trace|
    next unless trace.self.name == "CLAide::Command::PluginManager"

    hook.disable
    trace.self.singleton_class.prepend(load_plugin)
  end
  hook.enable
end
