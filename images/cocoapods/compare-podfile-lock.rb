# Compares a committed Podfile.lock with the one pod install wrote: only the checksums of pods the committed file
# already lists may differ, they are reported and accepted, any other difference fails
require "yaml"

# CocoaPods writes some keys as symbols, such as the :path of a local pod
def load_lockfile(path)
  YAML.safe_load(File.read(path), permitted_classes: [Symbol], aliases: true) || {}
end

def checksums(lockfile)
  lockfile.fetch("SPEC CHECKSUMS", {})
end

def without_checksums(lockfile)
  lockfile.merge("SPEC CHECKSUMS" => checksums(lockfile).keys.sort)
end

committed_path, written_path = ARGV
committed = load_lockfile(committed_path)
written = load_lockfile(written_path)

unless without_checksums(committed) == without_checksums(written)
  sections = (committed.keys | written.keys).reject do |key|
    without_checksums(committed)[key] == without_checksums(written)[key]
  end
  warn "pod install changed #{written_path} beyond podspec checksums, in #{sections.join(", ")}: " \
       "run pod install and commit the lockfile"
  exit 1
end

changed = checksums(committed).reject { |name, checksum| checksums(written)[name] == checksum }.keys
unless changed.empty?
  warn "Podspec checksums differ from #{written_path} on this host, accepted as the pods match: #{changed.join(", ")}"
end
