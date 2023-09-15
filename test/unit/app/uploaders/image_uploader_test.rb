require "test_helper"

class ImageUploaderTest < ActiveSupport::TestCase
  include ActionDispatch::TestProcess
  extend Minitest::Spec::DSL

  setup do
    ImageUploader.enable_processing = true
  end

  teardown do
    ImageUploader.enable_processing = false
  end

  test "uses the asset manager and quarantined file storage engine" do
    assert_equal Whitehall::AssetManagerStorage, ImageUploader.storage
  end

  test "should only allow JPG, GIF, PNG or SVG images" do
    uploader = ImageUploader.new
    assert_equal %w[jpg jpeg gif png svg], uploader.extension_allowlist
  end

  describe "use_non_legacy_endpoints is false" do
    setup do
      image_data = FactoryBot.create(:image_data)
      @uploader = ImageUploader.new(image_data, "mounted-as")
    end

    test "should send correctly resized versions of a bitmap image to asset manager" do
      Services.asset_manager.stubs(:create_whitehall_asset)
      Services.asset_manager.expects(:create_whitehall_asset).with do |value|
        image_path = value[:file].path
        assert_image_has_correct_size image_path
      end

      Sidekiq::Testing.inline! do
        @uploader.store!(upload_fixture("minister-of-funk.960x640.jpg", "image/jpg"))
      end
    end

    test "should store uploads in a directory that persists across deploys" do
      assert_match %r{^system}, @uploader.store_dir
    end

    test "should store all the versions of a bitmap image in asset manager" do
      Services.asset_manager.stubs(:create_whitehall_asset)
      Services.asset_manager.expects(:create_whitehall_asset).with(file_and_legacy_url_path_matching(/minister-of-funk.960x640.jpg/))
      Services.asset_manager.expects(:create_whitehall_asset).with(file_and_legacy_url_path_matching(/s960_minister-of-funk.960x640.jpg/))
      Services.asset_manager.expects(:create_whitehall_asset).with(file_and_legacy_url_path_matching(/s712_minister-of-funk.960x640.jpg/))
      Services.asset_manager.expects(:create_whitehall_asset).with(file_and_legacy_url_path_matching(/s630_minister-of-funk.960x640.jpg/))
      Services.asset_manager.expects(:create_whitehall_asset).with(file_and_legacy_url_path_matching(/s465_minister-of-funk.960x640.jpg/))
      Services.asset_manager.expects(:create_whitehall_asset).with(file_and_legacy_url_path_matching(/s300_minister-of-funk.960x640.jpg/))
      Services.asset_manager.expects(:create_whitehall_asset).with(file_and_legacy_url_path_matching(/s216_minister-of-funk.960x640.jpg/))

      Sidekiq::Testing.inline! do
        @uploader.store!(upload_fixture("minister-of-funk.960x640.jpg", "image/jpg"))
      end
    end

    test "should store the original version only of a svg image in asset manager" do
      Services.asset_manager.stubs(:create_whitehall_asset)
      Services.asset_manager.expects(:create_whitehall_asset).with(file_and_legacy_url_path_matching(/test-svg.svg/))

      Sidekiq::Testing.inline! do
        @uploader.store!(upload_fixture("images/test-svg.svg", "image/svg+xml"))
      end
    end
  end

  describe "use_non_legacy_endpoints is true" do
    test "should send correctly resized versions of a bitmap image to asset manager" do
      create(:image_data, use_non_legacy_endpoints: true)

      Services.asset_manager.expects(:create_asset).with { |value|
        image_path = value[:file].path
        assert_image_has_correct_size image_path
      }.times(7).returns("id" => "http://asset-manager/assets/some-id", "name" => "minister-of-funk.960x640.jpg")

      AssetManagerCreateAssetWorker.drain
    end

    test "should store uploads in a directory that persists across deploys" do
      image_data = build(:image_data, use_non_legacy_endpoints: true)
      @uploader = ImageUploader.new(image_data, "mounted-as")

      assert_match %r{^system}, @uploader.store_dir
    end

    test "should store all the versions of a bitmap image in asset manager" do
      expected_file_names = %w[minister-of-funk.960x640.jpg s960_minister-of-funk.960x640.jpg s712_minister-of-funk.960x640.jpg s630_minister-of-funk.960x640.jpg s465_minister-of-funk.960x640.jpg s300_minister-of-funk.960x640.jpg s216_minister-of-funk.960x640.jpg]
      create(:image_data, use_non_legacy_endpoints: true)

      Services.asset_manager.stubs(:create_asset).with { |params|
        file = params[:file].path.split("/").last
        assert expected_file_names.include?(file)
      }.times(7).returns("id" => "http://asset-manager/assets/some-id", "name" => "minister-of-funk.960x640.jpg")

      AssetManagerCreateAssetWorker.drain
    end

    test "should store only the original version of a svg image in asset manager" do
      svg = upload_fixture("images/test-svg.svg", "image/svg+xml")
      ImageData.create!(file: svg, use_non_legacy_endpoints: true)

      Services.asset_manager.stubs(:create_asset).with { |params|
        assert params[:file].path.split("/").last == "test-svg.svg"
      }.once.returns("id" => "http://asset-manager/assets/some-id", "name" => "test-svg.svg")

      AssetManagerCreateAssetWorker.drain
    end
  end

private

  def assert_image_has_correct_size(asset_path)
    filename = File.basename(asset_path)

    expected_sizes = {
      "minister-of-funk.960x640.jpg" => [960, 640],
      "s960_minister-of-funk.960x640.jpg" => [960, 640],
      "s712_minister-of-funk.960x640.jpg" => [712, 480],
      "s630_minister-of-funk.960x640.jpg" => [630, 420],
      "s465_minister-of-funk.960x640.jpg" => [465, 310],
      "s300_minister-of-funk.960x640.jpg" => [300, 195],
      "s216_minister-of-funk.960x640.jpg" => [216, 140],
    }

    width, height = expected_sizes[filename]
    image = MiniMagick::Image.open(asset_path)
    assert_equal width, image[:width], "#{expected_sizes[filename].join('x')} image version should be #{width}px wide, but was #{image[:width]}"
    assert_equal height, image[:height], "#{expected_sizes[filename].join('x')} image version should be #{height}px high, but was #{image[:height]}"
  end
end
