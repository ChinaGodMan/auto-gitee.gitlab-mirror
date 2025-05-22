<div align="right">
    <h6>
        <picture>
            <source type="image/svg+xml" media="(prefers-color-scheme: dark)"
                srcset="https://assets.aiwebextensions.com/images/icons/earth/white/icon32.svg">
            <img height=14
                src="https://assets.aiwebextensions.com/images/icons/earth/black/icon32.svg">
        </picture>
        简体中文|
        <a href="https://github.com/ChinaGodMan/auto-gitee-mirror/blob/main/README.md">English</a>
    <br>
    </h6>
</div>

<div align="center"> <img height="96px" width="96px" src="https://avatars.githubusercontent.com/u/96548841?v=4" alt="UserScripts"></a><h1>Auto Gitee&GitLab Mirror</h1>

### 自动镜像 GitHub↠Gitee &GitLab

</div>

灵感来源于 https://github.com/ouuan/Auto-Gitee-Mirror/blob/master/.github/workflows/mirror.yml

> [!WARNING]
> 暂不支持 lfs 管理的仓库

## 脚本功能

- **自动创建 Gitee&GitLab 仓库**：根据 GitHub 仓库的名称创建私有的 Gitee 或者 GitLab 仓库。
- **仓库同步**：从 GitHub 克隆仓库代码并推送至 Gitee 或者 GitLab。
- **忽略规则**：通过 `.mirrorignore` 文件排除不需要同步的仓库。
- **忽略规则**： `.mirrorignore` 也作为占位判断,如果同步的仓库下存在这个文件,跳过同步.(无论本程序根目录下`.mirrorignore`未排除此仓库)
- **批量处理**：支持分页拉取 GitHub 仓库列表并进行同步。
- **推送方式**：支持通过 HTTPS 或 SSH 推送代码到 Gitee 或者 GitLab。

---

### 推送到 GitLab

**前期设置环境变量**

- `GITLAB_ACCESS_TOKEN`：GitLab 的访问令牌。
- `PAT_GITHUB_TOKEN`：GitHub 的访问令牌。
- `GITLAB_USERNAME`：GitLab 用户名。
- `GITLAB_SSH_PRIVATE_KEY` ：GitLab 的 SSH 私钥。

**使用方法**

- 批量对指定用户的仓库进行镜像:

  ```bash
  list_repos_with_pagination <github_user_name>
  ```

  > 默认为当前用户

- <h6>对指定用户的仓库进行镜像:无论仓库在 GitLab 是否存在,都进行创建.</h6>

  ```bash
  create_gitlab_repo <gitlab_repo_name>

  mirror <github_user_name> <github_repo_name> <gitlab_user_name> <gitlab_repo_name>
  ```

<img height=6px width="100%" src="https://media.chatgptautorefresh.com/images/separators/gradient-aqua.png?latest">

### 推送到 Gitee

**前期设置环境变量**

- `ACCESS_TOKEN`：Gitee 的访问令牌。
- `PAT_GITHUB_TOKEN`：GitHub 的访问令牌。
- `GITEE_USERNAME`：Gitee 用户名。
- `GITEE_SSH_PRIVATE_KEY` ：Gitee 的 SSH 私钥。

**使用方法**

- 批量对指定用户的仓库进行镜像:

  ```bash
  list_repos_with_pagination <github_user_name>
  ```

  > 默认为当前用户

- <h6>对指定用户的仓库进行镜像:无论仓库在 Gitee 是否存在,都进行创建.</h6>

  ```bash
  create_gitee_repo <gitee_repo_name>

  mirror <github_user_name> <github_repo_name> <gitee_user_name> <gitee_repo_name>
  ```
