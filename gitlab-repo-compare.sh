#!/bin/bash

# GitLab 仓库对比脚本
# 对比 GitHub 和 GitLab 的仓库列表，找出差异

# 配置
GITHUB_TOKEN=$PAT_GITHUB_TOKEN
GITLAB_TOKEN=$GITLAB_ACCESS_TOKEN
GITLAB_URL="https://gitlab.com"  

# 创建临时文件
TEMP_DIR=$(mktemp -d)
GITHUB_REPOS="$TEMP_DIR/github_repos.txt"
GITLAB_REPOS="$TEMP_DIR/gitlab_repos.txt"
ONLY_GITHUB="$TEMP_DIR/only_github.txt"
ONLY_GITLAB="$TEMP_DIR/only_gitlab.txt"
BOTH="$TEMP_DIR/both.txt"

echo "正在获取仓库列表..."


# 获取 GitHub 仓库（处理分页）
echo "获取 GitHub 仓库..."
page=1
while true; do
    response=$(curl -s -H "Authorization: token $GITHUB_TOKEN" \
        "https://api.github.com/user/repos?per_page=100&page=$page")
    
    # 检查 API 调用是否成功
    if echo "$response" | grep -q "API rate limit"; then
        echo "GitHub API 速率限制达到"
        break
    fi
    
    # 检查是否为空
    count=$(echo "$response" | jq length 2>/dev/null || echo 0)
    if [ "$count" -eq 0 ] || [ "$response" = "[]" ]; then
        break
    fi
    
    echo "$response" | jq -r '.[].name' >> "$GITHUB_REPOS"
    echo "  第 $page 页: 获取到 $count 个仓库"
    ((page++))
done

# 获取 GitLab 仓库（处理分页）
echo "获取 GitLab 仓库..."
page=1
while true; do
    # GitLab API 获取当前用户的项目
    response=$(curl -s --header "PRIVATE-TOKEN: $GITLAB_TOKEN" \
        "$GITLAB_URL/api/v4/projects?membership=true&per_page=100&page=$page")
    
    # 检查 API 调用是否成功
    if echo "$response" | grep -q "error"; then
        echo "GitLab API 错误: $(echo "$response" | jq -r '.error // .message')"
        break
    fi
    
    # 检查是否为空
    count=$(echo "$response" | jq length 2>/dev/null || echo 0)
    if [ "$count" -eq 0 ] || [ "$response" = "[]" ]; then
        break
    fi
    
    # 提取项目名称（GitLab 的项目路径可能包含命名空间，我们只取项目名）
    echo "$response" | jq -r '.[].name' >> "$GITLAB_REPOS"
    echo "  第 $page 页: 获取到 $count 个仓库"
    ((page++))
done

# 统计总数
github_count=$(wc -l < "$GITHUB_REPOS" 2>/dev/null || echo 0)
gitlab_count=$(wc -l < "$GITLAB_REPOS" 2>/dev/null || echo 0)
echo ""
echo "GitHub 仓库总数: $github_count"
echo "GitLab 仓库总数: $gitlab_count"
echo ""

# 找出只在 GitHub 的仓库
while IFS= read -r repo; do
    if ! grep -q "^$repo$" "$GITLAB_REPOS"; then
        echo "$repo" >> "$ONLY_GITHUB"
    fi
done < "$GITHUB_REPOS"

# 找出只在 GitLab 的仓库
while IFS= read -r repo; do
    if ! grep -q "^$repo$" "$GITHUB_REPOS"; then
        echo "$repo" >> "$ONLY_GITLAB"
    fi
done < "$GITLAB_REPOS"

# 找出两个平台都有的仓库
while IFS= read -r repo; do
    if grep -q "^$repo$" "$GITLAB_REPOS"; then
        echo "$repo" >> "$BOTH"
    fi
done < "$GITHUB_REPOS"

# 统计数量
only_github_count=$(wc -l < "$ONLY_GITHUB" 2>/dev/null || echo 0)
only_gitlab_count=$(wc -l < "$ONLY_GITLAB" 2>/dev/null || echo 0)
both_count=$(wc -l < "$BOTH" 2>/dev/null || echo 0)

# 输出结果
echo "=================================================="
echo "只在 GitHub 的仓库：（$only_github_count 个）"
echo "=================================================="
if [ -s "$ONLY_GITHUB" ]; then
    cat "$ONLY_GITHUB" | sort | while IFS= read -r repo; do
        echo "  ✓ $repo"
    done
else
    echo "  （无）"
fi

echo -e "\n=================================================="
echo "只在 GitLab 的仓库：（$only_gitlab_count 个）"
echo "=================================================="
if [ -s "$ONLY_GITLAB" ]; then
    cat "$ONLY_GITLAB" | sort | while IFS= read -r repo; do
        echo "  ✓ $repo"
    done
else
    echo "  （无）"
fi

echo -e "\n=================================================="
echo "两个平台都有的仓库：（$both_count 个）"
echo "=================================================="
if [ -s "$BOTH" ]; then
    cat "$BOTH" | sort | while IFS= read -r repo; do
        echo "  ✓ $repo"
    done
else
    echo "  （无）"
fi

# 清理临时文件
rm -rf "$TEMP_DIR"

echo ""
echo "对比完成！"
