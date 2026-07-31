# ble.sh generates path candidates by globbing, and bash globs never match the "."
# and ".." entries (unlike readline's own filename completion). Yield them back so
# `cd ..<TAB>` completes to `cd ../`.
function ble/complete/source:file/generate:dotdot {
  ((${#ret[@]})) && return 0
  local path=${ADVICE_WORDS[1]}
  [[ $path == . || $path == .. || $path == */. || $path == */.. ]] || return 0
  [[ -d $path ]] && ret=("$path")
  return 0
}
blehook/eval-after-load complete '
  ble/function#advice after ble/complete/source:file/generate ble/complete/source:file/generate:dotdot'
