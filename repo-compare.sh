#!/bin/bash

# 配置
GITHUB_TOKEN=$PAT_GITHUB_TOKEN
GITEE_TOKEN=$ACCESS_TOKEN

# 创建临时文件
TEMP_DIR=$(mktemp -d)
GITHUB_REPOS="$TEMP_DIR/github_repos.txt"
GITEE_REPOS="$TEMP_DIR/gitee_repos.txt"
ONLY_GITHUB="$TEMP_DIR/only_github.txt"
ONLY_GITEE="$TEMP_DIR/only_gitee.txt"
BOTH="$TEMP_DIR/both.txt"

echo "正在获取仓库列表..."

# 获取 GitHub 仓库（处理分页）
page=1
while true; do
    response=$(curl -s -H "Authorization: token $GITHUB_TOKEN" \
        "https://api.github.com/user/repos?per_page=100&page=$page")
    
    # 检查是否为空
    if [ "$(echo "$response" | jq length)" -eq 0 ] || [ "$response" = "[]" ]; then
        break
    fi
    
    echo "$response" | jq -r '.[].name' >> "$GITHUB_REPOS"
    ((page++))
done

# 获取 Gitee 仓库（处理分页）
page=1
while true; do
    response=$(curl -s "https://gitee.com/api/v5/user/repos?access_token=$GITEE_TOKEN&per_page=100&page=$page")
    
    # 检查是否为空
    if [ "$(echo "$response" | jq length)" -eq 0 ] || [ "$response" = "[]" ]; then
        break
    fi
    
    echo "$response" | jq -r '.[].name' >> "$GITEE_REPOS"
    ((page++))
done

# 统计总数
github_count=$(wc -l < "$GITHUB_REPOS" 2>/dev/null || echo 0)
gitee_count=$(wc -l < "$GITEE_REPOS" 2>/dev/null || echo 0)
echo "GitHub 仓库总数: $github_count"
echo "Gitee 仓库总数: $gitee_count"
echo ""

# 找出只在 GitHub 的仓库
while IFS= read -r repo; do
    if ! grep -q "^$repo$" "$GITEE_REPOS"; then
        echo "$repo" >> "$ONLY_GITHUB"
    fi
done < "$GITHUB_REPOS"

# 找出只在 Gitee 的仓库
while IFS= read -r repo; do
    if ! grep -q "^$repo$" "$GITHUB_REPOS"; then
        echo "$repo" >> "$ONLY_GITEE"
    fi
done < "$GITEE_REPOS"

# 找出两个平台都有的仓库
while IFS= read -r repo; do
    if grep -q "^$repo$" "$GITEE_REPOS"; then
        echo "$repo" >> "$BOTH"
    fi
done < "$GITHUB_REPOS"

# 统计数量
only_github_count=$(wc -l < "$ONLY_GITHUB" 2>/dev/null || echo 0)
only_gitee_count=$(wc -l < "$ONLY_GITEE" 2>/dev/null || echo 0)
both_count=$(wc -l < "$BOTH" 2>/dev/null || echo 0)

# 输出结果
echo "=================================================="
echo "只在 GitHub 的仓库：（$only_github_count 个）"
echo "=================================================="
if [ -s "$ONLY_GITHUB" ]; then
    cat "$ONLY_GITHUB" | while IFS= read -r repo; do
        echo "  ✓ $repo"
    done
else
    echo "  （无）"
fi

echo -e "\n=================================================="
echo "只在 Gitee 的仓库：（$only_gitee_count 个）"
echo "=================================================="
if [ -s "$ONLY_GITEE" ]; then
    cat "$ONLY_GITEE" | while IFS= read -r repo; do
        echo "  ✓ $repo"
    done
else
    echo "  （无）"
fi

echo -e "\n=================================================="
echo "两个平台都有的仓库：（$both_count 个）"
echo "=================================================="
if [ -s "$BOTH" ]; then
    cat "$BOTH" | while IFS= read -r repo; do
        echo "  ✓ $repo"
    done
else
    echo "  （无）"
fi

# 清理临时文件
rm -rf "$TEMP_DIR" 
