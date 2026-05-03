class VirusTotalScanJob < ApplicationJob
  queue_as :virus_total

  def perform(attachment_id)
    attachment = Attachment.find_by(id: attachment_id)
    return unless attachment

    result = VirusTotalScanner.scan(attachment)
    if result == :pending
      VirusTotalScanJob.set(wait: 2.minutes).perform_later(attachment.id)
    elsif result.is_a?(Hash) && result[:status] == :pending
      VirusTotalScanJob.set(wait: result[:wait].seconds).perform_later(attachment.id)
    end
  end
end
