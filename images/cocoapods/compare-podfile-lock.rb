# Compares a committed Podfile.lock with the one pod install wrote. Only the checksums of pods built from a local path,
# its EXTERNAL SOURCES, may differ, as their podspecs can depend on the host, they are reported and accepted. The
# checksums of pods from spec repositories must match exactly, and any other difference fails
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
from_repositories = changed - committed.fetch("EXTERNAL SOURCES", {}).keys
unless from_repositories.empty?
  warn "The podspec checksums of #{from_repositories.join(", ")}, from spec repositories, differ from #{written_path}: " \
       "run pod install and commit the lockfile"
  exit 1
end

unless changed.empty?
  warn "Podspec checksums differ from #{written_path} on this host, accepted as the pods match: #{changed.join(", ")}"
end
