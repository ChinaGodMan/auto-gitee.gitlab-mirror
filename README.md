<div align="right">
    <h6>
        <picture>
            <source type="image/svg+xml" media="(prefers-color-scheme: dark)"
                srcset="https://assets.aiwebextensions.com/images/icons/earth/white/icon32.svg">
            <img height=14
                src="https://assets.aiwebextensions.com/images/icons/earth/black/icon32.svg">
        </picture>
        English|
        <a href="https://github.com/ChinaGodMan/auto-gitee-mirror/blob/main/README.zh-CN.md">简体中文</a>
    <br>
    </h6>
</div>
<div align="center">
  <img height="96px" width="96px" src="https://avatars.githubusercontent.com/u/96548841?v=4" alt="UserScripts">
  <h1>Auto Gitee&GitLab Mirror</h1>

### Automatically Mirror GitHub ↠ Gitee & GitLab

</div>

Inspired by https://github.com/ouuan/Auto-Gitee-Mirror/blob/master/.github/workflows/mirror.yml

> [!WARNING]
> LFS-managed repositories are not supported yet.

## Script Features

- **Automatically Create Gitee & GitLab Repositories**: Creates private repositories on Gitee or GitLab based on the GitHub repository name.
- **Repository Synchronization**: Clones code from GitHub and pushes it to Gitee or GitLab.
- **Ignore Rules**: Excludes repositories from synchronization using a `.mirrorignore` file.
- **Ignore Rules (Extended)**: The `.mirrorignore` file also acts as a placeholder. If this file exists in the repository being synchronized, it skips synchronization (regardless of the `.mirrorignore` settings in the program's root directory).
- **Batch Processing**: Supports pagination for fetching GitHub repositories and synchronizing them.
- **Push Methods**: Supports pushing code to Gitee or GitLab via HTTPS or SSH.

---

### Pushing to GitLab

**Set Up Environment Variables**

- `GITLAB_ACCESS_TOKEN`: Access token for GitLab.
- `PAT_GITHUB_TOKEN`: Access token for GitHub.
- `GITLAB_USERNAME`: GitLab username.
- `GITLAB_SSH_PRIVATE_KEY`: SSH private key for GitLab.

**Usage**

- Batch mirror repositories for a specified user:

  ```bash
  list_repos_with_pagination <github_user_name>
  ```

  > Defaults to the current user.

- <h6>Mirror a specific repository: Creates the repository on GitLab if it does not already exist.</h6>

  ```bash
  create_gitlab_repo <gitlab_repo_name>

  mirror <github_user_name> <github_repo_name> <gitlab_user_name> <gitlab_repo_name>
  ```

<img height=6px width="100%" src="https://media.chatgptautorefresh.com/images/separators/gradient-aqua.png?latest">

### Pushing to Gitee

**Set Up Environment Variables**

- `ACCESS_TOKEN`： Access token for Gitee.
- `PAT_GITHUB_TOKEN`：Access token for GitHub.
- `GITEE_USERNAME`：Gitee username.
- `GITEE_SSH_PRIVATE_KEY` ：SSH private key for Gitee.

**Usage**

- Batch mirror repositories for a specified user:

  ```bash
  list_repos_with_pagination <github_user_name>
  ```

  > Defaults to the current user.

- <h6>Mirror a specific repository: Creates the repository on Gitee if it does not already exist.</h6>

  ```bash
  create_gitee_repo <gitee_repo_name>

  mirror <github_user_name> <github_repo_name> <gitee_user_name> <gitee_repo_name>
  ```
