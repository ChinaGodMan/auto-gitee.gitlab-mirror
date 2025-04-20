
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

mirror() {
  # https://github.com/ouuan/Auto-Gitee-Mirror/blob/master/.github/workflows/mirror.yml
  local github_user=$1
  local github_repo=$2
  local gitee_user=$3
  local gitee_repo=$4
  git clone https://$PAT_GITHUB_TOKEN@github.com/$github_user/$github_repo.git
  cd "$github_repo"
  git remote add gitee "git@gitee.com:$gitee_user/$gitee_repo.git" >/dev/null 2>&1
  git remote set-head origin -d >/dev/null 2>&1
  git push gitee --prune +refs/remotes/origin/*:refs/heads/* +refs/tags/*:refs/tags/* >/dev/null 2>&1
  cd ..
}
list_repos_with_pagination() {  
  local per_page=100
  local page=1
  local exclude=("auto-gitee-mirror" "stats" "github-stats" "github-stats-remotion" "github-action-dynamic-profile-page" "UserScriptsHistory")
  local repos=()
  local api_url
  local username
  if [[ -n "$1" ]]; then
    username="$1"
    api_url="https://api.github.com/users/$username/repos"
  else
    username="ChinaGodMan"
    api_url="https://api.github.com/user/repos"
  fi
  while true; do
    local response=$(curl -s -H "Authorization: token $PAT_GITHUB_TOKEN" "$api_url?per_page=$per_page&page=$page")
    local current_repos=$(echo "$response" | jq -r '.[].name')
    if [[ -z "$current_repos" ]]; then
      break
    fi
    while read -r repo; do
      if [[ ! " ${exclude[@]} " =~ " $repo " ]]; then
        repos+=("$repo")
      fi
    done <<< "$current_repos"
    ((page++))
  done
  for repo in "${repos[@]}"; do
    echo "正在同步仓库：[$repo]"
    create_gitee_repo "$repo"
    mirror "$username" "$repo" "$GITEE_USERNAME" "$repo"
  done
}

# 批量
list_repos_with_pagination

# 单个
#create_gitee_repo "gitee_repo_name"
#mirror "github_user_name" "github_repo_name" "gitee_user_name" "gitee_repo_name"
