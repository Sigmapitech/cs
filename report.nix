pkgs: ruleset: banana-vera:
(pkgs.writeShellScriptBin "cs" ''
  start_time=$(date +%s)

  if [ -z "$1" ]; then
    project_dir=$(pwd)
  else
    project_dir="$1"
  fi

  echo "Running norm in $project_dir"

  count=$(find "$project_dir"     \
    -type f                       \
    -not -path "*/.git/*"         \
    -not -path "*/.idea/*"        \
    -not -path "*/.vscode/*"      \
    -not -path "*/bonus/*"        \
    -not -path "*/tests/*"        \
    -not -path "*/*build/*"       \
  | ${banana-vera}/bin/vera++     \
    --profile epitech             \
    --root ${ruleset}/vera        \
    --error                       \
    2>&1                          \
    | sed "s|$project_dir/||"     \
    | tee /dev/stderr | wc -l
  )

  echo "Found $count issues"

  end_time=$(date +%s)
  echo "Ran in $((end_time - start_time))s"

  if [ $count -gt 0 ]; then
    exit 1
  fi

  exit 0
'')
