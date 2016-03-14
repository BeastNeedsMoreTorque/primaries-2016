require_relative '../lib/paths'

ShortAge = 5
MaxAge = 365 * 86400 # 1yr

# Uploads stuff to S3
#
# Usage:
#
#   uploader = Uploader.new # uses environment variables
#   uploader.upload_assets
#   uploader.upload_pages
class Uploader
  def initialize
    s3_bucket = ENV['S3_BUCKET']
    if s3_bucket.nil? || s3_bucket.empty?
      raise 'You must set the `S3_BUCKET` environment variable'
    end
    @bucket = Aws::S3::Bucket.new(s3_bucket)

    # We cache the sha1s of files we upload, so we don't need to upload twice.
    # This shaves a few seconds off our upload times on election night: we won't
    # need to re-upload the JavaScript over and over again.
    @already_uploaded = {} # relative_path -> sha1
  end

  # Upload all assets to the server.
  #
  # Upload the never-expiring assets first. They're fingerprinted, and we never
  # delete the old fingerprints. By uploading them first, we guarantee we don't
  # upload an HTML file that points to an asset before that asset is uploaded.
  def upload_assets
    Dir["#{Paths.Dist}/**/*.*"].select{ |s| s !~ /\.(html|json|txt)$/ }.sort.each do |filename|
      content_type = if filename =~ /\.css$/
        'text/css; charset=utf-8'
      elsif filename =~ /\.png$/
        'image/png'
      elsif filename =~ /\.jpg$/
        'image/jpeg'
      elsif filename =~ /\.gif$/
        'image/gif'
      elsif filename =~ /\.svg$/
        'image/svg+xml'
      elsif filename =~ /\.txt$/
        'text/plain'
      elsif filename =~ /\.js$/
        'application/javascript; charset=utf-8'
      else
        raise "Aah, this file shouldn't exist: #{filename}"
      end

      upload_if_changed(filename, content_type, MaxAge)
    end
  end

  # Upload all data to the server.
  #
  # Be sure to upload the assets first, because the data files depend on them.
  def upload_content
    # First, the JSON. If we uploaded HTML before JSON, then a race could cause
    # the user to see results disappear.
    #
    # Actually, caching means this race still exists. But let's not make the
    # situation any worse.
    Dir["#{Paths.Dist}/**/*.json"].each do |filename|
      upload_if_changed(filename, 'application/json', ShortAge)
    end

    # Then the HTML
    Dir["#{Paths.Dist}/**/*.html"].each do |filename|
      upload_if_changed(filename, 'text/html; charset=utf-8', ShortAge)
    end
  end

  private

  def upload_if_changed(absolute_path, content_type, max_age)
    relative_path = absolute_path[(Paths.Dist.length + 1) .. -1]

    debug_path = "s3://#{@bucket.name}/#{relative_path}"

    contents = IO.read(absolute_path)
    digest = hexdigest(contents)

    if @already_uploaded[relative_path] != digest
      $logger.info("PUT #{debug_path} #{content_type}")

      File.open(absolute_path, 'r') do |f|
        @bucket.put_object({
          key: relative_path.sub(/\.html$/, ''),
          acl: 'public-read',
          body: f,
          cache_control: "public, max-age=#{max_age}",
          content_type: content_type,
          expires: Time.now + max_age
        })
      end

      @already_uploaded[relative_path] = digest
    else
      $logger.debug("SKIP #{debug_path}")
    end
  end

  def hexdigest(data)
    Digest::SHA1.hexdigest(data)
  end
end
