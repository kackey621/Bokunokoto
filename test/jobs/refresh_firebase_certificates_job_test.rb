require "test_helper"

class RefreshFirebaseCertificatesJobTest < ActiveJob::TestCase
  test "fetches certificates and re-enqueues itself after REFRESH_INTERVAL" do
    FirebaseIdToken::Certificates.stub(:request, nil) do
      assert_enqueued_jobs 1, only: RefreshFirebaseCertificatesJob do
        RefreshFirebaseCertificatesJob.perform_now
      end

      next_job = enqueued_jobs.last
      scheduled_at = next_job["scheduled_at"]
      expected_at = RefreshFirebaseCertificatesJob::REFRESH_INTERVAL.from_now.to_f
      assert_in_delta expected_at, scheduled_at, 10.0
    end
  end

  test "re-enqueues after RETRY_INTERVAL when certificate fetch fails" do
    FirebaseIdToken::Certificates.stub(:request, -> { raise "network error" }) do
      assert_enqueued_jobs 1, only: RefreshFirebaseCertificatesJob do
        RefreshFirebaseCertificatesJob.perform_now
      end

      next_job = enqueued_jobs.last
      scheduled_at = next_job["scheduled_at"]
      expected_at = RefreshFirebaseCertificatesJob::RETRY_INTERVAL.from_now.to_f
      assert_in_delta expected_at, scheduled_at, 10.0
    end
  end
end
