ENV["RAILS_ENV"] = "test"

require File.expand_path('../../../../config/environment', __dir__)
require 'minitest/autorun'
require 'mocha/setup'
require 'rails/test_help'
require_relative '../../../../lib/sync_checker/checks/unpublished_check'
require_relative '../../../../lib/whitehall/govspeak_renderer'

module SyncChecker::Checks
  class UnpublishedCheckTest < Minitest::Test
    def setup
      Whitehall::GovspeakRenderer.stubs(:new).returns(@stub_renderer = stub)
    end

    def test_returns_no_errors_if_the_document_has_no_unpublishing
      document = stub(
        published_edition: stub(unpublishing: nil),
        pre_publication_edition: stub(unpublishing: nil)
      )
      assert_equal [], UnpublishedCheck.new(document).call(stub)
    end

    def test_returns_no_errors_if_the_document_is_withdrawn_and_has_the_correct_notice
      document = stub(
        published_edition: stub(
          updated_at: Time.gm(2016, 8, 10, 1, 2, 3, 456)
        ),
        pre_publication_edition: nil
      )
      document.published_edition.stubs(unpublishing: stub(
        unpublishing_reason_id: 5,
        explanation: "Some explainings",
        edition: document.published_edition
      ))
      @stub_renderer.stubs(:govspeak_to_html).returns("<p>Some explainings</p>")

      response = stub(
        body: {
          withdrawn_notice: {
            explanation: "<p>Some explainings</p>",
            withdrawn_at: "2016-08-10T01:02:03.000+00:00"
          }
        }.to_json
      )

      assert_equal [], UnpublishedCheck.new(document).call(response)
    end

    def test_returns_an_error_if_the_document_is_withdrawn_and_has_the_wrong_notice
      document = stub(
        published_edition: stub(
          updated_at: Time.gm(2016, 8, 10, 1, 2, 3, 456)
        ),
        pre_publication_edition: nil
      )
      document.published_edition.stubs(unpublishing: stub(
        unpublishing_reason_id: 5,
        explanation: "Some explainings",
        edition: document.published_edition
      ))
      @stub_renderer.stubs(:govspeak_to_html).returns("<p>Some explainings</p>")

      response = stub(
        body: {
          withdrawn_notice: {
            explanation: "<p>Some other explainings</p>",
            withdrawn_at: "2016-08-10T01:02:03.000+00:00"
          }
        }.to_json
      )
      expected_error = "expected withdrawn notice: '<p>Some explainings</p>' but got '<p>Some other explainings</p>'"

      assert_equal [expected_error],
        UnpublishedCheck.new(document).call(response)
    end

    def test_returns_an_error_if_the_document_is_withdrawn_and_has_no_notice
      document = stub(
        published_edition: stub(
          updated_at: Time.gm(2016, 8, 10, 1, 2, 3, 456)
        ),
        pre_publication_edition: nil
      )
      document.published_edition.stubs(unpublishing: stub(
        unpublishing_reason_id: 5,
        explanation: "Some explainings",
        edition: document.published_edition
      ))
      @stub_renderer.stubs(:govspeak_to_html).returns("<p>Some explainings</p>")

      response = stub(
        body: {
          withdrawn_notice: {
            withdrawn_at: "2016-08-10T01:02:03.000+00:00"
          }
        }.to_json
      )
      expected_error = "expected withdrawn notice: '<p>Some explainings</p>' but got ''"

      assert_equal [expected_error],
        UnpublishedCheck.new(document).call(response)
    end

    def test_returns_no_error_if_the_document_is_withdrawn_and_has_a_withdrawn_date_expressed_with_an_offset
      document = stub(
        published_edition: stub(
          updated_at: Time.gm(2016, 8, 10, 1, 2, 3, 456)
        ),
        pre_publication_edition: nil
      )
      document.published_edition.stubs(unpublishing: stub(
        unpublishing_reason_id: 5,
        explanation: "Explanation",
        edition: document.published_edition
      ))

      @stub_renderer.stubs(:govspeak_to_html).returns("<p>Explanation</p>")

      response = stub(
        body: {
          withdrawn_notice: {
            explanation: "<p>Explanation</p>",
            withdrawn_at: "2016-08-10T02:02:03.000+01:00"
          }
        }.to_json
      )

      assert_equal [],
        UnpublishedCheck.new(document).call(response)
    end

    def test_returns_an_error_if_the_document_is_withdrawn_and_has_the_wrong_date
      document = stub(
        published_edition: stub(
          updated_at: Time.gm(2016, 8, 10, 1, 2, 3, 456)
        ),
        pre_publication_edition: nil
      )
      document.published_edition.stubs(unpublishing: stub(
        unpublishing_reason_id: 5,
        explanation: "Some explainings",
        edition: document.published_edition
      ))

      @stub_renderer.stubs(:govspeak_to_html).returns("<p>Some explainings</p>")

      response = stub(
        body: {
          withdrawn_notice: {
            explanation: "<p>Some explainings</p>",
            withdrawn_at: "2016-08-10T02:02:03.000+00:00"
          }
        }.to_json
      )
      expected_error = "expected withdrawn at '2016-08-10 01:02:03 UTC' but got '2016-08-10 02:02:03 UTC'"

      assert_equal [expected_error],
        UnpublishedCheck.new(document).call(response)
    end

    def test_returns_an_error_if_the_document_is_withdrawn_and_has_blank_date
      document = stub(
        published_edition: stub(
          updated_at: Time.gm(2016, 8, 10, 1, 2, 3, 456)
        ),
        pre_publication_edition: nil
      )
      document.published_edition.stubs(unpublishing: stub(
        unpublishing_reason_id: 5,
        explanation: "Some explainings",
        edition: document.published_edition
      ))

      @stub_renderer.stubs(:govspeak_to_html).returns("<p>Some explainings</p>")

      response = stub(
        body: {
          withdrawn_notice: {
            explanation: "<p>Some explainings</p>",
            withdrawn_at: ""
          }
        }.to_json
      )
      expected_error = "expected withdrawn at but was missing"

      assert_equal [expected_error],
        UnpublishedCheck.new(document).call(response)
    end

    def test_returns_no_error_if_the_document_is_unpublished_in_error_and_has_gone
      document = stub(
        published_edition: nil,
        pre_publication_edition: stub(
          unpublishing: stub(
            unpublishing_reason_id: 1,
            explanation: "Some explainings",
            alternative_url: "https://gov.uk/booyah",
            "redirect?" => false
          )
        )
      )
      @stub_renderer.stubs(:govspeak_to_html).returns("<p>Some explainings</p>")

      response = stub(
        body: {
          schema_name: "gone",
          withdrawn_notice: {},
          details: {
            explanation: "<p>Some explainings</p>",
            alternative_path: "/booyah"
          }
        }.to_json
      )

      assert_equal [],
        UnpublishedCheck.new(document).call(response)
    end

    def test_returns_an_error_if_the_document_is_unpublished_in_error_with_no_redirect_and_is_not_gone
      document = stub(
        published_edition: nil,
        pre_publication_edition: stub(
          unpublishing: stub(
            unpublishing_reason_id: 1,
            explanation: "Some explainings",
            alternative_url: "https://gov.uk/booyah",
            "redirect?" => false
          )
        )
      )
      @stub_renderer.stubs(:govspeak_to_html).returns("<p>Some explainings</p>")

      response = stub(
        body: {
          schema_name: "redirect",
          withdrawn_notice: {},
          details: {
            explanation: "<p>Some explainings</p>",
            alternative_path: "/booyah"
          }
        }.to_json
      )

      assert_equal ["should be gone"],
        UnpublishedCheck.new(document).call(response)
    end

    def test_returns_an_error_if_the_document_is_unpublished_in_error_with_no_redirect_alt_path_incorrect
      document = stub(
        published_edition: nil,
        pre_publication_edition: stub(
          unpublishing: stub(
            unpublishing_reason_id: 1,
            explanation: "Some explainings",
            alternative_url: "https://gov.uk/booyah",
            "redirect?" => false
          )
        )
      )
      @stub_renderer.stubs(:govspeak_to_html).returns("<p>Some explainings</p>")

      response = stub(
        body: {
          schema_name: "gone",
          withdrawn_notice: {},
          details: {
            explanation: "<p>Some explainings</p>",
            alternative_path: "/booyahkasha"
          }
        }.to_json
      )

      assert_equal ["expected gone alternative_path: '/booyah' but got '/booyahkasha'"],
        UnpublishedCheck.new(document).call(response)
    end

    def test_returns_an_error_if_the_document_is_unpublished_in_error_with_no_redirect_explanation_incorrect
      document = stub(
        published_edition: nil,
        pre_publication_edition: stub(
          unpublishing: stub(
            unpublishing_reason_id: 1,
            explanation: "Some explainings",
            alternative_url: "https://gov.uk/booyah",
            "redirect?" => false
          )
        )
      )
      @stub_renderer.stubs(:govspeak_to_html).returns("<p>Some explainings</p>")

      response = stub(
        body: {
          schema_name: "gone",
          withdrawn_notice: {},
          details: {
            explanation: "<p>Some other explainings</p>",
            alternative_path: "/booyah"
          }
        }.to_json
      )
      expected_error = "expected gone explanation: '<p>Some explainings</p>' but got '<p>Some other explainings</p>'"
      assert_equal [expected_error],
        UnpublishedCheck.new(document).call(response)
    end

    def test_returns_no_error_if_the_document_is_unpublished_in_error_with_redirect_and_redirect_is_returned
      document = stub(
        published_edition: nil,
        pre_publication_edition: stub(
          unpublishing: stub(
            unpublishing_reason_id: 1,
            "redirect?" => true
          )
        )
      )

      response = stub(
        body: {
          schema_name: "redirect",
        }.to_json
      )

      assert_equal [], UnpublishedCheck.new(document).call(response)
    end

    def test_returns_an_error_if_the_document_is_unpublished_in_error_with_redirect_but_no_redirect_is_returned
      document = stub(
        published_edition: nil,
        pre_publication_edition: stub(
          unpublishing: stub(
            unpublishing_reason_id: 1,
            "redirect?" => true
          )
        )
      )

      response = stub(
        body: {
          schema_name: "gone",
        }.to_json
      )

      expected_error = "should be redirect"
      assert_equal [expected_error],
        UnpublishedCheck.new(document).call(response)
    end

    def test_returns_no_error_if_the_document_is_unpublished_consolidated_and_redirect_is_returned
      document = stub(
        published_edition: nil,
        pre_publication_edition: stub(
          unpublishing: stub(
            unpublishing_reason_id: 4,
          )
        )
      )

      response = stub(
        body: {
          schema_name: "redirect",
        }.to_json
      )

      assert_equal [], UnpublishedCheck.new(document).call(response)
    end

    def test_returns_an_error_if_the_document_is_unpublished_consolidated_but_no_redirect_is_returned
      document = stub(
        published_edition: nil,
        pre_publication_edition: stub(
          unpublishing: stub(
            unpublishing_reason_id: 4,
          )
        )
      )

      response = stub(
        body: {
          schema_name: "gone",
        }.to_json
      )

      expected_error = "should be redirect"
      assert_equal [expected_error],
        UnpublishedCheck.new(document).call(response)
    end
  end
end
