class CreateAssetRelationshipWorker < WorkerBase
  def perform(assetable_type, start_id, end_id)
    logger.info("CreateAssetRelationshipWorker start!")

    assetable_type = assetable_type.constantize
    assetables = assetable_type.where(id: start_id..end_id, use_non_legacy_endpoints: false)
    logger.info "Number of #{assetable_type} found: #{assetables.count}"
    logger.info "Creating Asset for records from #{start_id} to #{end_id}"

    count = 0
    asset_counter = 0

    assetables.each do |assetable|
      assetable.use_non_legacy_endpoints = true
      assetable.save!

      all_variants = assetable.bitmap? ? assetable.file.versions.keys.push(:original) : [Asset.variants[:original].to_sym]
      all_variants.each do |variant|
        asset_counter += 1 if save_asset(assetable, assetable_type, variant)
      end

      count += 1
    end

    logger.info("Created assets for #{count} assetable")
    logger.info("Created asset counter #{asset_counter}")
    logger.info("CreateAssetRelationshipWorker finish!")

    { count:, asset_counter: }
  end

private

  def asset_manager
    Services.asset_manager
  end

  def save_asset(assetable, assetable_type, variant)
    path = variant == :original ? assetable.file.path : assetable.file.versions[variant].path
    asset_info = get_asset_data(path)
    save_asset_id_to_assets(assetable.id, assetable_type, Asset.variants[variant], asset_info[:asset_manager_id], asset_info[:filename])
  rescue GdsApi::HTTPNotFound
    logger.warn "#{assetable_type} of id##{assetable.id} - could not find asset variant :#{variant} at path #{path}"

    false
  end

  def get_asset_data(legacy_url_path)
    asset_info = {}
    path = legacy_url_path.sub(/^\//, "")
    response_hash = asset_manager.whitehall_asset(path).to_hash
    asset_info[:asset_manager_id] = get_asset_id(response_hash)
    asset_info[:filename] = get_filename(response_hash)

    asset_info
  end

  def get_filename(response)
    response["name"]
  end

  def get_asset_id(response)
    url = response["id"]
    url[/\/assets\/(.*)/, 1]
  end

  def save_asset_id_to_assets(assetable_id, assetable_type, variant, asset_manager_id, filename)
    asset = Asset.new(asset_manager_id:, assetable_type:, assetable_id:, variant:, filename:)
    asset.save!
  end
end