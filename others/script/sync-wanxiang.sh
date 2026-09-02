#!/bin/zsh

set -euo pipefail

script_dir=${0:A:h}
repo_dir=${script_dir:h:h}
model_name="wanxiang-lts-zh-hans.gram"
model_url="https://cnb.cool/amzxyz/rime-wanxiang/-/releases/download/model/${model_name}"
model_path="${repo_dir}/${model_name}"
deployer="/Library/Input Methods/Squirrel.app/Contents/MacOS/rime_deployer"
squirrel="/Library/Input Methods/Squirrel.app/Contents/MacOS/Squirrel"
shared_dir="/Library/Input Methods/Squirrel.app/Contents/SharedSupport"

cd "${repo_dir}"

if [[ "$(git branch --show-current)" != "main" ]]; then
  print -u2 "错误：请在 main 分支运行此脚本。"
  exit 1
fi

if [[ -n "$(git status --porcelain)" ]]; then
  print -u2 "错误：工作区不干净，请先提交或处理本地改动。"
  exit 1
fi

if [[ "$(git remote get-url --push upstream)" != "DISABLED" ]]; then
  print -u2 "错误：upstream 未禁用推送，已中止。"
  exit 1
fi

git fetch upstream wanxiang-base
git merge --no-edit upstream/wanxiang-base

if [[ "${1:-}" == "--refresh-model" || ! -s "${model_path}" ]]; then
  temp_model=$(mktemp "${TMPDIR:-/tmp}/wanxiang-model.XXXXXX")
  trap 'rm -f "${temp_model}"' EXIT
  curl --fail --location --retry 3 --output "${temp_model}" "${model_url}"
  if [[ ! -s "${temp_model}" ]]; then
    print -u2 "错误：下载的语法模型为空。"
    exit 1
  fi
  mv "${temp_model}" "${model_path}"
  trap - EXIT
fi

if [[ ! -x "${deployer}" || ! -x "${squirrel}" ]]; then
  print -u2 "错误：未找到鼠须管部署或重载工具。"
  exit 1
fi

"${deployer}" --build "${repo_dir}" "${shared_dir}" "${repo_dir}/build"
"${squirrel}" --reload

print "万象已同步并部署完成。检查无误后可运行：git push"
