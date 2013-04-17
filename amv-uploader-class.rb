require 'aws-sdk'
require 'logger'
require 'json'
require 'tempfile'

require_relative 'config'

# Base class for renderers
class AmvRendererBase
  
  # Takes the name of the source file
  def initialize(src)
    @src = src
    @log = Logger.new(STDOUT)
  end

  # Setup logger
  def logger(log_obj)
    @log = log_obj
  end

  # Ready to run?
  def ready
    false
  end

  # Get MIME Type
  def type
    'application/octet-string'
  end
  
  # Renders a file into another form
  # Returns encoded file
  def render
    return nil
  end

  # Renders a thumbnail
  def thumbnail
    return nil
  end
end

# MPEG4 Renderer thru ffmpeg
class MP4Renderer < AmvRendererBase

  def ready
    system "which #{$Settings[:path_to_handbrake]} >/dev/null 2>&1"
  end

  def render
    tempfile_datestamp = Time.now.strftime("%Y-%m-%d-%H-%m-%s")
    target_file = Tempfile.new(["amv-process--#{tempfile_datestamp}", ".mp4"])
    @log.debug("Exporting to #{target_file.path}")
    
    cmd = "#{$Settings[:path_to_handbrake]} -i \"#{@src}\" -o \"#{target_file.path}\" -e x264 -X 480 -q 30 -B 160 --optimize --verbose 0 >/dev/null 2>&1"
    
    result = system cmd
    @log.debug(result)

    unless $Settings[:path_to_faststart].nil?
      @log.debug("Running qtfaststart")
      cmd = "#{$Settings[:path_to_faststart]} \"#{target_file.path}\" \"#{target_file.path}\" >/dev/null 2>&1"
      result = system cmd
      @log.debug(result)
    end

    return target_file
  end

  def type
    'video/mp4'
  end

  def thumbnail(src)
    length = 30
    dimensions = "320x240"

    unless $Settings[:path_to_ffprobe].nil?
      cmd = "#{$Settings[:path_to_ffprobe]} -v quiet -print_format json -show_streams \"#{src.path}\""
      json_result = `#{cmd}`
      video_data = JSON.load(json_result)
      length = video_data['streams'][0]['duration'].to_f
      dimensions = "#{video_data['streams'][0]['width']}x#{video_data['streams'][0]['height']}"
    end

    mark = (length / 2).to_i

    unless $Settings[:path_to_ffmpeg].nil?
      target_file = Tempfile.new([File.basename(src.path), '.jpg'])
      cmd = "#{$Settings[:path_to_ffmpeg]} -i \"#{src.path}\" -vframes 1 -an -s #{dimensions} -ss #{mark} -y #{target_file.path} -loglevel 0"
      result = system cmd
      return target_file
    end
    nil
  end
end

# Base class for uploaders
class AmvUploaderBase
  
  # Takes the uploader params: username, password, whatever
  def initialize(params)
    @params = params
    @log = Logger.new(STDOUT)
  end

  # Good to go?
  def ready
    false
  end

  # Setup logger
  def logger(log_obj)
    @log = log_obj
  end
  
  # Put a file
  def put(src)
    false
  end

  # Get URL
  def get_url(obj)
    obj.to_s
  end
end

# Uploader to AWS
class AwsUploader < AmvUploaderBase

  alias_method :initialize_super, :initialize

  def initialize(params)
    initialize_super(params)
    AWS.config(
      :s3_endpoint        => @params[:endpoint],
      :access_key_id      => @params[:key],
      :secret_access_key  => @params[:secret]
    )
  end

  def ready
    true
  end

  def put(src, type, filename = nil)
    if filename.nil?
      filename = File.basename(src.path)
    end
    @log.debug("Uploading #{src} to AWS as #{filename}")

    s3 = AWS::S3.new
    bucket = s3.buckets[@params[:bucket]]  
    obj = bucket.objects.create(filename, {
      :data => src,
      :acl => :public_read,
      :content_type => type
    })
    @log.debug(obj.key)
    obj
  end

  def get_url(obj)
    obj.public_url
  end
end

# Uploader container
class AmvUploader

  attr_accessor :src, :dst, :remote, :thumbnail
  
  # Sets up src and other stuff
  def initialize(params)
    @errors = []
    @src = params[:src]
    @log = Logger.new(STDOUT)
    @type = nil
  end

  # Set logger
  def logger(log_obj)
    @log = log_obj
  end
  
  # Convert and upload
  def process(renderClass, uploadClass, uploadParams)
    @dst = render(renderClass)
    if @dst != false
      @remote = upload(uploadClass, uploadParams)
      return @remote
    end
    false
  end
  
  # Convert
  def render(className)
    cls = Object.const_get(className)
    if cls < AmvRendererBase
      @renderer = cls.new(@src)
      unless @renderer.ready == true
        @log.fatal("Renderer has not been configured correctly.")
        return false
      end

      @renderer.logger(@log)
      @type = @renderer.type
      output = @renderer.render
      @thumbnail = @renderer.thumbnail(output)
      return output
    end
    false
  end
  
  # Upload
  def upload(className, params)
    if @dst == false
      return false
    end
    
    cls = Object.const_get(className)
    if cls < AmvUploaderBase
      @uploader = cls.new(params)
      unless @uploader.ready == true
        @log.fatal("Uploader has not been configured correctly.")
        return false
      end

      @uploader.logger(@log)
      obj = @uploader.put(@dst, @type)
      video_url = @uploader.get_url(obj)
      @log.info("Uploaded video to #{video_url}")

      unless @thumbnail.nil?
        thumbnail_obj = @uploader.put(@thumbnail, 'image/jpeg', "#{obj.key}.jpg")
        thumbnail_url = @uploader.get_url(thumbnail_obj)
        @log.info("Uploaded thumbnail to #{thumbnail_url}")
      end

      return video_url
    end
    false
  end
  
  def errors
    @errors
  end
  
end
