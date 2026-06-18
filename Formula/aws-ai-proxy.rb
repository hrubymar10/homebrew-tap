class AwsAiProxy < Formula
  desc "Host-side loopback AWS credential proxy for AI docker sandboxes"
  homepage "https://github.com/hrubymar10/aws-ai-proxy"
  url "https://github.com/hrubymar10/aws-ai-proxy/archive/refs/tags/v0.0.2.tar.gz"
  sha256 "496dd4a99a422573b6eb875c24de62291580ab0ad9391614d924a8af92836d22"
  license "MIT"
  head "https://github.com/hrubymar10/aws-ai-proxy.git", branch: "master"

  depends_on "go" => :build

  def install
    ldflags = "-s -w -X main.version=#{version}"
    system "go", "build", *std_go_args(ldflags: ldflags), "./cmd/aws-ai-proxy"
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
