require "securerandom"

class AttachmentCreator
  def self.attach(attachable:, user:, files:)
    Array(files).compact.select { |f| f.respond_to?(:original_filename) }.each do |file|
      content_type = file.content_type.presence || "application/octet-stream"
      attachment = Attachment.new(
        attachable: attachable,
        user: user,
        filename: file.original_filename,
        content_type: content_type,
        byte_size: file.size,
        is_video: content_type.start_with?("video/")
      )
      attach_file(attachment, file, attachable, user, content_type)
      if attachment.save
        VirusTotalScanJob.perform_later(attachment.id) if attachment.vt_scannable?
      end
    end
  end

  def self.attach_file(attachment, file, attachable, user, content_type)
    if attachable.is_a?(PrivateMessage)
      io = file.respond_to?(:tempfile) ? file.tempfile : file.to_io
      io.rewind if io.respond_to?(:rewind)
      attachment.file.attach(
        io: io,
        filename: file.original_filename,
        content_type: content_type,
        key: dm_file_key(file.original_filename, attachable, user)
      )
    else
      attachment.file.attach(file)
    end
  end

  def self.dm_file_key(filename, message, user)
    safe_filename = filename.to_s.gsub(/[^a-zA-Z0-9._-]/, "_")
    date_path = Time.current.utc.strftime("%Y/%m/%d")
    "dmfile/#{date_path}/user-#{user.id}/message-#{message.id}/#{SecureRandom.uuid}-#{safe_filename}"
  end
end
