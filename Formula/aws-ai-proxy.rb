class AwsAiProxy < Formula
  desc "Host-side loopback AWS credential proxy for AI docker sandboxes"
  homepage "https://github.com/hrubymar10/aws-ai-proxy"
  url "https://github.com/hrubymar10/aws-ai-proxy/archive/refs/tags/v0.0.3.tar.gz"
  sha256 "df0c355484274242eb89acdb7cb17ef563a2c4f34411c7a99ff32c86d1904018"
  license "MIT"
  head "https://github.com/hrubymar10/aws-ai-proxy.git", branch: "master"

  depends_on "go" => :build

  def install
    ldflags = "-s -w -X main.version=#{version}"
    system "go", "build", *std_go_args(ldflags: ldflags), "./cmd/aws-ai-proxy"
  end

  def caveats
    <<~EOS
      Configuration lives at:
        ~/.aws-ai-proxy/config
      It is auto-created with defaults on first run. Set AWS_AI_PROXY_PROFILES
      there (or in your environment) to allowlist profiles. Environment
      variables override the file per setting.

      OS notifications on successful credential requests are ENABLED by default.
      To disable, set in that file (or your environment):
        AWS_AI_PROXY_NOTIFICATIONS_ENABLED=false
      Repeat notifications for the same client+profile are throttled via
      AWS_AI_PROXY_NOTIFICATION_DEDUP_WINDOW (default 5m; 0 notifies every time).
    EOS
  end

  service do
    run [opt_bin/"aws-ai-proxy", "serve"]
    keep_alive true
    working_dir var
    log_path var/"log/aws-ai-proxy.log"
    error_log_path var/"log/aws-ai-proxy.log"
  end

  test do
    port = free_port
    pid = fork do
      ENV["HOME"] = testpath.to_s
      ENV["AWS_AI_PROXY_PROFILES"] = "dummy"
      ENV["AWS_AI_PROXY_BIND"] = "127.0.0.1:#{port}"
      exec bin/"aws-ai-proxy", "serve"
    end
    sleep 2
    output = shell_output("curl -sf http://127.0.0.1:#{port}/health")
    assert_match "ok", output
  ensure
    Process.kill("TERM", pid)
    Process.wait(pid)
  end
end
