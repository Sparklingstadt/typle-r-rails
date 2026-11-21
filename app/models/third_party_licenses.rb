# The third-party software this app ships, for /about/licenses (typle-r's LicenseList and third-party.txt): the gems of
# the bundle, as their gemspecs name them, and the browser-side parts the app serves itself.
module ThirdPartyLicenses
  Entry = Data.define(:name, :version, :license, :url, :text)

  # Served from public/ or by importmap rather than installed as gems.
  BROWSER = [
    { name: "onnxruntime-web", license: "MIT", url: "https://github.com/microsoft/onnxruntime", text: "public/handwriting/ort/onnxruntime-LICENSE.txt" },
    { name: "PaddleOCR (handwriting models)", license: "Apache-2.0", url: "https://github.com/PaddlePaddle/PaddleOCR", text: "public/handwriting/LICENSE-models.txt" }
  ].freeze

  LICENSE_FILES = %w[LICENSE LICENSE.txt LICENSE.md MIT-LICENSE MIT-LICENSE.txt LICENCE COPYING LICENSE-MIT].freeze

  module_function

  def entries
    @entries ||= begin
      gems = Bundler.load.specs.sort_by(&:name).map do |spec|
        file = LICENSE_FILES.map { |name| File.join(spec.full_gem_path, name) }.find { |path| File.file?(path) }
        Entry.new(name: spec.name, version: spec.version.to_s, license: Array(spec.licenses).join(" OR ").presence || "—",
          url: spec.homepage.to_s, text: file)
      end
      browser = BROWSER.map { |item| Entry.new(name: item[:name], version: "", license: item[:license], url: item[:url], text: Rails.root.join(item[:text]).to_s) }
      (gems + browser).sort_by { |entry| entry.name.downcase }
    end
  end

  # Every license text, one after another under the name of what it belongs to.
  def full_text
    entries.filter_map { |entry|
      next unless entry.text && File.file?(entry.text)
      "#{entry.name} #{entry.version}".strip + " (#{entry.license})\n#{"=" * 72}\n#{File.read(entry.text).scrub.strip}\n"
    }.join("\n\n")
  end
end
