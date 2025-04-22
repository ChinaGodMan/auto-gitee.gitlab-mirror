#!/usr/bin/env bash
# shellcheck disable=SC2148
create_gitee_repo() {
  local repo_name=$1
  curl -s -o /dev/null -X POST "https://gitee.com/api/v5/user/repos" \
    -H "Content-Type: application/json" \
    -d '{
      "access_token": "'"${ACCESS_TOKEN}"'",
      "name": "'"${repo_name}"'",
      "private": true,
      "description": "'"${repo_name}"' 仓库"
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
  # shellcheck disable=SC2086
  if is_mirrorignore $github_user $github_repo; then
    echo "[$github_repo] 禁止镜像"
    return 0
  fi
  echo "正在同步仓库：[$github_repo]"
  # shellcheck disable=SC2086
  git clone https://$PAT_GITHUB_TOKEN@github.com/$github_user/$github_repo.git
  # shellcheck disable=SC2164
  cd "$github_repo"
  if [ "$push_method" = "ssh" ]; then
    git remote add gitee "git@gitee.com:$gitee_user/$gitee_repo.git" >/dev/null 2>&1
  else
    echo "使用 HTTPS 推送"
    git remote add gitee "https://$gitee_user:$ACCESS_TOKEN@gitee.com/$gitee_user/$gitee_repo.git" >/dev/null 2>&1
  fi

  git remote set-head origin -d >/dev/null 2>&1
  git push gitee --prune +refs/remotes/origin/*:refs/heads/* +refs/tags/*:refs/tags/* >/dev/null 2>&1
  # shellcheck disable=SC2103
  cd ..
}
# shellcheck disable=SC2120
list_repos_with_pagination() {
  local per_page=100
  local page=1
  local exclude_file=".mirrorignore"
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
    local current_repos=$(echo "$response" | jq -r '.[].name')
    if [[ -z "$current_repos" ]]; then
      break
    fi
    while read -r repo; do
      # shellcheck disable=SC2199
      # shellcheck disable=SC2076
      if [[ ! " ${exclude[@]} " =~ " $repo " ]]; then
        repos+=("$repo")
      fi
    done <<<"$current_repos"
    ((page++))
  done
  for repo in "${repos[@]}"; do
    create_gitee_repo "$repo"
    mirror "$username" "$repo" "$GITEE_USERNAME" "$repo"
  done
}

# 批量
list_repos_with_pagination

# 单个
#create_gitee_repo "gitee_repo_name"
#mirror "github_user_name" "github_repo_name" "gitee_user_name" "gitee_repo_name"
