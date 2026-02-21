#!/usr/bin/env bash
# shellcheck disable=SC2148
create_gitee_repo() {
  local repo_name=$1
  local repo_description=$2
  local safe_description=$(printf "%s" "$repo_description" | jq -R -s '.')
  curl -s -o /dev/null -X POST "https://gitee.com/api/v5/user/repos" \
    -H "Content-Type: application/json" \
    -d '{
      "access_token": "'"${ACCESS_TOKEN}"'",
      "name": "'"${repo_name}"'",
      "private": true,
      "description": '"${safe_description}"'
    }'
}
update_gitee_repo_description() {
  local REPO_PATH=$1
  local NEW_DESCRIPTION=$2
  # shellcheck disable=SC2155
  local USERNAME=$(echo "$REPO_PATH" | cut -d'/' -f1)
  # shellcheck disable=SC2155
  local REPO_NAME=$(echo "$REPO_PATH" | cut -d'/' -f2)
  local API_URL="https://gitee.com/api/v5/repos/$USERNAME/$REPO_NAME"
  curl -s -o /dev/null -X PATCH "$API_URL" \
    -H "Authorization: token $ACCESS_TOKEN" \
    -H "Content-Type: application/json" \
    -d '{
          "name": "'"$REPO_NAME"'",
          "owner": "'"$USERNAME"'",
          "description": "'"$NEW_DESCRIPTION"'"
          }'
}
is_mirrorignore() {
  local github_user=$1
  local github_repo=$2
  local url="https://raw.githubusercontent.com/${github_user}/${github_repo}/main/.mirrorignore"
  # shellcheck disable=SC2086
  status_code=$(curl -s -o /dev/null -w "%{http_code}" -H "Authorization: token $PAT_GITHUB_TOKEN" $url)
  if [ "$status_code" -eq 200 ]; then
    return 0
  else
    return 1
  fi
}

mirror() {
  # https://github.com/ouuan/Auto-Gitee-Mirror/blob/master/.github/workflows/mirror.yml
  local github_user=$1
  local github_repo=$2
  local gitee_user=$3
  local gitee_repo=$4
  local push_method=$5
  local check_mirror=$6
  # shellcheck disable=SC2086
  if [ "$check_mirror" = "true" ]; then
    if is_mirrorignore $github_user $github_repo; then
      echo -e "\033[31m mirror:[$github_user/$github_repo]存在[.mirrorignore]文件,跳过镜像\033[0m"
      return 0
    fi
  fi
  echo -e "\033[32m正在同步仓库:[$github_user/$github_repo]\033[0m"
  # shellcheck disable=SC2086
  git clone https://$PAT_GITHUB_TOKEN@github.com/$github_user/$github_repo.git >/dev/null 2>&1
  # shellcheck disable=SC2164
  cd "$github_repo"
  if [ "$push_method" = "ssh" ]; then
    git remote add gitee "git@gitee.com:$gitee_user/$gitee_repo.git" >/dev/null 2>&1
  else
    git remote add gitee "https://$gitee_user:$ACCESS_TOKEN@gitee.com/$gitee_user/$gitee_repo.git" >/dev/null 2>&1
  fi

  git remote set-head origin -d >/dev/null 2>&1
  output=$(git push gitee --prune +refs/remotes/origin/*:refs/heads/* +refs/tags/*:refs/tags/* 2>&1)
  # shellcheck disable=SC2181
  if [ $? -ne 0 ]; then
    while IFS= read -r line; do
      echo -e "\033[31m\t$line\033[0m"
    done <<<"$output"
  fi
  # shellcheck disable=SC2103
  cd ..
}
# shellcheck disable=SC2120
list_repos_with_pagination() {
  local per_page=100
  local page=1
  local exclude_file=".automirrorignore"
  local exclude=()
  local repos=()
  local api_url
  local username
  if [[ -f "$exclude_file" ]]; then
    mapfile -t exclude <"$exclude_file"
  fi
  if [[ -n "$1" ]]; then
    username="$1"
    api_url="https://api.github.com/users/$username/repos"
  else
    username=$GITHUB_REPO_OWNER
    api_url="https://api.github.com/user/repos"
  fi
  while true; do
    # shellcheck disable=SC2155
    local response=$(curl -s -H "Authorization: token $PAT_GITHUB_TOKEN" "$api_url?per_page=$per_page&page=$page")
    # shellcheck disable=SC2155
    current_repos=$(echo "$response" | jq -r '.[] | "\(.name):\(.description)"')
    if [[ -z "$current_repos" ]]; then
      break
    fi
    while read -r repo; do
      # shellcheck disable=SC2199
      # shellcheck disable=SC2076
      repo_name=$(echo "$repo" | cut -d':' -f1)
      # shellcheck disable=SC2199
      # shellcheck disable=SC2076
      if [[ ! " ${exclude[@]} " =~ " $repo_name " ]]; then
        repos+=("$repo")
      fi
    done <<<"$current_repos"
    ((page++))
  done
  for repo in "${repos[@]}"; do
    repo_name=$(echo "$repo" | cut -d':' -f1)
    repo_description=$(echo "$repo" | cut -d':' -f2-)
    # shellcheck disable=SC2086
    #! 在此处进行判断,不然直接执行gitee创建仓库了
    if is_mirrorignore $username $repo_name; then
      echo -e "\033[31m[$username/$repo_name]存在<.mirrorignore>文件,跳过镜像\033[0m"
    else
      #update_gitee_repo_description "$GITEE_USERNAME/$repo_name" "$repo_description"
      create_gitee_repo "$repo_name" "$repo_description"
      mirror "$username" "$repo_name" "$GITEE_USERNAME" "$repo_name"
    fi

  done
}

# 批量
list_repos_with_pagination

# 单个
#create_gitee_repo "gitee_repo_name"
#mirror "github_user_name" "github_repo_name" "gitee_user_name" "gitee_repo_name"
