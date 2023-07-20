class AssetManager::AttachmentUpdater::RedirectUrlUpdates
  def self.call(attachment_data)
    redirect_url = nil
    if attachment_data.unpublished? && attachment_data.present_at_unpublish?
      redirect_url = attachment_data.unpublished_edition.unpublishing.document_url
    end

    Enumerator.new do |enum|
      enum.yield AssetManager::AttachmentUpdater::Update.new(
        nil, attachment_data, attachment_data.file, redirect_url:
      )

      if attachment_data.pdf?
        enum.yield AssetManager::AttachmentUpdater::Update.new(
          nil, attachment_data, attachment_data.file.thumbnail, redirect_url:
        )
      end
    end
  end
end
