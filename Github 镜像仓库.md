
### 首先准备“钥匙” (Personal Access Token)

> GitHub 不让你用登录密码推镜像。

- 去 GitHub 设置：`Settings` -> `Developer settings` -> `Personal access tokens (classic)`。
    
- 生成一个 Token，勾选 `write:packages` 和 `read:packages`。**保存好这个 Token**。

### 终端登录
```
# 这里的 TOKEN 就是你刚才保存的字符串
export CR_PAT=YOUR_TOKEN
echo $CR_PAT | docker login ghcr.io -u YOUR_GITHUB_USERNAME --password-stdin
```

### 打标并推送
```
# 打标（别忘了全小写，GitHub 仓库名不喜欢大写）
docker tag my-nginx:v1.0 ghcr.io/yourname/my-nginx:v1.0

# 推送
docker push ghcr.io/yourname/my-nginx:v1.0
```

如何拉取？
```
docker pull ghcr.io/yourname/my-nginx:v1.0
```

密钥存放位置：Bitwarden 软件