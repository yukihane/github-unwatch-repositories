#! /bin/bash

# dry run:
# ./github-unwatch.bash [unwatch repository pattern] [github account] [github token]
#
# execute actually:
# ./github-unwatch.bash [unwatch repository pattern] [github account] [github token] run

set -eu

readonly REPOSITORY_PATTERN="$1"
readonly CREDENTIALS="$2:$3"
readonly RUN="${4:-dry-run}"

page=1
targets=()

while :
do
  # https://docs.github.com/en/rest/activity/watching#list-repositories-watched-by-the-authenticated-user
  result=($( curl \
  -u $CREDENTIALS \
  -H "Accept: application/vnd.github.v3+json" \
  "https://api.github.com/user/subscriptions?per_page=100&page=$page" \
  | jq -r '.[].full_name' ))

  # 最後まで取得し切ったらループ終了
  # https://serverfault.com/a/477506/966063
  if [[ ${#result[@]} -eq 0 ]]; then
    break
  fi

  # 対象のリポジトリを抽出
  for e in "${result[@]}"
  do
    if [[ $e =~ $REPOSITORY_PATTERN ]]; then
      targets+=($e)
    fi
  done

  page=$((++page))
done

if [[ ${#targets[@]} -eq 0 ]]; then
  exit 0
fi
for target in "${targets[@]}"
do
  echo "Unwatch: $target"
  if [[ "$RUN" == "run" ]]; then
    # https://docs.github.com/en/rest/activity/watching#delete-a-repository-subscription
    curl \
      -u $CREDENTIALS \
      -X DELETE \
      -H "Accept: application/vnd.github.v3+json" \
      "https://api.github.com/repos/$target/subscription"
  fi
done
