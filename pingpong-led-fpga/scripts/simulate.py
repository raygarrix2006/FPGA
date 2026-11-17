#!/usr/bin/env python3
"""Run the handed-over testbench with GHDL; require its explicit success marker."""
from pathlib import Path
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
    sources = [repo / "src" / "btn_cond.vhd", repo / "src" / "pingpong.vhd",
               repo / "sim" / "tb_pingpong.vhd"]
    commands = [[ghdl, "--version"],
                [ghdl, "-a", "--std=93"] + [str(p) for p in sources],
                [ghdl, "-e", "--std=93", "tb_pingpong"],
                [ghdl, "-r", "--std=93", "tb_pingpong", "--assert-level=error",
                 "--stop-time=5ms", "--vcd=tb_pingpong.vcd"]]
    with (out / "simulation.log").open("w", encoding="utf-8") as log:
        for command in commands:
            log.write("$ " + " ".join(command) + "\n")
            log.flush()
            try:
                result = subprocess.run(command, cwd=out, stdout=subprocess.PIPE,
                                        stderr=subprocess.STDOUT, text=True,
                                        encoding="utf-8", errors="replace", timeout=120)
            except subprocess.TimeoutExpired:
                log.write("FAIL: wall-clock timeout\n")
                return 1
            log.write(result.stdout)
            print(result.stdout, end="")
            if result.returncode:
                return result.returncode
        if "ALL TESTS PASSED" not in result.stdout:
            log.write("FAIL: success marker not found\n")
            print("FAIL: success marker not found", file=sys.stderr)
            return 1
    return 0

if __name__ == "__main__":
    sys.exit(main())
