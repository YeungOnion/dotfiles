# Validation rules for chezmoi JSON data (home/.chezmoidata/*.json).
# `violations` returns an array of messages; empty means valid.
# Used by scripts/data-edit on every edit's result, and by tests on live data.

def package_keys: ["brew_packages", "brew_packages_linux", "brew_packages_darwin",
                   "cargo_plugins", "cargo_binaries", "uv_packages"];

def list_violations($k):
  .[$k] as $xs
  | [ $xs[] | select(type != "string" or . == "" or test("\\s"))
      | "\($k): entry \(tojson) must be a non-empty string without whitespace" ]
  + [ ($xs | group_by(.) | map(select(length > 1))[] | .[0])
      | "\($k): duplicate entry \(tojson)" ];

def plugin_violations:
  if has("fish_plugins") then
    [ .fish_plugins[] | strings | select(test("^[^/\\s]+/[^/\\s]+(@\\S+)?$") | not)
      | "fish_plugins: \(tojson) is not owner/repo" ]
    + [ (.fish_plugins | map(strings) | group_by(ascii_downcase) | map(select(length > 1))[])
        | "fish_plugins: \(map(tojson) | join(", ")) differ only by case" ]
  else [] end;

def package_violations:
  [ package_keys[] as $k | select(has($k)) | .[$k][] | strings
    | select(test("^[A-Za-z0-9@][A-Za-z0-9._+@/-]*$") | not)
    | "\($k): \(tojson) is not a valid package name" ];

def map_violations($k):
  [ .[$k] | to_entries[]
    | (select(.key | test("^[A-Za-z_][A-Za-z0-9_]*$") | not)
        | "\($k): \(.key | tojson) is not a valid variable name"),
      (select(.value | type != "string")
        | "\($k).\(.key): value must be a string") ];

def violations:
  if type != "object" then ["top level must be an object"]
  else
    [ keys[] as $k
      | if (.[$k] | type) == "array" then list_violations($k)[]
        elif (.[$k] | type) == "object" then map_violations($k)[]
        else empty end ]
    + plugin_violations + package_violations
  end;
