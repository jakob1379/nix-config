final: prev:

{
  tana = prev.tana.overrideAttrs (old: {
    postInstall = (old.postInstall or "") + ''
              main="$out/lib/tana/resources/app/build/main.js"

              unsupported_branch='else Ox=()=>(console.warn("System audio capture not supported on this platform"),"denied"),Dx=async()=>(console.warn("System audio capture not supported on this platform"),"denied"),Nx=async()=>{throw console.warn("System audio capture not supported on this platform"),new Error("System audio capture not supported on this platform")};var HM=require("electron")'

              pipewire_branch=$(cat <<'EOF'
      else {
        let childProcess = require("child_process");
        let stream = require("stream");

        Ox = () => "authorized";
        Dx = async () => "authorized";
        Nx = async () => {
          let output = new stream.PassThrough();
          let recorder = childProcess.spawn(
            "${final.pipewire}/bin/pw-record",
            ["--raw", "--format", "f32", "--rate", "48000", "--channels", "2", "-"],
            { stdio: ["ignore", "pipe", "pipe"] }
          );

          recorder.stdout.pipe(output);
          recorder.stderr.on("data", data =>
            console.warn("pw-record:", data.toString().trim())
          );
          recorder.on("error", error => output.emit("error", error));
          recorder.on("close", (code, signal) => {
            if (code && code !== 0) {
              output.emit(
                "error",
                new Error("pw-record exited " + code + (signal ? " signal " + signal : ""))
              );
            } else {
              output.end();
            }
          });
          output.on("close", () => {
            if (!recorder.killed) recorder.kill("SIGTERM");
          });

          return output;
        };
      }
      var HM = require("electron")
      EOF
      )

              grep -Fq -- "$unsupported_branch" "$main" || {
                echo "Tana system-audio patch target not found" >&2
                exit 1
              }

              substituteInPlace "$main" \
                --replace-fail "$unsupported_branch" "$pipewire_branch"

              loopback_count="$(grep -oF 'audio:"loopback"' "$main" | wc -l | tr -d ' ')"
              if [ "$loopback_count" -ne 2 ]; then
                echo "Expected 2 Tana loopback targets, found $loopback_count" >&2
                exit 1
              fi

              substituteInPlace "$main" \
                --replace-fail 'audio:"loopback"' 'audio:n.frame'
    '';
  });
}
