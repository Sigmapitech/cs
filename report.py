"""
usage: report.py [banana-vera-bin] [ruleset] [path] [...]

"""

from typing import List, Optional

import re
import os
import subprocess
import shlex
import sys
import time


IGNORE_PATTERNS: List[str] = [
    r".*/[.]build/.*",
    r".*/[.]cache/.*",
    r".*/[.]direnv/.*",
    r".*/[.]git/.*",
    r".*/[.]idea/.*",
    r".*/[.]vscode/.*",
    r".*/bonus/.*",
    r".*/result/.*",
]


def find_files(search_dir: str, ignore_tests: bool = False) -> List[str]:
    find_proc = subprocess.run(
        shlex.split(f"find {search_dir} -type f"),
        capture_output=True, text=True
    )

    if ignore_tests:
        IGNORE_PATTERNS.append(r".*/tests/.*")

    return [
        filename for filename in find_proc.stdout.splitlines()
        if all(
            re.match(pattern, filename) is None
            for pattern in IGNORE_PATTERNS
        )
    ]


def run_vera(
    vera_bin: str, ruleset: str, basepath: str,
    ignore_tests: bool = False, ignored_rules: Optional[List[str]] = None
) -> int:
    print("Running norm in", basepath)

    files = find_files(basepath, ignore_tests=ignore_tests)
    vera_proc = subprocess.Popen(
        shlex.split(f"{vera_bin} --profile epitech --root {ruleset}"),
        stdin=subprocess.PIPE,
        stdout=subprocess.PIPE,
        text=True
    )

    stdout, stderr = vera_proc.communicate(input='\n'.join(files))

    if not stdout:
        print(stderr)
        return -1

    reports = (
        stdout if ignored_rules is None else
        '\n'.join(
            line for line in stdout.splitlines()
            if not any(
                re.match(rf".*:{rule}$", line)
                for rule in ignored_rules
            )
        )
    )

    print(reports.replace(basepath.removesuffix('/'), '.'))
    return sum(
        reports.count(severity)
        for severity in ("FATAL", "MAJOR", "MINOR", "INFO")
    )


def main() -> int:
    if len(sys.argv) < 3:
        return 1

    vera, ruleset, *args = sys.argv[1::]
    project_dir = os.path.expanduser(
        args[0] if args and not args[0].startswith('-') else "."
    )

    ignored_rules = [
        rule for arg in args for rule in arg[15:].split(",")
        if arg.startswith("--ignore-rules=")
    ]

    marker = time.perf_counter()
    count = run_vera(
        vera, ruleset, project_dir,
        ignore_tests="--include-tests" not in args,
        ignored_rules=ignored_rules
    )

    if count != -1:
        elasped = time.perf_counter()
        print(f"Found {count} issues")
        print(f"Ran in {(elasped - marker):.3f}s")

    return count > 0 and count != -1


if __name__ == "__main__":
    sys.exit(main())
