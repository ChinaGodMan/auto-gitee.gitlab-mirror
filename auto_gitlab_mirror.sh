#!/usr/bin/env bash
# shellcheck disable=SC2148
create_gitlab_repo() {
  local repo_name=$1
  local repo_description=$2
  curl -s -o /dev/null -X POST "https://gitlab.com/api/v4/projects" \
    -H "PRIVATE-TOKEN: $GITLAB_ACCESS_TOKEN" \
    -H "Content-Type: application/json" \
    -d '{
      "name": "'"${repo_name}"'",
      "description": "'"${repo_description}"'",
      "visibility": "private"
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
  # https://github.com/ouuan/Auto-gitee-Mirror/blob/master/.github/workflows/mirror.yml
  local github_user=$1
  local github_repo=$2
  local gitlab_user=$3
  local gitlab_repo=$4
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
  git clone https://$PAT_GITHUB_TOKEN@github.com/$github_user/$github_repo.git
  # shellcheck disable=SC2164
  cd "$github_repo"
  if [ "$push_method" = "ssh" ]; then
    git remote add gitlab "git@gitlab.com:$gitlab_user/$gitlab_repo.git" >/dev/null 2>&1
  else
    git remote add gitlab "https://$gitlab_user:$GITLAB_ACCESS_TOKEN@gitlab.com/$gitlab_user/$gitlab_repo.git" >/dev/null 2>&1
  fi

  git remote set-head origin -d >/dev/null 2>&1
  git push gitlab --prune +refs/remotes/origin/*:refs/heads/* +refs/tags/*:refs/tags/* >/dev/null 2>&1
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
    #! 在此处进行判断,不然直接执行gitlab创建仓库了
    if is_mirrorignore $username $repo_name; then
      echo -e "\033[31m[$username/$repo_name]存在<.mirrorignore>文件,跳过镜像\033[0m"
    else
      create_gitlab_repo "$repo_name" "$repo_description"
      mirror "$username" "$repo_name" "$GITLAB_USERNAME" "$repo_name"
    fi

  done
}

# 批量
list_repos_with_pagination

# 单个
#create_gitlab_repo "gitlab_repo_name"
#mirror "github_user_name" "github_repo_name" "gitlab_user_name" "gitlab_repo_name"
