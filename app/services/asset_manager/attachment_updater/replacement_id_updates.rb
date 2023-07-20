class AssetManager::AttachmentUpdater::ReplacementIdUpdates
  def self.call(attachment_data)
    return [] unless attachment_data.replaced?

    replacement = attachment_data.replaced_by

    Enumerator.new do |enum|
      enum.yield(
        AssetManager::AttachmentUpdater::Update.new(
          nil,
          attachment_data,
          attachment_data.file,
          replacement_legacy_url_path: replacement.file.asset_manager_path,
        ),
      )

      if attachment_data.pdf?
        replacement_legacy_url_path = if replacement.pdf?
                                        replacement.file.thumbnail.asset_manager_path
                                      else
                                        replacement.file.asset_manager_path
                                      end
        enum.yield(
          AssetManager::AttachmentUpdater::Update.new(
            nil,
            attachment_data,
            attachment_data.file.thumbnail,
            replacement_legacy_url_path:,
          ),
        )
      end
    end
  end
end
