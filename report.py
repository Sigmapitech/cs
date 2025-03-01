"""
Usage:
    nix run github:Sigmapitech/cs
    nix run github:Sigmapitech/cs -- [options]

Options:
    path                Specifies the path to the project to be checked,
                        defaults to the current directory
    --ecsls             Use the ignore list from the nearest ecsls.toml
    --ignore-rules      Specifies a list of rules to be ignored,
                        separated by commas
    --ignore-folders    Specifies a list of folders to be ignored
                        within the search path, separated by commas
    --include-tests     Specifies whether to include the test folder
                        for checking, disabled by default
    --use-gitignore     Exclude all file / folder in gitignore
    --emit-report       Output to a coding-style-reports.log file
    -h, --help          Displays this help message
"""

from typing import List

import re
import os
import subprocess
import shlex
import sys
import time
import pathlib
import tomli

IGNORE_PATTERNS: List[str] = [
    r".*/[.]build/.*",
    r".*/[.]cache/.*",
    r".*/[.]direnv/.*",
    r".*/[.]git/.*",
    r".*/[.]idea/.*",
    r".*/[.]vscode/.*",
    r"./bonus/.*",
    r".*/result/.*",
    r".*/Doxyfile"
]


def find_files(search_dir: str, ignored_folders: List[str]) -> List[str]:
    find_proc = subprocess.run(
        shlex.split(f"find {search_dir} -type f"),
        capture_output=True,
        text=True,
    )

    for folder in ignored_folders or []:
        IGNORE_PATTERNS.append(rf"{search_dir}/{folder}/.*")
    return [
        filename
        for filename in find_proc.stdout.splitlines()
        if all(
            re.match(pattern, filename) is None for pattern in IGNORE_PATTERNS
        )
    ]


def read_ecsls_ignore_list(path: pathlib.Path) -> list[str]:
    count_slash = str(path.absolute()).count('/')

    for _ in range(count_slash + 1):
        abs_path = (path / 'ecsls.toml').absolute()

        if abs_path.exists():
            with open(abs_path, "rb") as f:
                conf = tomli.load(f).get("reports", {})
                return conf.get("ignore", [])

        path = path.parent
    return []


def run_vera(
    vera_bin: str,
    ruleset: str,
    basepath: str,
    ignored_folders: List[str],
    ignored_rules: List[str],
    to_file: bool = True
) -> int:
    print("Running norm in", basepath)

    files = find_files(basepath, ignored_folders)
    vera_proc = subprocess.Popen(
        shlex.split(f"{vera_bin} --profile epitech --root {ruleset}"),
        stdin=subprocess.PIPE,
        stdout=subprocess.PIPE,
        text=True,
    )

    stdout, stderr = vera_proc.communicate(input="\n".join(files))

    if not stdout:
        print(stderr)
        return -1

    reports = (
        stdout
        if ignored_rules is None
        else "\n".join(
            line
            for line in stdout.splitlines()
            if not any(
                re.match(rf".*:{rule}$", line) for rule in ignored_rules
            )
        )
    )

    if to_file:
        with open("coding-style-reports.log", "w+") as f:
            f.write(reports + "\n")

    print(reports.replace(basepath.removesuffix("/"), "."))
    return sum(
        reports.count(severity)
        for severity in ("FATAL", "MAJOR", "MINOR", "INFO")
    )


def main() -> int:
    if len(sys.argv) < 3:
        return 1

    if "-h" in sys.argv or "--help" in sys.argv:
        print(__doc__[1:-1])
        return 0

    vera, ruleset, *args = sys.argv[1::]
    project_dir = os.path.expanduser(
        args[0] if args and not args[0].startswith("-") else "."
    )

    ignored_rules = [
        rule
        for arg in args
        for rule in arg[15:].split(",")
        if arg.startswith("--ignore-rules=")
    ]
    ignored_folders = [
        folder
        for arg in args
        for folder in arg[17:].split(",")
        if arg.startswith("--ignore-folders=")
    ]

    if "--use-gitignore" in args and os.path.isfile(".gitignore"):
        content = [
            line
            for line in pathlib.Path(".gitignore").read_text().splitlines()
            if line and not line.startswith('#')
        ]
        for (pattern, repl) in (
            (r"(?=[^.]|^)([*])", ".*"),
            (r"(?=^\[)?([.])(?=[^*])?(?!\])", "[.]")
        ):
            content = [re.sub(pattern, repl, line) for line in content]
        IGNORE_PATTERNS.extend(f".*/{line}" for line in content)

    if "--include-tests" not in args:
        ignored_folders.append("tests")

    if "--ecsls" in args:
        ignored_rules.extend(read_ecsls_ignore_list(pathlib.Path(project_dir)))

    marker = time.perf_counter()
    count = run_vera(
        vera,
        ruleset,
        project_dir,
        ignored_folders,
        ignored_rules,
        to_file="--emit-report" in args
    )

    if count != -1:
        elasped = time.perf_counter()
        print(f"Found {count} issues")
        print(f"Ran in {(elasped - marker):.3f}s")

    return count > 0 and count != -1


if __name__ == "__main__":
    sys.exit(main())
