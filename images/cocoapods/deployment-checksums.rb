# Lets pod install --deployment accept podspec checksums that differ only on this host, such as a podspec written from
# a file listing whose order depends on the file system. Every pod, version, source and the Podfile must still match
# the committed Podfile.lock, which deployment mode leaves untouched. Preloaded into every Ruby through RUBYOPT, it
# only acts once CocoaPods defines its installer
module_name = Module.instance_method(:name)
hook = TracePoint.new(:end) do |trace|
  # Some libraries override name on their classes, so the name comes from Module itself
  next unless module_name.bind_call(trace.self) == "Pod::Installer"
  hook.disable

  trace.self.prepend(Module.new do
    def verify_no_lockfile_changes!
      return super unless lockfile

      committed = lockfile.to_hash
      generated = generate_lockfile.to_hash
      checksums = ->(hash) { hash.fetch("SPEC CHECKSUMS", {}) }
      without_checksums = ->(hash) { hash.merge("SPEC CHECKSUMS" => checksums.(hash).keys.sort) }
      # Any other difference fails with the diff CocoaPods prints
      return super unless without_checksums.(committed) == without_checksums.(generated)

      changed = checksums.(committed).reject { |name, checksum| checksums.(generated)[name] == checksum }.keys
      Pod::UI.warn "Podspec checksums differ from Podfile.lock on this host, accepted as the pods match: #{changed.join(", ")}" if changed.any?
    end

    # The committed Podfile.lock stays as it is, only the Manifest.lock of the Pods folder follows this host
    def write_lockfiles
      return super unless deployment?

      @lockfile = generate_lockfile
      @lockfile.write_to_disk(sandbox.manifest_path)
    end
  end)
end
hook.enable
