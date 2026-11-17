#!/usr/bin/env python3
"""Run both self-checking benches, stopping on assertion errors or missing markers."""
from pathlib import Path
import re
import shutil
import subprocess
import sys

def main():
    repo = Path(__file__).resolve().parent.parent
    ghdl = shutil.which("ghdl")
    if not ghdl:
        print("GHDL not found. Install GHDL and put it on PATH.", file=sys.stderr)
        return 2
    out = repo / "build" / "ghdl"
    out.mkdir(parents=True, exist_ok=True)
    options = ["--std=93", "--mb-comments", "--workdir=build/ghdl"]
    sources = ["src/btn_cond.vhd", "src/pingpong.vhd", "sim/tb_pingpong.vhd", "sim/tb_btn_cond.vhd"]
    commands = [( [ghdl, "--version"], None),
                ([ghdl, "-a"] + options + sources, None)]
    for bench, marker in [("tb_pingpong", "ALL TESTS PASSED"), ("tb_btn_cond", "ALL BUTTON TESTS PASSED")]:
        commands += [([ghdl, "-e"] + options + [bench], None),
                     ([ghdl, "-r"] + options + [bench, "--assert-level=error", "--stop-time=5ms",
                      "--vcd=build/ghdl/" + bench + ".vcd"], marker)]
    with (out / "simulation.log").open("w", encoding="utf-8") as log:
        for command, marker in commands:
            log.write("$ ghdl " + " ".join(command[1:]) + "\n")
            log.flush()
            try:
                result = subprocess.run(command, cwd=repo, stdout=subprocess.PIPE,
                    stderr=subprocess.STDOUT, text=True, encoding="utf-8", errors="replace", timeout=120)
            except subprocess.TimeoutExpired:
                log.write("FAIL: wall-clock timeout\n")
                return 1
            log.write(result.stdout)
            print(result.stdout, end="")
            if result.returncode:
                return result.returncode
            if re.search(r"assertion (?:error|failure)|^Failure:", result.stdout, re.I | re.M):
                return 1
            if marker and marker not in result.stdout:
                log.write("FAIL: success marker not found\n")
                return 1
    return 0

if __name__ == "__main__":
    sys.exit(main())
