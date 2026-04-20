

# 前言

Kubernetes（简称 k8s）是一个开源的容器编排平台，用于自动化部署、扩展和管理容器化应用。其核心设计遵循分布式、模块化的微服务架构，而非单体系统，主要分为**控制平面（Master 节点）**和**工作节点（Worker 节点）**两部分，共同协作以实现集群的自动化运维与高可用性。

------

### **一、控制平面（Master 节点）**

控制平面负责集群的全局决策与状态管理，包含以下核心组件：

1. **etcd**
   分布式键值存储数据库，作为 Kubernetes 的“数据大脑”，持久化存储所有集群配置、状态及元数据。它保证数据的一致性与高可用性，是集群状态信息的唯一可信源。
2. **kube-apiserver**
   集群的**统一网关**，提供 RESTful API 接口（默认端口 8443），是所有内部组件与外部客户端（如 `kubectl`）与集群交互的唯一入口。它负责认证、授权、请求校验与数据读写转发。
3. **kube-scheduler**
   **智能调度器**，负责为新创建的 Pod 分配合适的工作节点。它基于资源需求、节点负载、亲和性策略等约束条件，自动选择最优节点运行 Pod。
4. **kube-controller-manager**
   运行多种**控制器**的核心组件，通过**控制回路**持续监控集群状态（如 Pod 副本数、节点状态），并与 etcd 中存储的期望状态进行对比。一旦发现偏差（如 Pod 崩溃），立即触发修复操作（如重启 Pod），实现集群的自我修复与自动化运维。

------

### **二、工作节点（Worker 节点）**

工作节点是容器实际运行的位置，每个节点包含以下关键组件：

1. **kubelet**
   节点上的**代理**，负责接收来自 Master 的指令，管理本节点上 Pod 的生命周期（如创建、销毁容器），并定期向 Master 报告节点与 Pod 状态。
2. **Pod**
   Kubernetes 中最小的**可调度计算单元**。每个 Pod 包含一个或多个紧密关联的容器，这些容器共享网络命名空间、存储卷及其他资源，通常被调度到同一节点上协同工作。
3. **kube-proxy**
   节点上的**网络代理**，负责维护网络规则（如 iptables/IPVS），实现 Service 的虚拟 IP 负载均衡、服务发现与 Pod 间的网络通信，确保集群内部网络连通性。

------

### **三、核心协作流程**

1. 用户通过 `kubectl` 或 API 向 **kube-apiserver** 提交部署请求。
2. **kube-scheduler** 为 Pod 选择合适的工作节点，并将调度结果写入 **etcd**。
3. 目标节点上的 **kubelet** 监控到新任务，拉取镜像并启动 Pod 中的容器。
4. **kube-controller-manager** 持续监控 Pod 状态，确保实际数量与期望值一致。
5. **kube-proxy** 为 Pod 配置网络，使其可通过 Service 被其他 Pod 或外部访问。

------

### **四、设计特点与优势**

- **声明式架构**：用户定义“期望状态”，Kubernetes 自动驱动集群向该状态收敛。
- **自我修复**：通过控制器自动重启异常容器、替换故障节点，保障应用高可用。
- **弹性伸缩**：支持根据负载自动扩缩容 Pod 或节点。
- **可扩展性**：可通过 CRD（自定义资源）、Operator 等机制扩展功能。
- **松耦合设计**：组件间通过 API 通信，允许独立升级与替换。

------

### **总结**

Kubernetes 通过**分工明确的微服务组件**，实现了容器化应用的自动化部署、运维与故障恢复。Master 节点专注于集群调度与状态管理，Worker 节点负责具体工作负载的执行，二者协同构成一个**高度自动化、可自我修复的分布式系统**，成为云原生时代的核心基础设施。



> - k8s 非单体架构，是由多个微服务组成 ；
> - k8s 分为控制端（也称为管理节点、Master）与被控制端（工作节点、Worke）；
> - Master 节点分为四大块：
>   - etcd：类似于数据库，负责存储集群的所有配置信息和状态数据，采用键值对形式存储。
>   - scheduler：智能调度器，负责决定容器（Pod）在哪个 Worker 节点上运行。
>   - kube-api-server：Kubernetes 的“网关”，提供 API 接口，允许外部和集群内部的各个组件进行通信。通常监听 8443 端口。
>   - contraller manager：持续监控集群的实际状态，并确保其与期望状态一致。
>     - 通过不断地对比实际状态与期望状态，执行相应的操作来“修复”不一致的情况，从而保证集群的稳定性和高可用性。
>     - 这种控制回路让 Kubernetes 成为一个自我修复的系统，能够自动处理大多数故障，减少人工干预。
> - Worke 节点分为三大块：
>   - kubelet：Kubernetes 中的 "代理"，它在每个 Worker 节点上运行，负责接收 Master 节点的指令并执行。它管理节点上的 Pod 和容器；
>   - pod：k8s 中最小的计算单元，包含一个或多个容器；这些容器共享存储和网络，通常部署在同一节点上。
>   - kube-proxy：负责在每个 Worker 节点上维护网络规则，管理 Pod 间的网络通信。它确保 Pod 能够通过虚拟 IP 地址与集群中的其他 Pod 通信。

![image-20251210152011740](https://cdn.jsdelivr.net/gh/duanxueli08-cell/Obsidian-Images@main/img/image-20251210152011740.png)



![image-20251210095515555](https://cdn.jsdelivr.net/gh/duanxueli08-cell/Obsidian-Images@main/img/image-20251210095515555.png)

# 部署

#### 基于 Docker 安装

###### 准备工作

```powershell
# 按照规划配置修改主机名（唯一的主机名）
hostnamectl set-hostname master1.wang.org
hostnamectl set-hostname master2.wang.org
hostnamectl set-hostname master3.wang.org
hostnamectl set-hostname node1.wang.org
hostnamectl set-hostname node2.wang.org
hostnamectl set-hostname node3.wang.org
hostnamectl set-hostname ha1
hostnamectl set-hostname ha2


cat >> /etc/hosts <<'eof'
10.0.0.100 kubeapi.wang.org kubeapi
10.0.0.101 master1.wang.org master1
10.0.0.102 master2.wang.org master2
10.0.0.103 master3.wang.org master3
10.0.0.104 node1.wang.org node1
10.0.0.105 node2.wang.org node2
10.0.0.106 node3.wang.org node3
10.0.0.107 ha1.wang.org ha1
10.0.0.108 ha2.wang.org ha2
eof

ls /root/.ssh/id_rsa.pub || ssh-keygen -t rsa
for host in 10.0.0.{102..108}; do
    ssh-copy-id -i /root/.ssh/id_rsa.pub -o StrictHostKeyChecking=no root@$host
done

for host in 10.0.0.{102..106}; do
    scp /etc/hosts root@$host:/etc/hosts
done

# 网卡配置中不要加search指令
sed -i '/search/d;/8\.8\.8\.8/d' /etc/netplan/50-cloud-init.yaml

# 主机时间同步,集群的 Master 和各 node 同步时间

# 关闭防火墙，禁用 SELinux

# 禁用 Swap 设备

systemctl stop swap.img.swap
systemctl mask swap.img.swap
swapoff -a				# 关闭所有 swap
swapon --show			# 检查指令；没有输出则证明关闭所有 swap

# 内核优化
modprobe overlay
modprobe br_netfilter
# 查看
lsmod |grep -E 'overlay|br_netfilter'
# 开机加载
cat > /etc/modules-load.d/k8s.conf <<'eof'
overlay
br_netfilter
eof
# 设置所需的 sysctl 参数，参数在重新启动后保持不变
cat > /etc/sysctl.d/k8s.conf <<'eof'
net.bridge.bridge-nf-call-iptables = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward = 1
eof
# 应用 sysctl 参数生效而不重新启动
sysctl --system
```

###### Keepalived

```powershell
apt update && apt -y install keepalived

cat > /etc/keepalived/keepalived.conf <<'eof'
global_defs {
    notification_email {
        acassen
    }
    notification_email_from Alexandre.Cassen@firewall.loc
    smtp_server 192.168.200.1
    smtp_connect_timeout 30
    router_id ha1.wang.org   # 在 ha2 上为 ha2.wang.org
}

vrrp_script check_haproxy {
    #script "/etc/keepalived/check_haproxy.sh"
    script "killall -0 haproxy"
    interval 1
    weight -30
    fall 3
    rise 2
    timeout 2
}

vrrp_instance VI_1 {
    state MASTER              # 在 ha2 上为 BACKUP
    interface eth0
    garp_master_delay 10
    smtp_alert

    virtual_router_id 66      # ha1 / ha2 必须一致
    priority 100              # 在 ha2 上为 80
    advert_int 1

    authentication {
        auth_type PASS
        auth_pass 123456      # ha1 / ha2 必须一致
    }

    virtual_ipaddress {
        10.0.0.100/24 dev eth0 label eth0:1
    }

    track_script {
        check_haproxy
    }
}
eof

cat > /etc/keepalived/check_haproxy.sh <<'eof'
#!/bin/bash
/usr/bin/killall -0 haproxy || systemctl restart haproxy
eof
chmod +x /etc/keepalived/check_haproxy.sh
systemctl start keepalived.service ; systemctl status keepalived.service
hostname -I
```

```powershell
# 第二台服务器
cat > /etc/keepalived/keepalived.conf <<'eof'
global_defs {
    notification_email {
        acassen
    }
    notification_email_from Alexandre.Cassen@firewall.loc
    smtp_server 192.168.200.1
    smtp_connect_timeout 30
    router_id ha2.wang.org   # 在 ha2 上为 ha2.wang.org
}

vrrp_script check_haproxy {
    #script "/etc/keepalived/check_haproxy.sh"
    script "killall -0 haproxy"
    interval 1
    weight -30
    fall 3
    rise 2
    timeout 2
}

vrrp_instance VI_1 {
    state BACKUP              # 在 ha2 上为 BACKUP
    interface eth0
    garp_master_delay 10
    smtp_alert

    virtual_router_id 66      # ha1 / ha2 必须一致
    priority 80             # 在 ha2 上为 80
    advert_int 1

    authentication {
        auth_type PASS
        auth_pass 123456      # ha1 / ha2 必须一致
    }

    virtual_ipaddress {
        10.0.0.100/24 dev eth0 label eth0:1
    }

    track_script {
        check_haproxy
    }
}
eof
```

```powershell
# 两台设备都执行这个指令；绑定端口
cat >> /etc/sysctl.conf <<EOF
net.ipv4.ip_nonlocal_bind = 1
EOF

sysctl -p
```

###### Haproxy

```powershell
apt -y install haproxy
# 先暂时禁用master2和master3，等kubernetes安装完成后，再启用
systemctl restart haproxy ; systemctl status haproxy
# 浏览器查看： http://ha1.wang.org:8888/status     ha2.wang.org:8888/status    kubeapi.wang.org:8888/status
cat >> /etc/haproxy/haproxy.cfg <<'eof'
listen stats
    mode http
    bind 0.0.0.0:8888
    log global
    stats enable
    stats uri /status
    stats auth admin:123456


listen kubernetes-api-6443
    bind 10.0.0.100:6443
    mode tcp
    server master1 10.0.0.101:6443 check inter 3s fall 3 rise 3
    # 先暂时禁用 master2 和 master3，等 kubernetes 安装完成后，再启用
    #server master2 10.0.0.102:6443 check inter 3s fall 3 rise 3
    #server master3 10.0.0.103:6443 check inter 3s fall 3 rise 3
eof

# 登录：http://10.0.0.100:8888/status
# 账号密码：admin	123456
```

###### Docker

```powershell
apt -y install docker.io
cat > /etc/docker/daemon.json <<'eof'
{
  "registry-mirrors": [
    "https://docker.m.daocloud.io","https://docker.1panel.live"],
  "insecure-registries": ["harbor.wang.org"]
}
eof
systemctl restart docker

# 二进制安装
# 下载地址：https://github.com/Mirantis/cri-dockerd/releases
wget https://github.com/Mirantis/cri-dockerd/releases/download/v0.3.21/cri-dockerd-0.3.21.amd64.tgz
tar xf cri-dockerd-0.3.21.amd64.tgz && mv /root/cri-dockerd/cri-dockerd /usr/bin/
for i in {102..106} ; do scp /usr/bin/cri-dockerd 10.0.0.$i:/usr/bin/cri-dockerd ; done
# 配置 service 和 socket 文件
wget -O /lib/systemd/system/cri-docker.service https://raw.githubusercontent.com/Mirantis/cri-dockerd/refs/heads/master/packaging/systemd/cri-docker.service
wget -O /lib/systemd/system/cri-docker.socket https://raw.githubusercontent.com/Mirantis/cri-dockerd/refs/heads/master/packaging/systemd/cri-docker.socket
# 下载后做一点优化
sed -i 's#^ExecStart.*#ExecStart=/usr/bin/cri-dockerd --container-runtime-endpoint fd:// --pod-infra-container-image registry.aliyuncs.com/google_containers/pause:3.10.1#' /lib/systemd/system/cri-docker.service
grep ExecStart /lib/systemd/system/cri-docker.service
for i in {102..106} ; do scp /lib/systemd/system/cri-docker.service 10.0.0.$i:/lib/systemd/system/cri-docker.service ; done
for i in {102..106} ; do scp /lib/systemd/system/cri-docker.socket 10.0.0.$i:/lib/systemd/system/cri-docker.socket ; done
systemctl daemon-reload && systemctl restart cri-docker.service
systemctl enable cri-docker.service     # 在实验中我不喜欢做这个配置，知道就行！
# 测试做的配置优化是否可行
docker pull registry.aliyuncs.com/google_containers/pause:3.10.1
```

###### K8s 软件源和 kubeadm

所有 master 和 node 节点安装kubeadm等相关包

> 官方文档：https://kubernetes.io/zh-cn/docs/setup/production-environment/tools/kubeadm/install-kubeadm/#installing-kubeadm-kubelet-and-kubectl
>
> 国内指导文档：[Kubernetes镜像-Kubernetes镜像下载安装-开源镜像站-阿里云](https://developer.aliyun.com/mirror/kubernetes?spm=a2c6h.13651102.0.0.3e221b11fXyWDY)

```powershell
# k8s 集群清空本地软件源（可选）
rm -rf /etc/apt/sources.list.d/*
# 查看目前的版本，自定义版本
https://github.com/kubernetes/kubernetes/releases
# 对k8s集群刷入下面的指令（指导文档获取的指令）
curl -fsSL https://mirrors.aliyun.com/kubernetes-new/core/stable/v1.34/deb/Release.key |
    gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
echo "deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://mirrors.aliyun.com/kubernetes-new/core/stable/v1.28/deb/ /" |
    tee /etc/apt/sources.list.d/kubernetes.list
apt-get update
# 查看仓库是否下载，文件目录中会生成一个 kubernetes.list 文件
cat /etc/apt/sources.list.d/kubernetes.list
# 最后更新软件源
apt update
```

```powershell
# 查看安装 k8s 的安装工具；（若是需要别的版本，需要指定版本号）
apt list kubeadm
# 指定三个安装包(六台 k8s 集群设备都需要安装)
apt install -y kubeadm kubelet kubectl
```

###### 初始化

第一个 master 节点准备 k8s 的初始化

```powershell
# 实现 kubeadm 命令补全 （主要是在第一个master节点使用）
kubeadm completion bash > /etc/profile.d/kubeadm_completion.sh
source /etc/profile.d/kubeadm_completion.sh
# 先定义 k8s 版本（变量）；然后开始第一个master节点的初始化（这一步很重要！）
K8S_RELEASE_VERSION=1.34.2
kubeadm init --kubernetes-version=v${K8S_RELEASE_VERSION} --control-plane-endpoint kubeapi.wang.org --pod-network-cidr 10.244.0.0/16 --service-cidr 10.96.0.0/12 --token-ttl=0 --image-repository registry.aliyuncs.com/google_containers --upload-certs --cri-socket=unix:///run/cri-dockerd.sock
初始化成功完成，一定手动保存完成后的界面信息
```

```powershell
如果执行失败，可以执行下面命令恢复后，再执上面命令
kubeadm reset
如果上面的命令执行失败，可以尝试强制清理集群残留
kubeadm reset --cri-socket=unix:///run/cri-dockerd.sock --force
```

```powershell
# 后续添加节点，若是 Master 节点，则执行此指令；（循序执行，切勿多台设备同时执行！）
kubeadm join kubeapi.wang.org:6443 --token a0y2x9.nbu1tnvpzr3n7uox \
        --discovery-token-ca-cert-hash sha256:507a91c05ed42a3e2c1d878d0d41d6a5c35b934389b1bebfce9f8796eb0352bb \
        --control-plane --certificate-key b4e2c1465d8bc44670f89d51f3303d1c33e1b3c6fd0fac8ccda0b0362e0d0049 --cri-socket=unix:///run/cri-dockerd.sock
# 后续添加节点，若是 worker 节点，则执行此指令（循序执行，切勿多台设备同时执行！）
kubeadm join kubeapi.wang.org:6443 --token a0y2x9.nbu1tnvpzr3n7uox \
        --discovery-token-ca-cert-hash sha256:507a91c05ed42a3e2c1d878d0d41d6a5c35b934389b1bebfce9f8796eb0352bb --cri-socket=unix:///run/cri-dockerd.sock
```

```powershell
# 做授权
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
# 在第一个 Master 中查看节点
kubectl get nodes
# 登录：http://10.0.0.100:8888/status	查看节点状态
# 账号密码：admin	123456
```

```powershell
# 依据初始化完成后的界面信息提示，进入 https://kubernetes.io/docs/concepts/cluster-administration/addons/ 解决网络搭建问题
# 点击 Flannel —— 会进入 https://github.com/flannel-io/flannel#deploying-flannel-manually 网站下载该插件
wget  https://github.com/flannel-io/flannel/releases/latest/download/kube-flannel.yml
# 下载后改一下名字，为了可视化整理（可选）
grep image: kube-flannel.yml
mv kube-flannel.yml kube-flannel-v0.27.4.yml 
# 执行 yml 文件，顺带着解决网络容器问题
kubectl apply -f kube-flannel-v0.27.4.yml
# 执行成功后，k8s 集群节点的状态就会变成 Ready 
# 查看执行过程
kubectl get pod -A
# 查看具体节点执行状态
kubectl get pod -A -o wide
```



#### containerd 安装（主流）

背景：前身是基于 docker 安装，k8s 通过 docker 调用 containerd ；为了压榨性能潜力将 docker 壳子去掉，只取 containerd 这个核心！

获得性能的同时，牺牲也是有的！部署更难一些！后期维护难度也会提高！

##### **部署环境：**

Ubuntu2404

| IP         | 主机名           | 角色                                       |
| ---------- | ---------------- | ------------------------------------------ |
| 10.0.0.101 | master1.wang.org | K8s 集群主节点 1，Master 和 etcd           |
| 10.0.0.102 | master2.wang.org | K8s 集群主节点 2，Master 和 etcd           |
| 10.0.0.103 | master3.wang.org | K8s 集群主节点 3，Master 和 etcd           |
| 10.0.0.104 | node1.wang.org   | K8s 集群工作节点 1                         |
| 10.0.0.105 | node2.wang.org   | K8s 集群工作节点 2                         |
| 10.0.0.106 | node3.wang.org   | K8s 集群工作节点 3                         |
| 10.0.0.107 | ha1.wang.org     | K8s 主节点访问入口 1，提供高可用及负载均衡 |
| 10.0.0.108 | ha2.wang.org     | K8s 主节点访问入口 2，提供高可用及负载均衡 |
| 10.0.0.100 | kubeapi.wang.org | VIP，在 ha1 和 ha2 主机实现                |

###### 准备工作

```powershell
# 按照规划配置修改主机名（唯一的主机名）
hostnamectl set-hostname master1
hostnamectl set-hostname master2
hostnamectl set-hostname master3
hostnamectl set-hostname node1
hostnamectl set-hostname node2
hostnamectl set-hostname node3
hostnamectl set-hostname ha1
hostnamectl set-hostname ha2


cat >> /etc/hosts <<'eof'
10.0.0.101 kubeapi.wang.org kubeapi master1
10.0.0.102 master2.wang.org master2
10.0.0.103 master3.wang.org master3
10.0.0.104 node1.wang.org node1
10.0.0.105 node2.wang.org node2
10.0.0.106 node3.wang.org node3
10.0.0.107 ha1.wang.org ha1
10.0.0.108 ha2.wang.org ha2
eof

ls /root/.ssh/id_rsa.pub &>/dev/null || ssh-keygen -t rsa
for host in 10.0.0.{102..106}; do
    ssh-copy-id -i /root/.ssh/id_rsa.pub -o StrictHostKeyChecking=no root@$host
done

for host in 10.0.0.{102..106}; do
    scp /etc/hosts root@$host:/etc/hosts
done

# 网卡配置中不要加search指令
sed -i '/search/d;/8\.8\.8\.8/d' /etc/netplan/50-cloud-init.yaml

#借助于chronyd服务（程序包名称chrony）设定各节点时间精确同步
apt -y install chrony
chronyc sources -v

# 测试：时间同步做完后，修改时间后，回自动校正到正确的时间；
date && date -s '-1 day' && sleep 1 && date

# 关闭防火墙，禁用 SELinux

# 禁用 Swap （swapoff -a 关闭所有 swap）
swapoff -a && sed -i '/swap/s/^/#/' /etc/fstab && free -h
# 或者
systemctl disable --now swap.img.swap;systemctl mask swap.target
# 检查指令；没有输出则证明关闭所有 swap （或者执行 free -h 看到 Swap 的空间使用为 0 就 ok 了）
swapon --show			

# 开机加载
cat > /etc/modules-load.d/k8s.conf <<'eof'
overlay
br_netfilter
eof
# 加载模块 （立即加载，否则重启主机才能生效）
modprobe overlay
modprobe br_netfilter
# 查看是否被加载
lsmod |grep -E 'overlay|br_netfilter'

# 设置所需的 sysctl 参数，参数在重新启动后保持不变
cat > /etc/sysctl.d/k8s.conf <<'eof'
net.bridge.bridge-nf-call-iptables = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward = 1
eof
# 应用 sysctl 参数生效而不重新启动
sysctl --system
```

###### Keepalived

```powershell
apt update && apt -y install keepalived

cat > /etc/keepalived/keepalived.conf <<'eof'
global_defs {
    notification_email {
        acassen
    }
    notification_email_from Alexandre.Cassen@firewall.loc
    smtp_server 192.168.200.1
    smtp_connect_timeout 30
    router_id ha1.wang.org   # 在 ha2 上为 ha2.wang.org
}

vrrp_script check_haproxy {
    #script "/etc/keepalived/check_haproxy.sh"
    script "killall -0 haproxy"
    interval 1
    weight -30
    fall 3
    rise 2
    timeout 2
}

vrrp_instance VI_1 {
    state MASTER              # 在 ha2 上为 BACKUP
    interface eth0
    garp_master_delay 10
    smtp_alert

    virtual_router_id 66      # ha1 / ha2 必须一致
    priority 100              # 在 ha2 上为 80
    advert_int 1

    authentication {
        auth_type PASS
        auth_pass 123123      # ha1 / ha2 必须一致
    }

    virtual_ipaddress {
        10.0.0.100/24 dev eth0 label eth0:1
    }

    track_script {
        check_haproxy
    }
}
eof

cat > /etc/keepalived/check_haproxy.sh <<'eof'
#!/bin/bash
/usr/bin/killall -0 haproxy || systemctl restart haproxy
eof
chmod +x /etc/keepalived/check_haproxy.sh
systemctl start keepalived.service ; systemctl status keepalived.service
hostname -I
```

```powershell
# 第二台服务器
cat > /etc/keepalived/keepalived.conf <<'eof'
global_defs {
    notification_email {
        acassen
    }
    notification_email_from Alexandre.Cassen@firewall.loc
    smtp_server 192.168.200.1
    smtp_connect_timeout 30
    router_id ha2.wang.org   # 在 ha2 上为 ha2.wang.org
}

vrrp_script check_haproxy {
    #script "/etc/keepalived/check_haproxy.sh"
    script "killall -0 haproxy"
    interval 1
    weight -30
    fall 3
    rise 2
    timeout 2
}

vrrp_instance VI_1 {
    state BACKUP              # 在 ha2 上为 BACKUP
    interface eth0
    garp_master_delay 10
    smtp_alert

    virtual_router_id 66      # ha1 / ha2 必须一致
    priority 80             # 在 ha2 上为 80
    advert_int 1

    authentication {
        auth_type PASS
        auth_pass 123123     # ha1 / ha2 必须一致
    }

    virtual_ipaddress {
        10.0.0.100/24 dev eth0 label eth0:1
    }

    track_script {
        check_haproxy
    }
}
eof
```

```powershell
# 两台设备都执行这个指令；绑定端口
cat >> /etc/sysctl.conf <<EOF
net.ipv4.ip_nonlocal_bind = 1
EOF

sysctl -p
```

###### Haproxy

```powershell
apt -y install haproxy

cat >> /etc/haproxy/haproxy.cfg <<'eof'
listen stats
    mode http
    bind 0.0.0.0:8888
    log global
    stats enable
    stats uri /status
    stats auth admin:123123


listen kubernetes-api-6443
    bind 10.0.0.100:6443
    mode tcp
    server master1 10.0.0.101:6443 check inter 3s fall 3 rise 3
    # 先暂时禁用 master2 和 master3，等 kubernetes 安装完成后再启用 (或者master节点装完后就可以启动)
    #server master2 10.0.0.102:6443 check inter 3s fall 3 rise 3
    #server master3 10.0.0.103:6443 check inter 3s fall 3 rise 3
eof

# 先暂时禁用master2和master3，等kubernetes安装完成后，再启用
systemctl restart haproxy ; systemctl status haproxy
# 浏览器查看： http://ha1.wang.org:8888/status     ha2.wang.org:8888/status    kubeapi.wang.org:8888/status
# 或者登录：http://10.0.0.100:8888/status
# 账号密码：admin	123123
```

###### Containerd

```powershell
# Ubuntu24.04，22.04和Ubuntu20.04可以利用内置仓库安装containerd
apt update && apt -y install containerd
# 如果对版本有要求！需要下载二进制包进行安装；下载地址：https://github.com/containerd/containerd

systemctl status containerd
containerd -v
runc -v

# 修改containerd配置基于toml(Tom's Obvious Minimal Language)格式：toml.io
mkdir /etc/containerd/
containerd config default > /etc/containerd/config.toml
sed -i "s#registry.k8s.io/pause:3.8#registry.aliyuncs.com/google_containers/pause:3.10.1#g" /etc/containerd/config.toml
sed -i 's#SystemdCgroup = false#SystemdCgroup = true#g' /etc/containerd/config.toml
# 镜像加速
vi /etc/containerd/config.toml
[plugins."io.containerd.grpc.v1.cri".registry.mirrors]
# 在上面这一行下面添加下面的加速配置；
    [plugins."io.containerd.grpc.v1.cri".registry.mirrors."docker.io"]
    endpoint = ["https://docker.m.daocloud.io","https://docker.1panel.live"]
    [plugins."io.containerd.grpc.v1.cri".registry.mirrors."harbor.wang.org"]
    endpoint = ["https://harbor.wang.org"]
    [plugins."io.containerd.grpc.v1.cri".registry.configs."harbor.wang.org".tls]
    insecure_skip_verify = true
    [plugins."io.containerd.grpc.v1.cri".registry.configs."harbor.wang.org".auth]
    username = "admin"
    password = "123123"

systemctl restart containerd
for i in {102..106} ; do scp -r /etc/containerd/ 10.0.0.$i:/etc/ ; done
systemctl restart containerd ; systemctl status containerd
```

###### K8s 软件源和 kubeadm

所有 master 和 node 节点安装kubeadm等相关包 

> 官方文档：https://kubernetes.io/zh-cn/docs/setup/production-environment/tools/kubeadm/install-kubeadm/#installing-kubeadm-kubelet-and-kubectl
>
> 国内指导文档：[https://developer.aliyun.com/mirror/kubernetes](https://developer.aliyun.com/mirror/kubernetes?spm=a2c6h.13651102.0.0.3e221b11fXyWDY)

```powershell
# 对k8s集群刷入下面的指令（指导文档获取的指令）
curl -fsSL https://mirrors.aliyun.com/kubernetes-new/core/stable/v1.34/deb/Release.key |
    gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
echo "deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://mirrors.aliyun.com/kubernetes-new/core/stable/v1.34/deb/ /" |
    tee /etc/apt/sources.list.d/kubernetes.list
apt-get update
# 安装指定版本（k8s集群节点都做此步骤）
K8S_RELEASE_VERSION=1.34.1 && echo $K8S_RELEASE_VERSION
apt install -y kubeadm=${K8S_RELEASE_VERSION}-1.1 kubelet=${K8S_RELEASE_VERSION}-1.1 kubectl=${K8S_RELEASE_VERSION}-1.1
# 查看
apt list kubeadm kubectl kubelet
```

###### 初始化

第一个 master 节点准备 k8s 的初始化

```powershell
# 实现 kubeadm 命令补全 （主要是在第一个master节点使用）
kubectl completion bash > /etc/profile.d/kubectl_completion.sh
source /etc/profile.d/kubectl_completion.sh
# 先定义 k8s 版本（变量）；然后开始第一个master节点的初始化（这一步很重要！）
K8S_RELEASE_VERSION=1.34.1 && echo $K8S_RELEASE_VERSION
# 初始化一个 HA Kubernetes 控制平面，设置 Pod/Service 网段，指定镜像源，开启多主集群证书共享，生成永不过期的 join token。
kubeadm init --kubernetes-version=v${K8S_RELEASE_VERSION} --control-plane-endpoint kubeapi.wang.org --pod-network-cidr 10.244.0.0/16 --service-cidr 10.96.0.0/12 --token-ttl=0 --image-repository registry.aliyuncs.com/google_containers --upload-certs 
初始化成功完成，一定手动保存完成后的界面信息
```

初始化回退

```powershell
systemctl stop kubelet && systemctl status kubelet
kubeadm reset -f && rm -rf /etc/cni/net.d && rm -rf /var/lib/cni
# 如实失败则手动回退
rm -rf /etc/kubernetes
rm -rf /var/lib/kubelet
rm -rf /var/lib/etcd
rm -rf /var/lib/cni
rm -rf /etc/cni/net.d
rm -rf ~/.kube
rm -rf /var/lib/containerd/io.containerd.grpc.v1.cri/*
systemctl stop kubelet
systemctl stop containerd
pkill -f kube-proxy
pkill -f flanneld
pkill -f kubelet
# 节点
kubectl delete node node1
# 可选
iptables -F
iptables -t nat -F
iptables -t mangle -F
iptables -X
ipvsadm -C	# 如果用的是 ipvs
# 最后确保这三个文件目录为空
ls /etc/kubernetes/manifests && ls /var/lib/etcd && ip a | grep cni
ss -tunlp | egrep '6443|10250|10256|8472' ; ps aux | grep kube
```

初始化成功后，后续操作

```powershell
# 做授权
mkdir -p $HOME/.kube
cp /etc/kubernetes/admin.conf $HOME/.kube/config
# 在第一个 Master 中查看节点
kubectl get nodes
# 登录：http://10.0.0.100:8888/status	查看节点状态
# 账号密码：admin	123456
```

```powershell
如果执行失败，可以执行下面命令恢复后，再执上面命令
kubeadm reset
如果上面的命令执行失败，可以尝试强制清理集群残留
kubeadm reset --cri-socket=unix:///run/cri-dockerd.sock --force
```

```powershell
# 后续添加节点，若是 Master 节点，则执行此指令；（循序执行，切勿多台设备同时执行！）
  kubeadm join kubeapi.wang.org:6443 --token j1hki3.tt1ouv8u6ey53t2k \
        --discovery-token-ca-cert-hash sha256:223044d974edf774752bcdee2a2097f5c241c2b4464b56149d8599d0c1d4c4d4 \
        --control-plane --certificate-key 8970a0ea38a226766cf622be9f36336b903f24bac32fc21df7e612f2b8d93218
# 后续添加节点，若是 worker 节点，则执行此指令（循序执行，切勿多台设备同时执行！）
kubeadm join kubeapi.wang.org:6443 --token ntlpcq.ah6cbssxakx9c58y --discovery-token-ca-cert-hash sha256:59f295053e6017ef2324c61d290e4f4d0652aad58fbd43f685e85ddc83b7f922 
```



```powershell
# 去掉注释,并重新加载配置文件
sed -i 's@#server@server@' /etc/haproxy/haproxy.cfg && systemctl reload haproxy
# 依据初始化完成后的界面信息提示，进入该网页接口解决网络搭建问题
https://kubernetes.io/docs/concepts/cluster-administration/addons/
# 点击 Flannel —— 会进入 https://github.com/flannel-io/flannel#deploying-flannel-manually 网站下载该插件
wget  https://github.com/flannel-io/flannel/releases/latest/download/kube-flannel.yml
# 下载后改一下名字，为了可视化整理（可选）
grep image kube-flannel.yml
mv kube-flannel.yml kube-flannel-v0.27.4.yml 
# 执行 yml 文件，直接跳过 OpenAPI 校验 （Calico 官方文档里也默认这么干）
kubectl apply -f kube-flannel-v0.27.4.yml  --validate=false
# 执行成功后，k8s 集群节点的状态就会变成 Ready 
# 查看执行过程
kubectl get pod -A
# 查看具体节点执行状态
kubectl get pod -A -o wide
```

```powershell
cat >> ~/.bashrc <<'eof'
export KUBECONFIG=/etc/kubernetes/admin.conf
eof
或者 (临时)
export KUBECONFIG=/etc/kubernetes/admin.conf
或者 （推荐）
cp /etc/kubernetes/admin.conf ~/.bashrc
```



```powershell
# flannel 与 calico （二选一）
wget https://raw.githubusercontent.com/projectcalico/calico/v3.27.0/manifests/calico.yaml

# 先定义 k8s 版本（变量）；然后开始第一个master节点的初始化（这一步很重要！）
K8S_RELEASE_VERSION=1.34.1 && echo $K8S_RELEASE_VERSION
# 初始化一个 HA Kubernetes 控制平面，设置 Pod/Service 网段，指定镜像源，开启多主集群证书共享，生成永不过期的 join token。
kubeadm init --kubernetes-version=v${K8S_RELEASE_VERSION} --control-plane-endpoint kubeapi.wang.org --pod-network-cidr 192.168.0.0/16 --service-cidr 10.96.0.0/12 --token-ttl=0 --image-repository registry.aliyuncs.com/google_containers --upload-certs 

# 下载后改一下名字，为了可视化整理（可选）
grep image calico.yaml
mv calico.yaml kube-calico-v3.27.0.yml 
# 执行 yml 文件，顺带着解决网络容器问题
kubectl apply -f kube-calico-v3.27.0.yml 
# 观察 Calico 组件起来没有
kubectl get pod -n kube-system
# 应该看到类似CNI 配置文件：10-calico.conflist
ls /etc/cni/net.d/
# 测试
kubectl run test1 --image=busybox -- sleep 100
kubectl run test2 --image=busybox -- sleep 100
kubectl exec -it test1 -- ping test2
# 执行成功后，k8s 集群节点的状态就会变成 Ready 
# 查看执行过程
kubectl get pod -A
# 查看具体节点执行状态
kubectl get pod -A -o wide
```



###### Containerd 客户端工具

containerd 的客户端工具有ctr,crictl和 nerdctl

```powershell
ctr image import docker镜像包
ctr image ls 
# nerdctl 功能更强大；下载地址如下：
wget https://github.com/containerd/nerdctl/releases/download/v2.2.0/nerdctl-2.2.0-linux-amd64.tar.gz
tar xf nerdctl-2.2.0-linux-amd64.tar.gz  && mv nerdctl /usr/local/bin/
nerdctl -n k8s.io ps
```

























#### 基于二进制安装

我愿称之为葵花宝典，自残式获得极致的性能！

Kubeasz 利用 Ansible 部署二进制 Kubernetes 高可用集群

> - 基于二进制方式部署和利用ansible-playbook实现自动化；
> - 下载地址：https://github.com/easzlab/kubeasz

##### 部署环境：

| 角色节点    | 数量 | 描述                                                     |
| ----------- | ---- | -------------------------------------------------------- |
| 部署节点    | 1    | 执行 ansible / etcdctl 命令，可以复用第一个 master 节点  |
| etcd 节点   | 3    | 注意 etcd 集群需要 1, 3, 5... 个节点，可以复用master节点 |
| master 节点 | 2    | 高可用集群至少需要 2 个 master 节点                      |
| node 节点   | n    | 执行应用负载的节点，可根据需求增加/减少节点数量          |



| IP         | 主机名                                        | 角色                                   |
| :--------- | :-------------------------------------------- | :------------------------------------- |
| 10.0.0.101 | [master1.wang.org](https://master1.wang.org/) | K8s 集群主节点 1，K8s 集群 etcd 节点 1 |
| 10.0.0.102 | [master2.wang.org](https://master2.wang.org/) | K8s 集群主节点 2，K8s 集群 etcd 节点 2 |
| 10.0.0.103 | [master3.wang.org](https://master3.wang.org/) | K8s 集群主节点 3，K8s 集群 etcd 节点 3 |
| 10.0.0.104 | [node1.wang.org](https://node1.wang.org/)     | K8s 集群工作节点 1                     |
| 10.0.0.105 | [node2.wang.org](https://node2.wang.org/)     | K8s 集群工作节点 2                     |
| 10.0.0.106 | [node3.wang.org](https://node3.wang.org/)     | K8s 集群工作节点 3                     |
| 10.0.0.100 |                                               | 独立安装部署节点                       |

##### 准备工作

- 由于部署节点与 Msater 主节点是分开的，所以对于 SSH 的免密认证，在两个主机重要做一遍，参数稍微调一调！

```powershell
主机名必须与 /etc/kubeasz/clusters/k8s-01/hosts 文件中的配置相对应
# 按照规划配置修改主机名（唯一的主机名）
hostnamectl set-hostname master-01
hostnamectl set-hostname master-02
hostnamectl set-hostname master-03
hostnamectl set-hostname worker-01
hostnamectl set-hostname worker-02
hostnamectl set-hostname worker-03

cat >> /etc/hosts <<'eof'
10.0.0.101 master1.wang.org master-01
10.0.0.102 master2.wang.org master-02
10.0.0.103 master3.wang.org master-03
10.0.0.104 worker1.wang.org worker-01
10.0.0.105 worker2.wang.org worker-02
10.0.0.106 worker3.wang.org worker-03
eof

# 在 master 主节点进行 SSH 免密认证
ls /root/.ssh/id_rsa.pub || ssh-keygen -t rsa
for host in 10.0.0.{101..106}; do
    ssh-copy-id -i /root/.ssh/id_rsa.pub -o StrictHostKeyChecking=no root@$host
done

for host in 10.0.0.{101..106}; do
    scp /etc/hosts root@$host:/etc/hosts
done
```

##### ezdown

```powershell
# 查看官方文档；（选择 edown 版本 ，每个版本有对应的部署文档）
https://github.com/easzlab/kubeasz/blob/master/docs/setup/mix_arch.md
# 下载 ezdown（注意：Kubeasz-3.6.3部署kubernetes-v1.29.0有bug，无法实现跨主机的Pod通信，Kubeasz-3.6.2无此问题）
export release=3.6.8
wget https://github.com/easzlab/kubeasz/releases/download/${release}/ezdown
# 添加权限
chmod +x ./ezdown
# 更换为阿里云的软件源
sed -i "s#mirrors.tuna.tsinghua.edu.cn#mirrors.aliyun.com#" ezdown
# 下载 kubeasz 代码、二进制、默认下载容器镜像到/etc/kubeasz目录并同时安装Docker，（更多关于 ezdown 的参数，运行./ezdown 查看）
./ezdown -D
# 查看加速配置 (docker 是自动下载好的！在这个 ezdown 3.6.8 版本中，加速的优化配置会自动生成)
docker info && cat /etc/docker/daemon.json
systemctl restart docker.service
# 查看下载启动的镜像和容器
docker ps && docker images
# 查看生成的 kubeasz 目录大小；
du -sh /etc/kubeasz/ ;
# 运行 ezdown 脚本，生成一个容器 kubeasz（用于安装k8s集群的工具）
./ezdown -S
# 查看~/.bashrc 文件应该包含：alias dk='docker exec -it kubeasz'
grep dk ~/.bashrc && source ~/.bashrc
# 创建新集群 k8s-01 ，建议使用alias命令 (两个命令二选一) (dk=docker exec -it kubeasz)
dk ezctl new k8s-01
docker exec -it kubeasz ezctl new k8s-01
# 修改 hosts 文件 （目前就改动这些参数；）
vi /etc/kubeasz/clusters/k8s-01/hosts
[etcd]
10.0.0.101
10.0.0.102
10.0.0.103
[kube_master]
10.0.0.101 k8s_nodename='master-01'
10.0.0.102 k8s_nodename='master-02'
10.0.0.103 k8s_nodename='master-03'
[kube_node]
10.0.0.104 k8s_nodename='worker-01'
10.0.0.105 k8s_nodename='worker-02'
10.0.0.106 k8s_nodename='worker-03'
[all:vars]
CLUSTER_NETWORK="calico"	# 建议用 calico，最稳定
# 修改 config.yml 配置文件 (目前不需要修改，本次实验不需要)
vi /etc/kubeasz/clusters/k8s-01/config.yml

# 查看启动步骤
dk ezctl help setup
# 开始安装 (all 全部安装)
dk ezctl setup k8s-01 all
# 查看节点状态（如果没有这个工具，重启终端窗口 ）
kubectl get nodes
# 查看当前 Kubernetes 集群中所有命名空间（Namespace）内 Pod 的状态。
kebectl get pod -A
# 查看组件启动状态（这个版本的playbooks会自动创建service配置文件）
systemctl  status kube-apiserver.service kube-scheduler.service kube-controller-manager.service kube-proxy.service
没有容器！所有 K8s 组件都是系统服务，都以 systemd service 的形式启动运行
```

回退步骤

```powershell
# 在所有 Master + Worker 节点执行：清理 K8s / CNI / CRI
systemctl stop kubelet
systemctl disable kubelet
systemctl stop containerd	# 本次实验不是基于 containerd 安装的，所以不需要执行这个步骤
rm -rf /etc/kubernetes		
rm -rf /var/lib/kubelet
rm -rf /var/lib/etcd
rm -rf /etc/cni
rm -rf /opt/cni
rm -rf /var/lib/cni
rm -rf /run/flannel
rm -rf /run/calico		# 删除 K8s 目录
# 在部署机（ubuntu-100）清理 kubeasz 环境
docker exec -it kubeasz sh
ezctl destroy k8s-01
rm -rf /etc/kubeasz/clusters
exit
```

```powershell
# 创建第二套集群 k8s-02 
dk ezctl new k8s-01
# 修改 hosts 文件 
vi /etc/kubeasz/clusters/k8s-02/hosts
# 修改 config.yml 配置文件 (目前不需要修改，本次实验不需要)
vi /etc/kubeasz/clusters/k8s-01/config.yml
# 开始一键安装
dk ezctl setup k8s-02 all
```



# Pod

## 基础概念

```bash
API = 集群提供给你的操作接口。所有 kubectl 都是在调用 API。
资源类型 = Kubernetes 世界里的“对象”，比如 Pod/Service/Deployment。
namespaced = 属于某个命名空间；cluster = 全集群资源，没有命名空间。
default 是默认名称空间，一切未加指定的增删改都是归为默认名称空间；
资源的创建方法：指令式（临时操作）；指令对象配置（手动部署）；声明式对象配置（生产环境首选，推荐）；
Pod = 业务容器（真正跑你的应用） + Pause 容器（基础设施容器）		# 所以说一个Pod中最少应该有两个容器；（一个容器没有意义；）
# Pod 内的业务容器负责跑应用；pause 容器作为 Pod 的基础容器，负责创建并维持网络和各类 Linux Namespace，是实现多容器共享环境的关键。
Kubernetes 里的 restart = 容器被删除后重新创建一个新的容器实例；（容器一旦退出，那么这个容器就没了，自然就没有重启这个概念！）
```

### Pod 状态

```powershell
kubectl get pod 的 STATUS 不是 Kubernetes 的真实状态，而是由 PodPhase + PodCondition + ContainerState 综合得出的可读结果。
真正排障必须看 describe 与 container 状态。
```

- PodPhase 是官方设计的“生命周期标准”，永远只有那 5 个；但实际状态更多，只能放在 ContainerState 或 Condition 里。
- Kubernetes 内置的 PodCondition 类型是固定的 4 个。 Kubernetes 允许扩展控制器为对象添加额外 Condition，因此数量不是完全锁死。
- 对Pod进行的三种策略管理： OnFailure，Never，和Always（默认）
  

#### Pod phase 状态

Pod Phase 用于描述 Pod 的高层生命周期

1. Pending（等待中）
   - Pod 已被 API Server 接收，但 **还没开始在节点上运行**。
   - 常见原因：调度还没有完成；镜像正在拉取，或者拉取太慢；
   - 总结：Pod 还在排队，还没有真正开始 run
2. Running（运行中）
   - Pod 已经调度到节点，并且 **至少一个容器正在运行或正要运行**。（可能部分容器是 Running，部分正在启动。）
   - 总结：Pod 在节点上实际运行；
3. Succeeded（成功）
   - Pod 的所有容器都成功退出，且 **退出码为 0**，并且不会被重启策略拉起（RestartPolicy=Never 或 OnFailure）。
   - 总结：任务型 Pod 正常跑完了！
4. Failed（失败）
   - Pod 内有容器异常退出，且 **退出码非 0** 或 RestartPolicy=Never 导致最终失败。
   - 常见原因：程序崩溃；启动探针失败；Liveness 反复失败导致重启到限制
   - 总结：Pod 运行失败。容器挂了！
5. Unknown（未知）
   - API Server **无法获取节点上的 Pod 状态**。
   - 通常是 kubelet 失联或者节点网络断连。
   - 总结：控制面和节点失联，Pod 状态无法确认。

#### Pod ContainerState

- Waiting：容器正在等待中
- Running：容器正常的运行状态
- Terminated：容器已经被成功的关闭了

#### PodCondition 状态

- **PodScheduled**：Pod 已被调度器分配到某节点。
- **Initialized**：所有 Init 容器已成功运行完毕。
- **ContainersReady**：所有业务容器的运行状态都为 Ready。
- **Ready**：Pod 整体可对外提供服务，Service 会将其加入负载列表。

#### 🧩 **总表：最常见状态的完整对应关系**

| 你看到的 STATUS（kubectl get pod）   | PodPhase（固定5种）               | PodConditions（4种固定类型）                                                    | ContainerState（Running/Waiting/Terminated） | 本质解释                           |
| ------------------------------ | ---------------------------- | ------------------------------------------------------------------------ | ------------------------------------------ | ------------------------------ |
| **Pending**                    | Pending                      | PodScheduled=True/False                                                  | Waiting                                    | Pod 还没准备好运行，可能在调度、拉镜像、init 未完成 |
| **ContainerCreating**          | Pending                      | PodScheduled=True                                                        | Waiting(reason=ContainerCreating)          | 容器正在创建（拉镜像、创建 rootfs、CNI 准备）   |
| **Init:0/1**（或 Init:N/M）       | Pending                      | Initialized=False                                                        | Waiting/Terminated                         | init 容器正在运行或失败                 |
| **Init:Error**                 | Pending                      | Initialized=False                                                        | Terminated(reason=Error)                   | init 容器失败                      |
| **Init:CrashLoopBackOff**      | Pending                      | Initialized=False                                                        | Waiting(reason=CrashLoopBackOff)           | init 容器反复启动失败                  |
| **Running**                    | Running                      | PodScheduled=True / Initialized=True / Ready=True / ContainersReady=True | Running                                    | Pod 运行正常                       |
| **Completed**                  | Succeeded                    | Ready=False                                                              | Terminated(reason=Completed)               | 所有容器成功退出（常见于 Job）              |
| **CrashLoopBackOff**           | Running（多数情况）                | Ready=False / ContainersReady=False                                      | Waiting(reason=CrashLoopBackOff)           | 主容器一直崩，Kubelet 反复重启            |
| **Error**                      | Failed                       | Ready=False                                                              | Terminated(reason=Error)                   | 容器异常退出                         |
| **ImagePullBackOff**           | Pending                      | Ready=False                                                              | Waiting(reason=ImagePullBackOff)           | 镜像拉取失败（认证、tag、仓库问题）            |
| **ErrImagePull**               | Pending                      | Ready=False                                                              | Waiting(reason=ErrImagePull)               | 镜像无法找到                         |
| **CreateContainerConfigError** | Pending                      | Ready=False                                                              | Waiting                                    | Pod 配置错误（环境变量、Mount 等）         |
| **Terminating**                | Running / Succeeded / Failed | Ready=False                                                              | Terminated                                 | Pod 正在删除（优雅退出阶段）               |
| **Unknown**                    | Unknown                      | 无法获取                                                                     | 无法获取                                       | 节点失联，K8s 获不来容器状态               |







#### 重启策略

Kubernetes 的 Pod 有三种重启策略，配置在 Pod Spec 中：

```powershell
restartPolicy: Always | OnFailure | Never
```

- Always（默认）：无论容器因为什么退出，都要重新启动容器。
- OnFailure：只有容器以非 0 状态码退出时，才重启。
- Never：容器退出后完全不重启，无论是否正常退出。

#### 镜像拉取策略

```powershell
imagePullPolicy: Always | IfNotPresent | Never
```

- Always（总是拉取）
  - 频繁更新镜像、开发环境。
  - 每次创建 Pod 都从镜像仓库重新拉取镜像。
  - 默认用于带 **:latest** 标签的镜像；保证镜像一定是最新
- IfNotPresent（本地有就不拉）
  - 适用于生产环境；
  - 本地存在就用本地镜像，不存在才从仓库拉取；
  - 默认策略（只要镜像不是 latest）
- Never（从不拉取）
  - 离线环境；
  - 只使用本地镜像，本地没有就报错。

### Pod 的三种健康检测探针

1. livenessProbe（存活探针）
   - 判断容器是否“活着”。
   - 失败 ⇒ kubelet 会 **重启容器**。
2. readinessProbe（就绪探针）
   - 判断容器是否“准备好对外提供服务”。
   - 失败 ⇒ **从 Service 负载列表中移除**，但不会重启容器。
3. startupProbe（启动探针）
   - 判断容器是否成功完成启动。
   - 适合启动慢的应用（Java、大型框架）。
   - startupProbe 成功 ⇒ 才开始执行 liveness 和 readiness。
   - 避免应用启动慢导致被 liveness 一直重启。

#### 探针的三种实现方式

- Exec
  - 直接执行指定的命令，根据命令结果的状态码$?判断是否成功，成功则返回表示探测成功
- HTTPGet
  - 根据指定Http/Https服务URL的响应码结果判断，当2xx, 3xx的响应码表示成功
- TCPSocket
  - 检查 TCP 端口能否建立连接



#### 配置案例

```powershell
cat > pod-liveness-tcpsocket.yaml
apiVersion: v1
kind: Pod
metadata:
  name: pod-liveness-tcpsocket
  namespace: default
spec:
  containers:
  - name: pod-liveness-tcpsocket-container
    image: registry.cn-beijing.aliyuncs.com/wangxiaochun/pod-test:v0.1
    imagePullPolicy: IfNotPresent
    ports:
    - name: http           #给指定端口定义别名
      containerPort: 80
    securityContext:  #添加特权，否则添加iptables规则会提示：getsockopt failed strangely: Operation not permitted
      capabilities:
        add:
        - NET_ADMIN
    livenessProbe:
      tcpSocket:
        port: http        #引用上面端口的定义
      periodSeconds: 5
      initialDelaySeconds: 5

kubectl apply -f pod-liveness-tcpsocket.yaml
kubectl get pod 
kubectl exec  pod-liveness-tcpsocket -- touch /test 
kubectl exec  pod-liveness-tcpsocket --  iptables -AINPUT -p tcp --dport 80 -j REJECT		# 设置过滤 80 端口拒绝规则
kubectl get pod -A		# 因为是基于监测80端口启动，对此设置拒绝规则，容器应该会一直重启；
kubectl exec  pod-liveness-tcpsocket -- ls /		# 重启后创建的文件应该不存在的（如果没有做持久化）
kubectl exec pod-liveness-tcpsocket -- iptables -vnL
kubectl pod-liveness-tcpsocket --iptables -F
```



- initialDelaySeconds：首次探测前等待时间（默认 0）

  - 作用：给应用预热时间，避免容器刚启动就被判定失败。

- periodSeconds：每次探测的时间间隔（默认 10s）

  - Pod 多时可以适当加大以降低 kubelet 压力。

- timeoutSeconds：探测超时（默认 1s）

  - 服务响应慢时要适当调大

- failureThreshold：连续失败几次判定为不健康（默认 3 次）

  - 举例：`periodSeconds=10`，`failureThreshold=3` → 至少失败 **30 秒** 才被认定为 unhealthy。

- successThreshold：连续成功几次才算健康

  - `livenessProbe` 和 `startupProbe` 固定只能是 1
  - readinessProbe 可大于 1（适合探测接口稳定性）

  

### Pod  服务质量 Qos

> QoS（Quality of Service）是 Kubernetes 用来判断 “当节点资源不够时，先保谁、先杀谁”的一套等级体系
> 👉 **QoS 不是性能优化**
> 👉 **QoS 是“活命优先级”**
>
> - QoS 不是手工配置的，是算出来的；
> - K8s 会根据 **Pod 中所有容器的 resources.requests / limits** **自动计算** QoS Class。
>   

**QoS 三个等级**

| QoS 等级       | 条件                           | 生存能力 |
| -------------- | ------------------------------ | -------- |
| **Guaranteed** | request == limit（CPU + 内存） | ⭐⭐⭐      |
| **Burstable**  | 有 request，但不完全等于 limit | ⭐⭐       |
| **BestEffort** | 没有 request、没有 limit       | ⭐        |

#### Guaranteed（最高优先级）

> 条件（非常严格）
>
> - **每个容器**
>   - CPU request = CPU limit
>   - 内存 request = 内存 limit
>
> 为什么生产常用？
>
> - 不被轻易驱逐
> - 性能稳定
> - 方便容量规划

“核心业务通常使用 Guaranteed QoS”

配置示例：

```powershell
resources:
  requests:
    cpu: "1"
    memory: "1Gi"
  limits:
    cpu: "1"
    memory: "1Gi"
```

👉 **这种 Pod 在资源紧张时最晚被杀**

#### Burstable（最常见）

> 条件
>
> - 设置了 request
> - 但 request ≠ limit 或只设置了其中一部分

配置示例：

```powershell
requests:
  cpu: "500m"
  memory: "512Mi"
limits:
  cpu: "2"
  memory: "2Gi"
```

👉 **可以“爆发”，但不是铁饭碗**；（Pod 无法正常运行；重启次数增加）

#### BestEffort（最低）

> 条件
>
> -  什么资源都没有分配

配置示例：

```powershell
resources: {}
```

👉 **节点一紧张，先死的就是它**

#### 总结

##### 情况一：不写 resources

```powershell
resources: {}
```

👉 结果：

- QoS = BestEffort
- 节点压力大时 **第一个被杀**

##### 情况二：内存打爆

```powershell
limits:
  memory: "64Mi"
```

👉 在容器里压内存
 结果：

- Pod 状态：`OOMKilled`
- 重启次数增加

##### 情况三：CPU 限流

```powershell
limits:
  cpu: "50m"
```

👉 结果：

- Pod 不死
- 响应明显变慢

##### 情况四：requests 过大

```powershell
requests:
  memory: "8Gi"
```

👉 结果：

- Pod Pending
- 原因：**无节点满足 requests**

##### 资源问题的标准排错流程

> 1️⃣ `kubectl get pod` → 状态
>  2️⃣ `kubectl describe pod`
>
> - 看 Events
> - 看 OOM / Evicted
>    3️⃣ 看 resources 配置
>    4️⃣ 看 Node 资源
>    5️⃣ 判断是：
> - requests 太大？
> - limits 太小？
> - 节点压力？

```powershell
# kubelet 会根据 Pod 的 QoS，自动设置容器进程的 oom_score_adj
cat /proc/4321/oom_score_adj
# QoS 是策略，oom_score_adj 是杀戮容器的刀。
```



### Pod 资源限制

- scheduler **只看 requests**
- requests 决定：Pod 能不能被调度

| 资源   | 超 limit 行为          |
| ------ | ---------------------- |
| CPU    | 被限流（变慢，不会死） |
| Memory | OOMKill（直接杀）      |

> 提示:为保证性能,生产推荐Requests和Limits设置为相同的值
>
> 要实现资源限制,需要先安装metrics-server
>
> 官方链接：https://github.com/kubernetes-sigs/metrics-server
>
> 安装 metrics-server
>
> ```powershell
> # 建议安装metrics-server,可以通过dashboard查看更多的信息,此步可选
> wget https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml
> # 默认文件需要修改才能工作,因为默认需要内部证书验证和镜像地址k8s.gcr.io所以修改
> vim components.yaml
>         - --metric-resolution=15s
>         - --kubelet-insecure-tls # 添加本行和下面一行
>         image: registry.cn-hangzhou.aliyuncs.com/google_containers/metrics-server:v0.7.2
>         # image: registry.k8s.io/metrics-server/metrics-server:v0.8.0		# 将此行注释
> # 应用此文件
> kubectl apply -f components.yaml
> # 查看资源
> kubectl api-resources | wc -l
> # 查看性能信息
> kubectl top nodes
> ```
>
> 资源限制实现
> limits（上限）必须大于等于requests（下限），否则报错；
>
> 在生产中上限和下限不要设置，要设也要一样！
>
> 如果下限内存大于物理实际内存，则会导致pending；（上限超出物理实际内存不影响）
>
> ```powershell
> cat > pod-limit-request.yaml
> apiVersion: v1
> kind: Pod
> metadata:
>   name: pod-limit-request
> spec:
>   containers:
>   - name: pod-limit-request-container
>     image: registry.cn-beijing.aliyuncs.com/wangxiaochun/nginx:1.20.0
>     imagePullPolicy: IfNotPresent
>     resources:
>       requests:
>         memory: "1000Mi"
>         cpu: "500m"
>       limits:
>         memory: "1000Mi"
>         cpu: "500m"
> 
> # 修改yaml文件，将下限内存超过实际物理内存（测试）
> kubectl apply -f pod-limit-request.yaml
> kubectl get pod
> kubectl describe pod pod-limit-request
> kubectl delete -f pod-limit-request.yaml
> # 删除限制
> kubectl delete limitranges limit-mem-cpu-per-container
> # 查看资源限制仍然存在
> kubectl describe pod pod-limit-request.yaml
> ```
>
> 每个节点默认设置最多运行110个pod；但是正常来说一个节点运行几十个

Pod 资源限制只有两个维度：

- CPU
- Memory

每个维度又有两个参数：

| 参数         | 含义         | 关键作用                  |
| ------------ | ------------ | ------------------------- |
| **requests** | 最低资源需求 | 决定 Pod 能否被调度到节点 |
| **limits**   | 最大资源上限 | 决定 Pod 能使用多少资源   |

#### 配置示例

```powershell
apiVersion: v1
kind: Pod
metadata:
  name: demo
spec:
  containers:
  - name: app
    image: busybox
    resources:
      requests:
        cpu: "100m"     # 0.1 核
        memory: "128Mi" # 保证至少分到这么多
      limits:
        cpu: "500m"     # 最大 0.5 核
        memory: "256Mi" # 超了就 OOMKilled
```

####   

#### CPU 和内存限制的实现原理

Kubernetes 自己不控制资源，**kubelet 调用 Linux CGroup 来限制**。

  1）**CPU 限制的实现（CGroup）**

Kubernetes 对 CPU 的限制通过：

- `cpu.shares`
- `cpu.cfs_quota_us`
- `cpu.cfs_period_us`

实现：

| 参数                              | 作用                    |
| --------------------------------- | ----------------------- |
| **requests.cpu → cpu.shares**     | 保证争抢 CPU 时的权重   |
| **limits.cpu → cpu.cfs_quota_us** | 强制限制使用的 CPU 时间 |

举例：
 `limits.cpu = 0.5` 核 → kubelet 设置：

```
cpu.cfs_quota_us = 50000
cpu.cfs_period_us = 100000
```

意思是：
 每 100ms，只能使用 50ms CPU。

**→ CPU 不会被杀，只会被限速（throttle）。**

2）**Memory 限制的实现（CGroup）**

通过：

- `memory.limit_in_bytes`
- `memory.soft_limit_in_bytes`

实现。

| 参数                             | 作用                       |
| -------------------------------- | -------------------------- |
| **requests.memory → soft limit** | 优先保障分配，但不是硬限制 |
| **limits.memory → hard limit**   | 达到就 OOMKilled           |

内存超出 limit：

- Linux 内核 OOM Killer 介入
- 容器被杀
- K8s 标记为 `OOMKilled`

**→ 内存不会被限速，是“撞线就死”。**

####   

------



#### LimitRange

1）限制最小/最大资源

如果用户提交的 Pod 违反 LimitRange：

- 超过 max → 拒绝创建
- 小于 min → 拒绝创建

2）自动补全默认资源

当用户没有写 requests/limits：

- default → 自动填到 limits
- defaultRequest → 自动填到 requests

生产极常见：

> 防止业务方提交一个 “全空资源” 的 Pod，导致把节点打满。  

生产工作中的规范

1）所有生产命名空间必须设置 LimitRange + ResourceQuota

理由：

- 防止容器空配置吃掉整个 node
- 防止某业务无限制创建 Pod
- 避免 CPU 被暴力抢占

2）CPU 与内存必须成对出现

3）requests ≈ limits 的比例；略

4）内存要保守，CPU 要宽松



### Pod 经典设计模式

#### 单容器 Pod

（最常见、最推荐）

> 默认选择，90% 场景用它。
>
> 

#### Sidecar 模式

（面试 + 实战双高频 ⭐）

> 结构：
>
> ```powershell
> Pod
> ├── 主业务容器
> └── Sidecar 容器
> ```
>
> - 设计理念：给主容器“外挂一个功能”， 但不改主容器代码；
> - 典型用途：日志收集（filebeat）；代理（Envoy）；配置热更新；安全 / 证书
> - 为什么放同一个 Pod？
>   - 共享 IP / localhost
>   - 共享 Volume
>   - 生命周期绑定
>
> 👉 **这是 Pod 设计的灵魂模式**

#### Ambassador 模式

（Sidecar 的特化）

> 结构：
>
> ```powershell
> Pod
> ├── 业务容器
> └── Ambassador（代理）
> ```
>
> - 设计理念：把“访问外部服务的复杂性”代理掉；
>   - 例如：TLS、认证、限流 
>   - 业务容器只连 `localhost`；外部细节全部在代理里

#### Adapter 模式

（接口转换器）

> 结构：
>
> ```powershell
> Pod
> ├── 应用容器
> └── Adapter 容器
> ```
>
> - 设计理念：把应用的输出“改成平台想要的格式”
> - 典型应用：业务日志 → 统一日志格式；自定义指标 → Prometheus
>
> 👉 **应用不改，平台一致**

#### 边车容器 yaml 注意事项

- 边车业务单一，职责清晰；不推荐 "万能边车" ；
- Sidecar 与主容器的“强耦合点” ；主容器写日志，Sidecar 只读采集；
- Sidecar 与 Pod 终止顺序是“同时”的；日志 Sidecar 要能处理 SIGTERM；envoy 要支持优雅下线
- 资源限制非常关键（很多人会漏）；每个容器都有 `requests / limits`；Sidecar **资源明显小于业务容器**

- Sidecar 数量控制
  - 1 个：理想
  - 2 个：常见
  - ≥3 个：要非常谨慎

边车容器 yaml 文件示例：

```powershell
apiVersion: v1
kind: Pod
metadata:
  name: sidecar-test
spec:
  containers:
  - name: proxy
    #image: envoyproxy/envoy-alpine:v1.14.1
    image: registry.cn-beijing.aliyuncs.com/wangxiaochun/envoy-alpine:v1.14.1
    command: ['sh', '-c', 'sleep 5 && envoy -c /etc/envoy/envoy.yaml']
    lifecycle:
      postStart:
        exec:
          command: ["/bin/sh","-c","wget -O /etc/envoy/envoy.yaml http://www.wangxiaochun.com:8888/testdir/kubernetes/envoy.yaml"]
  - name: pod-test
    image: registry.cn-beijing.aliyuncs.com/wangxiaochun/pod-test:v0.1
    env:
    - name: HOST
      value: "127.0.0.1"
    - name: PORT
      value: "8080"
```



## Pod 创建



#### 标签管理

```powershell
# 查看所有的标签
get pods --show-labels
# 查看指定标签的资源
kubectl get pods -l label_name[=label_value]
# 创建一个有label的自主式pod
kubectl run pod-label-nginx --image=wangxiaochun/nginx:1.20.0 -l "app=nginx,env=prod"
# 添加新label
kubectl label pod pod-label-nginx release=1.20.0 role=web
# 修改label,需要加 --overwrite 选项
kubectl label pod pod-label-nginx role=proxy --overwrite
# 删除label
kubectl label pod pod-label-nginx role- release-pod/pod-label-nginx labeled
```

控制器不认 Pod 名字，只认 Label。

> 不管是：
>
> - Deployment
> - ReplicaSet
> - StatefulSet
> - Job
>
> 它们都靠：
>
> ```powershell
> spec:
>   selector:
>     matchLabels:
> ```
>
> 来决定：👉 **“哪些 Pod 是我该管的”**
>
> Deployment 是怎么管理 Pod 的？
>
> 通过 label selector 关联 Pod 和 ReplicaSet

Selector 一旦创建，不能改；改了 = 重建资源



#### 概念

> - Pod 从来不应该被人直接管理
> - Pod 是一次性消耗品，控制器才是长期管理者
>
> 控制器的本质：持续对比「期望状态」和「当前状态」，并不断修正；
>
> 逻辑概念结构：
>
> ```powershell
> 用户声明期望状态
> ↓
> 控制器循环对账
> ↓
> 实际状态 ≠ 期望状态 → 修正
> ```



## 创建流程

- Pod 的容器运行时只要符合CRI标准即可,而非必须为Docker；
- 每个Pod中的容器依赖于一个特殊名为pause容器事先创建出可被各应用容器共享的基础环境；
  - 包括 Network、IPC和UTS名称空间共享给Pod中各个容器；
  - Mount和User是不共享的,每个容器有独立的Mount,User的名称空间
  - PID名称空间也可以共享，但需要用户显式定义；

![image-20251211193304830](https://cdn.jsdelivr.net/gh/duanxueli08-cell/Obsidian-Images@main/img/image-20251211193304830.png)

##### 口述：

```python
# Pod 创建流程

用户通过 kubectl 发起创建 Pod 的操作，API Server 接收到请求后，会先把这个 Pod 的信息写入 etcd。
etcd 写入成功后，API Server 就认为这条创建请求已经提交完成。

接下来，Scheduler 会通过监听（Watch）API Server 的变化，发现有一个新的 Pod 还没有被调度，于是开始挑选最合适的节点。选好节点后，Scheduler 把“这个 Pod 应该由哪个节点来运行”的结果再写回 API Server。

各个节点上的 kubelet 也会一直监听 API Server。当某个 kubelet 发现“这个 Pod 被调度到我这个节点了”，它就会调用 containerd 来执行实际的创建动作：拉镜像、创建容器、设置网络等工作。

容器启动之后，kubelet 会不断获取 Pod 的真实运行状态，并把这些状态同步给 API Server。API Server 再把最新状态更新到 etcd。
最终，用户通过 kubectl 查询时，就能看到 Pod 正在怎样运行，这些信息全部来自 etcd 中的最新状态。
```



```bash
# 列出 当前 Kubernetes 集群里所有可用的 API 资源类型
kubectl api-resources
# 查看所有名称空间的资源（或者指定名称空间进行查看：kubectl get pod -n kube-system）
kubectl get pod -A
# 在 kube-flannel 这个命名空间里，查看 pod 资源类型名为 kube-flannel-ds-8jvfj 的 Pod 完整 YAML 数据。
kubectl get pod -n kube-flannel kube-flannel-ds-8jvfj -o yaml
# 查询 Kubernetes API 对指定资源 pod 指定字段 metadata 的说明文档
kubectl explain pod.metadata
# 列出整个 Kubernetes 集群里所有的 Namespace 
kubectl get ns
# 模拟创建一个名为 duan 的 Namespace，将生成的 YAML 输出到 duan.yaml 文件中：
kubectl create ns duan -o yaml --dry-run=client > duan.yaml
# 会根据该 YAML 在集群中创建一个名为 duan 的 Namespace。（上面相当于是模拟，这个相当于是实践！）
kubectl apply -f duan.yaml
# 删除名称空间，那么名称空间中的资源都会消失
kubectl delete ns duan
# 关闭 pod （默认 gracePeriodSeconds = 30 秒）
kubectl delete pod xxx --grace-period=5

查看排错原因：
kubectl get pod 名称 -o yaml
kubectl describe pod（类型） name名称 
kubectl logs pod名称 容器名称

Pod 起不来的排查思路；如何查看报错日志？
Pod 基本原理和工作机制
Pod 创建流程（手工创建、自动创建）
Pod 启动与关闭的流程
# Pending 状态的原因？
requests 不满足；
网络附件没安装；

# hook 钩子，可以在启动或者退出前做一些动作！
kubectl exec -it pot-poststart -- sh
kubectl exec pod-poststart -- ls
docker logs 
kubectl logs pod-poststart

pod 重启策略；三个
always （推荐）
pod 镜像拉取策略；三个
ifnotpresent 默认值；如果本地没有镜像，则拉取镜像；


```

清单格式

```powershell
# 资源类型写入配置文件中，格式：首字母大写，其余小写。 
# k8s 启动会自动检索这个文件夹下的yaml格式的清单文件
ls /etc/kubernetes/manifests/
# YAML 数据的五个字段，在 Kubernetes 的 任意资源对象里都能看到，是最核心的结构：apiVersion  kind  metadata  spec  status
apiVersion		# 这个资源属于哪个 API 版本；用哪个 API 版本解析
kind			# 资源类型；你声明的是哪种资源
metadata		# 对象的元数据（名字、标签、注解、namespace 等）。它不会影响业务逻辑，但非常关键
spec			# 资源的“期望状态”（你想要它变成怎样）spec 是人为设定的，告诉 K8s：我要它这样运行。
status			# 资源的“实际状态”（当前真实情况）。spec 是你“想要怎样”，status 是 K8s “当前是什么样”。
```









Pod 
静态；（不推荐）
自助式；（不具有故障自愈的能力，不推荐）
由workload controller 管控的pod；

kubectl get pod
kubectl get pod -n 名称
kubectl delete 
kubectl get pod -A
kubectl get pod -A -o wide
--dry-run



`kubectl` 的所有命令，本质上可以分成 **三大类**。这是学习 Kubernetes 必须掌握的基础结构，我给你讲得直接又清晰。

------

# 

**1. 查询类（查看资源）**

- `kubectl get` —— 获取资源列表
- `kubectl describe` —— 查看资源详情
- `kubectl logs` —— 查看容器日志
- `kubectl top` —— 查看资源使用情况
- `kubectl explain` —— 查看字段说明

------

**2. 操作类（增删改资源）**

- `kubectl create` —— 创建资源
- `kubectl apply` —— 应用配置（最常用：声明式）
- `kubectl delete` —— 删除资源
- `kubectl edit` —— 直接编辑现有资源
- `kubectl replace` —— 替换资源
- `kubectl scale` —— 扩缩容
- `kubectl rollout` —— 管理发布

------

**3. 调试类（排查问题）**

- `kubectl exec` —— 进入容器执行命令
- `kubectl cp` —— 在 Pod 与主机之间拷贝文件
- `kubectl port-forward` —— 转发端口调试服务
- `kubectl attach` —— 附加到正在跑的容器
- `kubectl debug` —— 调试 Pod（新版）

## 

------

Pending 原因

- requests 不满足；
- 网络附件没安装；



#### Pod 启动流程

🧠 总体一句话

> **用户下命令 → APIServer 记账 → Scheduler 选节点 → kubelet 真干活 → 容器跑起来**

下面拆开说。

------

① 用户提交 Pod（起点）

```bash
kubectl apply -f pod.yaml
```

发生了什么：

- kubectl 把 **Pod 描述（yaml）** 发送给 **APIServer**
- 这一步 **只是“申请”**，还没运行

📌 此时：

- Pod 状态：`Pending`

------

② APIServer + etcd（只做两件事）

APIServer：

1. 校验 YAML 合法性
2. **把 Pod 信息存进 etcd**（数据库）

📌 关键点：

> **APIServer 不创建 Pod，只记账**

------

③ Scheduler 调度 Pod（选一个节点）

Scheduler 一直在干这件事：

> “有没有**还没分配节点**的 Pod？”

它会：

- 过滤节点（资源、污点、亲和性）
- 打分（谁最合适）
- 选出一个 Node

然后：

> 把 `spec.nodeName = nodeX` 写回 APIServer

📌 此时：

- Pod 状态：`Pending`
- 但已经 **确定在哪台机器跑**

------

④ Node 上的 kubelet 接管（关键角色）

每个 Node 上都有 kubelet，它会：

1. 监听 APIServer

2. 发现：

   > “咦？有个 Pod 要我来跑”

然后开始真正干活。

------

⑤ kubelet 创建 Pod 环境（先搭地基）

顺序非常重要：

1. 创建 Pod 目录
2. 挂载 Volume
3. 创建 **Pause 容器**（核心）

📌 Pause 容器作用：

- 提供 Pod 的 **网络命名空间**
- Pod IP 就挂在它身上

> **Pod 先有 Pause，后有业务容器**

------

⑥ 运行 Init Containers（如果有）

Init 容器特点：

- **串行执行**
- 必须 **全部成功** 才能继续

用途：

- 初始化配置
- 等待依赖服务
- 准备数据

📌 如果 Init 容器失败：

- Pod 一直处于 `Init:Error`

------

⑦ 启动业务容器（主角登场）

Init 完成后：

- kubelet 启动 containers
- 通过 containerd / CRI

容器状态变化：

```text
Waiting → Running
```

- main container (业务容器) 启动的同时也会启动钩子 （如果有）
- 业务容器与启动钩子是同时进行的；

------

⑧ 健康检查 & Ready

如果定义了探针：（首先执行 startup probe 启动探针，然后才是 livenessProbe 与 readinessProbe ）

- livenessProbe（活着没）
- readinessProbe（能接活没）
- 启动探针在启动成功后就结束了，而 livenessProbe 和 readinessProbe 会伴随容器整个生命周期，直到 prestophook 钩子启动；

只有 readiness 成功后：

> Pod 才会被标记为 `Ready`

📌 Service 只会把流量打给 Ready 的 Pod

------

✅ Pod 启动完成标志

```bash
kubectl get pod
```

看到：

```text
STATUS: Running
READY: 1/1
```

代表：

> **Pod 真正可以对外服务了**

------

#### Pod 工作流程

🧠 一句话

> **kubelet 持续盯着，探针不断检查，出事就重启**

------

Pod 运行时的三件大事

1. **容器运行**（业务逻辑）
2. **探针检查**（健康）
3. **状态上报**（给 APIServer）

------

探针行为总结

| 探针           | 失败后会怎样              |
| -------------- | ------------------------- |
| livenessProbe  | kubelet 重启容器          |
| readinessProbe | Pod 变 NotReady，不接流量 |
| startupProbe   | 启动期保护 liveness       |

------

容器崩了会怎样？

取决于 **重启策略**：

| restartPolicy | 行为             |
| ------------- | ---------------- |
| Always        | 一直重启（默认） |
| OnFailure     | 失败才重启       |
| Never         | 不重启           |

------

#### Pod 关闭流程

🧠 一句话

> **先打招呼 → 给时间收尾 → 到点不走就强杀**

------

① 用户删除 Pod

```bash
kubectl delete pod xxx
```

APIServer：

- 给 Pod 打上 `deletionTimestamp`

📌 Pod 状态：

```text
Terminating
```

------

② kubelet 看到“要删了”

kubelet 开始执行 **优雅终止流程**。

------

③ 执行 preStop Hook（如果有）

如果 Pod 定义了：

```yaml
lifecycle:
  preStop:
```

kubelet 会先执行它。

常见用途：

- 下线通知
- 关闭连接
- flush 数据

------

④ 发送 SIGTERM 给容器

- 给主进程发 `SIGTERM`
- 等待退出

等待时间：

```yaml
terminationGracePeriodSeconds: 30
```

------

⑤ 超时还不退出？SIGKILL

如果超过时间：

- kubelet 直接 `SIGKILL`
- 容器被强制杀死

------

⑥ 清理资源

kubelet：

- 停止容器
- 删除网络
- 卸载 volume

APIServer：

- 从 etcd 删除 Pod 数据

------

你现在这个阶段，应该记住的 5 句话

1. **APIServer 只管记账，不干活**
2. **Scheduler 只选节点，不创建 Pod**
3. **kubelet 是真正干活的人**
4. **Pause 容器先于业务容器存在**
5. **Terminating 卡住 = 应用不肯退出**

------







# 控制管理

controller-manager 里面跑着很多控制循环（controller loop）：

- Deployment Controller
- ReplicaSet Controller
- DaemonSet Controller
- StatefulSet Controller
- Job Controller



#### ReplicaSet 

虽然它在 Deployment 后面，但它是底层的基石。

- **核心职责**：**保证副本数量**。
- **脾气**：它眼里只有数字。你告诉它要 3 个副本，多一个它就删，少一个它就补。它不关心版本，只关心数量。
- **侧重点**：**高可用**。只要 Pod 挂了，它立刻感知并拉起。

重点

> ReplicaSet 是 Kubernetes 中用于维持 Pod 副本数量的控制器，
> 通过 selector 匹配 Pod 标签进行管理。
> 它不支持滚动更新和版本管理，
> 主要作为 Deployment 的底层实现存在，
> selector 必须与 Pod 模板标签一致且不可变。

资源清单文件示例

```powershell
cat > controller-replicaset.yaml
apiVersion: apps/v1
kind: ReplicaSet
metadata:
  name: nginx-rs                # ReplicaSet 名称
  namespace: default             # 所属命名空间
spec:
  replicas: 3                    # 期望 Pod 副本数
  minReadySeconds: 10             # Pod 就绪后，至少稳定运行 10 秒才算 Ready

  selector:
    matchLabels:
      app: nginx                 # 必须和 template.metadata.labels 完全匹配

  template:
    metadata:
      labels:
        app: nginx               # ★ 关键：必须匹配 selector
    spec:
      containers:
        - name: nginx
          image: nginx:1.26
          ports:
            - containerPort: 80

kubectl apply -f controller-replicaset.yaml
# 删除一个Pod，RC又创建了一个Pod，证明Replication Controller的作用
kubectl delete pod controller-replicaset-test-c87m5
```

扩容：调整pod副本数量更多

```powershell
# 方法1:修改清单文件
vi controller-replicaset.yaml
spec:
  minReadySeconds: 0
  replicas: 4 #修改此行
```





#### Deployment

> 控制器体系总览：
>
> - 大部分控制器：不是直接管 Pod，而是“管另一个控制器”
>
> ```powershell
> Deployment
>    ↓ 管
> ReplicaSet
>    ↓ 管
> Pod
> ```

最全能的控制器，它是我们最常用的控制器，专门管理**无状态服务**。

- **核心职责**：管理 Pod 的版本更新、回滚和水平扩容。
- **套娃逻辑**：Deployment 并不直接管 Pod，它管的是 **ReplicaSet**。
  - `Deployment` -> `ReplicaSet` -> `Pod`
- **SRE 场景**：你要发布新版本（比如 Nginx 1.20 升级到 1.21），Deployment 会创建一个新的 RS，一点点把旧 RS 里的 Pod 挪到新 RS 里，这就是“滚动更新”。
- **侧重点**：**发布策略**（滚动更新、蓝绿部署）。



##### 简单实践

Deployment 负责创建 Pod，Service 负责提供访问。

无论是 Deployment 还是 Service，都通过标签选择器定位 Pod。

```powershell
命令行创建对象
kubectl create deployment deployment-pod-test --image=registry.cn-beijing.aliyuncs.com/wangxiaochun/pod-test:v0.1 --replicas=3
kubectl get all									 # 查看效果
kubectl describe deployment deployment-pod-test		# 查看 deployment 的详细过程

资源定义文件创建对象
cat controller-deployment-test.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: deployment-test
spec:
  replicas: 3
  selector:
    matchLabels:
      app: rs-test
  template:
    metadata:
      labels:
        app: rs-test
    spec:
      containers:
      - name: pod-test
        image: registry.cn-beijing.aliyuncs.com/wangxiaochun/pod-test:v0.1
# 应用资源定义文件
kubectl apply -f controller-deployment-test.yaml
kubectl get deploy
kubectl get rs
kubectl get pod -o wide

# 注意:创建deployment会自动创建相应的 RS 和 POD
# RS的名称=deployment名称+template_hash值
# 注意:Pod名=Deployment名+RS名的随机字符+Pod名的随机字符

# 将pod的80端口利用service发布出来
kubectl expose deployment deployment-pod-test --port=80
# 查看 service 资源中 deployment 的 clusterIP 
kubectl get svc

# 访问service的IP,可以看到随机访问到三个pod
curl 10.98.96.174 ; curl 10.98.96.174 ; curl 10.98.96.174
```

上述出现故障总结

**最初问题：** 宿主机无法访问 ClusterIP (`curl 10.98.96.174` 失败)。

> **根源诊断：** `kube-proxy` 日志中出现大量的 **`Unauthorized`** 错误。
>
> **核心原因：** 由于 Kubernetes 版本（v1.24+ 行为）或集群配置，`kube-system` 命名空间下的 `kube-proxy` ServiceAccount 缺少有效的 ServiceAccount Token，导致 `kube-proxy` 无法通过 RBAC 认证来访问 API Server，进而无法读取 Service 和 EndpointSlice 信息。

**最终解决方案：**

> - 使用 `kubectl create token kube-proxy -n kube-system --duration 8760h` **创建了一个有效的、有界限的 ServiceAccount 令牌**。
> - 通过 `kubectl rollout restart daemonset/kube-proxy -n kube-system` **强制 `kube-proxy` Pods 重启**。
> - 重启后，新的 `kube-proxy` Pods（`kube-proxy-kzhg8` 和 `kube-proxy-qr2ts`）成功地将新令牌作为 Projected Volume 挂载并使用。
>

**结果验证：**

> - 新的 `kube-proxy` 日志中**不再出现** `Unauthorized` 错误，它们成功同步了缓存并启动了 Proxier。
> - 宿主机 Master1 节点现在可以成功通过 ClusterIP `10.98.96.174` 访问后端 Pods (`192.168.166.133`, `134`, `135`)，并且可以看到流量在它们之间实现了 **负载均衡**。

| **特性**       | **旧版本 (≤ v1.23)**                               | **新版本 (≥ v1.24)**                                         |
| -------------- | -------------------------------------------------- | ------------------------------------------------------------ |
| **令牌类型**   | 永久 Secret (Legacy Secret)                        | 短期、有界限的令牌 (Bound Token)                             |
| **自动创建**   | **ServiceAccount 会自动创建** 对应的 Secret 令牌。 | **ServiceAccount 不会自动创建** 对应的 Secret 令牌。         |
| **Pod 挂载**   | 默认通过卷 (`Secret`) 自动挂载。                   | 默认通过 **投影卷 (`Projected Volume`)** 自动挂载短期令牌。  |
| **令牌有效期** | 永久有效，直到 Secret 被删除。                     | 有有效期（默认 1 小时），Pod 启动时获取，并会由 Kubelet 刷新。 |

```powershell
# 在 kube-system 命名空间中为 kube-proxy SA 创建一个令牌 Secret
kubectl create token kube-proxy -n kube-system --duration 8760h 
# 记下返回的TOKEN (这个TOKEN是新的SA Token，不是旧版本的Secret)
# 如果您的K8s版本不支持create token命令，请跳过此命令，执行下面的步骤
# 获取 kube-proxy DaemonSet 名称:
kubectl get ds -n kube-system
# 执行滚动重启 (强制更新配置):（假设 DaemonSet 名称为 kube-proxy）
kubectl rollout restart daemonset/kube-proxy -n kube-system
# 检查新的 kube-proxy Pod 状态和日志
kubectl get pod -n kube-system -l k8s-app=kube-proxy -o wide
# 查看日志，新的 kube-proxy Pod 名称
kubectl logs -n kube-system kube-proxy-kzhg8 ; kubectl logs -n kube-system kube-proxy-qr2ts
```



Deployment 管的是 ReplicaSet，不是 Pod；

> Deployment —— 管理无状态应用，支持滚动更新、回滚、扩缩容
>
> DaemonSet —— “每个节点一个”的代表；每个 Node 最多一个
>
> ```powershell
> Deployment
>  ├── ReplicaSet(v1)
>  ├── ReplicaSet(v2)
>  └── ReplicaSet(v3)
> ```
>
Deployment 的 5 大核心能力

> - ① 声明式发布（K8s 的灵魂）
>
>   - 只需要声明 **“我要什么状态”**；K8s 自动完成：创建新 RS、缩容旧 RS、对齐最终状态；
>   - Deployment 采用声明式管理，用户只描述目标状态。
>
> - ② 滚动更新（必须精通）
>
>   - ```powershell
>     strategy:
>       type: RollingUpdate
>       rollingUpdate:
>         maxUnavailable: 1
>         maxSurge: 1
>     ```
>
>   - | 参数           | 含义                                              |
>     | -------------- | ------------------------------------------------- |
>     | maxUnavailable | 封顶；更新期间可比期望的Pod数量能够多出的最大数量 |
>     | maxSurge       | 保底；更新期间可比期望的Pod数量能够缺少的最大数量 |
>
>     - 例子（replicas=3）：
>     - maxUnavailable = 1 ——>  最多4个Pod
>     - maxSurge = 1 ——>  最少2个Pod
>
>   - RS 不会滚动更新，Deployment 才会
>
> - ③ 版本管理 & 回滚（面试官最爱）
>
>   - Deployment 通过管理多个 ReplicaSet 实现版本控制和回滚。
>
>   - 常用命令（必须会）：
>
>     ```powershell
>     kubectl rollout status deploy nginx
>     kubectl rollout history deploy nginx
>     kubectl rollout undo deploy nginx
>     kubectl rollout undo deploy nginx --to-revision=2
>     ```
>
> - ④ 健康检查 + 发布安全（生产级）
>
>   - 滚动更新过程中，K8s 根据 readinessProbe 判断 Pod 是否可用。（即：以Pod是否能接收流量作为是否可用的判断标准！）
>
>   - 必学三件套：
>
>     ```powershell
>     livenessProbe:
>     readinessProbe:
>     startupProbe:
>     ```
>
>   - | 探针      | 决定什么     |
>     | --------- | ------------ |
>     | startup   | 是否启动成功 |
>     | liveness  | 是否需要重启 |
>     | readiness | 是否接收流量 |
>
> - ⑤ 扩缩容（手动 & 自动）
>
>   - Deployment 通过调整 ReplicaSet 的 replicas 实现扩缩容。
>
>   - 手动：
>
>     ```powershell
>     kubectl scale deploy nginx --replicas=5
>     ```
>
>   - 自动（必须理解）：
>
>     - HPA（Horizontal Pod Autoscaler）
>
>       基于：
>
>       - CPU
>       - Memory
>       - 自定义指标

Deployment YAML 必须熟的结构（能默写 80%）

- Deployment 的 selector **同样不可乱改**，但比 RS 宽容一点（创建时）。

```powershell
cat > controller-deployment-test.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: deployment-test
spec:
  replicas: 3
  selector:
    matchLabels:
      app: rs-test
  template:
    metadata:
      labels:
        app: rs-test
    spec:
      containers:
      - name: pod-test
        image: registry.cn-beijing.aliyuncs.com/wangxiaochun/pod-test:v0.1
```

Deployment 动态更新和回滚

```powershell
# 本地验证是否有该版本的软件
ctr image pull registry.cn-beijing.aliyuncs.com/wangxiaochun/pod-test:v0.1
# 创建Pod
kubectl apply -f controller-deployment-test.yaml
# 命令式更新镜像
kubectl set image deployment deployment-test pod-test=registry.cn-beijing.aliyuncs.com/wangxiaochun/pod-test:v0.2
# 查看 ReplicaSet (RS) 变化 【一个新的 RS（新的 image）；一个旧的 RS（逐渐缩到 0）】
kubectl get rs
# 看“现在这一轮发布进度”
kubectl rollout status deploy deployment-test
# 看“过去所有发布版本”
kubectl rollout history deployment deployment-test
# 回滚到上一个版本
kubectl rollout undo deploy deployment-test
# 将 Deployment 回滚到编号为 1 的历史版本。
kubectl rollout undo deploy deployment-test --to-revision=1
# 删除 Pod（验证 RS 自愈）
kubectl delete pod <deployment-test-pod>
# 查看 Deployment 详细信息
kubectl describe deploy deployment-test
# 查看 ReplicaSet 详细信息 （验证在 Pod 被删除后，RS 的 Current 和 Ready 副本数是否快速恢复。）
kubectl describe rs <rs-name>
# 查看 Pod 详细信息
kubectl describe pod <pod-name>

# 将pod的80端口利用service发布出来
kubectl expose deployment deployment-test --port=80
kubectl get svc
# 访问deployment-test service的IP,可以看到随机访问到三个pod
curl 10.106.18.27
```

Deployment 实现扩容缩容

```powershell
# 基于资源对象调整：
kubectl scale [--current-replicas=<当前副本数>] --replicas=<新副本数> deployment/deploy_name
# 基于资源文件调整:
kubectl scale --replicas=<新副本数> -f deploy_name.yaml
```

```powershell
# Pod 扩容
kubectl scale --replicas=5 deployment/deployment-test
kubectl get pod
kubectl get rs
# Pod 容量收缩 （用/和空格都可以！）
kubectl scale --replicas=3 deployment deployment-test
```

基于资源文件调整Pod数量

```powershell
# 修改 yaml 文件
vi controller-deployment-test.yaml
spec:
  replicas: 3		# 修改这一行内容
# 缩容
kubectl scale --replicas=1 -f controller-deployment-test.yaml
kubectl get pod
# 扩容
kubectl scale --replicas=3 -f controller-deployment-test.yaml
kubectl get rs
```

实际发生的是：

1. 修改 Deployment.spec.template.spec.containers[].image
2. Deployment 发现 Pod 模板变化
3. 创建 新的 ReplicaSet
4. 触发 滚动更新
5. 旧 RS 缩容，新 RS 扩容

至此 `set image` = 一次完整的滚动发布

> **必须做的实验**（非常重要）：
>
> - 故意写错端口
> - 看 rollout 卡住
> - 再修好，继续发布
>
> 👉 这是 Deployment 的灵魂。

清理环境

```powershell
kubectl delete deployment deployment-test
```



#### DaemonSet

```powershell
DaemonSet ——“节点级守护进程”	|	每个节点一个 Pod（或符合条件的节点一个）

Pod 数量 = 节点数

不是业务 Pod，是运维 Pod

典型用途：运维组件
比如：日志采集（fluentd / filebeat） | 网络插件（calico / flannel） | 监控 agent（node-exporter）

是否调度：自动
```

```powershell
kubectl get ds -A
kubectl get ds -n kube-system calico-node -o yaml 
```

| 参数           | 含义                                        |
| -------------- | ------------------------------------------- |
| maxUnavailable | 更新期间可比期望的Pod数量能够多出的最大数量 |
| maxSurge       | 更新期间可比期望的Pod数量能够缺少的最大数量 |



#### StatefulSet 

**核心职责**：管理 Pod 的**持久化身份**（稳定的网络 ID、稳定的存储）

**应用场景**：MySQL / Redis / Kafka / Zookeeper / Etcd

**有状态服务的特性总结：**

> - 身份持久化；
>- 数据持久化；
> - 操作有序性；
> - 数据一致性与同步；

`StatefulSet` 的工作机制

**稳定的网络标识**

> - 在 `Deployment` 中，Pod 的名字后面跟着一串随机字符，删了重开名字就变了。但在 `StatefulSet` 中，每个 Pod 都有一个从 0 开始的固定索引。
> - 定名称： 如果你定义 `replicas: 3`，Pod 永远叫 `web-0`, `web-1`, `web-2`。即便 `web-0` 挂了被重建，它回来还叫 `web-0`。
> - Headless Service： 配合一个 ClusterIP 为 None 的 Service；
> - **K8S 会为每个 Pod 生成一个 DNS 域名： `$(podname).$(service_name).$(namespace).svc.cluster.local`** 
>   运维意义： 像 Redis 集群或 ZooKeeper，节点之间需要互相通信，必须知道对方的“身份证号（域名）”，不能每次重启都变。

**稳定的持久化存储**

> - 这是 STS 最硬核的地方。它使用了 VolumeClaimTemplate（卷申请模板）。
> - 一对一绑定： 当 `web-0` 启动时，STS 会根据模板自动创建一个 PVC（比如 `data-web-0`）。
> - “房产”不随人走： 如果 `web-0` 调度到了机器 A，后来挂了漂移到机器 B，STS 会确保原来的 `data-web-0` 重新挂载到新的 Pod 上。
> - 数据安全： 默认情况下，当你删除 StatefulSet 时，为了安全，K8S 不会自动删除对应的 PVC。你需要手动清理，防止误删库跑路。

**严格的操作顺序**

> - 有状态集群通常有“主从”或“选举”逻辑，大家一起冲上去抢资源会出事。
> - 启动顺序： 按索引 0 到 N-1 顺序启动。只有 `web-0` 变成 Running 且 Ready 了，`web-1` 才会开始创建。
> - 更新策略（RollingUpdate）： 更新时则是逆序的。先删 `web-2`，等它更新好了，再动 `web-1`。这样能保证像 Elasticsearch 这样的集群在升级时，始终有足够的节点维持法线运行。
> - 级联删除： 删除时也是从后往前删。

为什么需要 Headless Service？

作为 SRE，要理解这层逻辑：普通的 Service 是做一个“负载均衡（VIP）”，把流量随机分给后端。但有状态服务（如 MySQL 主从）的流量是不能乱给的。

- 写操作得找 Master。
- 读操作可以找 Slave。 通过 Headless Service，客户端可以直接解析 DNS 拿到每一个 Pod 的具体 IP，实现精确打击。









#### Job

**核心职责**：负责执行**一次性任务**。只要容器内的进程退出码是 0，任务就结束了。

**进阶版 (CronJob)**：定时任务（像 Linux 的 crontab）。比如每天凌晨 3 点备份数据库。

```powershell
执行一次任务，成功就结束，不会长期存在
适用场景：脚本跑完就结束的活 ；数据初始化等一次性的活儿！
```

CronJob

```powershell
# 周期性创建 Job
schedule: "*/5 * * * *"

# 本质关系
CronJob
   ↓ 定时生成
Job
   ↓ 创建
Pod
```





#### Hook

由 kubelet 所设置的，在这里，我们称之为 pod hook；对于Pod的流程启动与关闭，主要有两种钩子：

- postStart，容器创建完成后立即运行；
- preStop，容器终止操作之前立即运行；在其完成前会阻塞删除容器的操作调用

> 钩子处理程序的日志不会在 Pod 事件中公开。 如果处理程序由于某种原因失败，它将播放一个事件。
> 对于 PostStart，这是 FailedPostStartHook 事件，对于 PreStop，这是 FailedPreStopHook 事件。
>
> 可以通过运行命令来查看这些事件： kubectl describe pod <pod_name> 

Poststart 钩子

实现方式：exec	httpGet	tcpSocket

实践演示

```powershell
# 创建 yaml 配置文件
cat > pod-poststart.yaml <<'eof'
apiVersion: v1
kind: Pod
metadata:
  name: pod-poststart
spec:
  containers:
  - name: busybox
    image: registry.cn-beijing.aliyuncs.com/wangxiaochun/busybox:1.32.0
    lifecycle:
      postStart:
        exec:
          command: ["/bin/sh","-c","echo lifecycle poststart at $(date) > /tmp/poststart.log"]
    command: ['sh', '-c', 'echo The app is running at $(date) && sleep 3600']
eof
# 启动文件
kubectl apply -f pod-poststart.yaml
# 查看pod资源
kubectl get pod
# 查看 /tmp/poststart.log 文件创建时间
kubectl exec pod-poststart -- ls /tmp/ -l
# 观察Pod启动时运行的命令和poststart定义的指令是同时执行的
kubectl logs pod-poststart
kubectl exec pod-poststart -- cat /tmp/poststart.log
# 清理环境
kubectl delete -f pod-poststart.yaml
```

> - `postStart` 是容器生命周期钩子，在 **容器刚启动后立即执行**；它不会阻塞容器主进程，但执行失败会导致容器失败（CrashLoopBackOff）
> - 第二个command 字段定义了主进程的启动命令；容器启动时打印一句话，然后睡 3600 秒（1 小时），防止容器立即退出！

Prestop 钩子

功能：实现pod对象移除之前，需要做一些清理工作，比如:释放资源，解锁等

实现方式：exec	httpGet	tcpSocket

实践演示：

```powershell
#由于默认情况下，删除的动作和日志我们都没有办法看到，那么我们这里采用一种间接的方法，在删除动作之前，给本地目录创建第一个文件，输入一些内容
cat > pod-prestop.yaml <<'eof'
apiVersion: v1
kind: Pod
metadata:
  name: pod-prestop
spec:
  volumes:
    - name: vol-prestop
      hostPath:
        path: /tmp
  containers:
    - name: prestop-pod-container
      image: registry.cn-beijing.aliyuncs.com/wangxiaochun/busybox:1.32.0
      volumeMounts:
        - name: vol-prestop
          mountPath: /tmp
      command: ['sh', '-c', 'echo The app is running at $(date) && sleep 3600']
      lifecycle:
        postStart:
          exec:
            command:
              - /bin/sh
              - -c
              - echo lifecycle poststart at $(date) > /tmp/poststart.log
        preStop:
          exec:
            command:
              - /bin/sh
              - -c
              - echo lifecycle prestop at $(date) > /tmp/prestop.log
eof
# 运行前确定所有节点目录文件列表
ls /tmp
# 启动Pod
kubectl apply -f pod-prestop.yaml
# 查看到此pod运行在哪个node节点上
kubectl get pod -o wide
# 查看这个node目录下生成文件
ls /tmp && cat /tmp/poststart.log
# 清理环境；删除pod
kubectl delete -f pod-prestop.yaml
```

> - postStart：容器刚启动，写入挂载到宿主机 `/tmp/poststart.log`
> - preStop：容器终止前，写入挂载卷 `/tmp/prestop.log`
> - 优雅退出流程顺序：
>   - kubelet 先执行 **preStop hook**
>   - 等 hook 执行完后发 SIGTERM
>   - 等待 terminationGracePeriodSeconds（默认 30s）
>   - 还没退出 → 发送 SIGKILL





串联知识

> **k8s 与 docker 的名称空间有什么区别?**

:star: Kubernetes 的 Namespace 是用来做集群资源的逻辑隔离，而 Docker 的 Namespace 是 Linux 内核提供的进程、网络、文件系统等运行环境的底层隔离技术，两者分别工作在管理层和内核层，完全不是同一层面的概念。

拓展：**Docker 六大空间（六大 Namespace）**

> 这六种加在一起，就构成了你看到的“一个独立容器”。
>
> K8s 的 namespace 是集群资源隔离；Nacos 的 namespace 是配置与服务隔离。

| Namespace   | 作用                   |
| ----------- | ---------------------- |
| **PID**     | 隔离进程号             |
| **UTS**     | 隔离主机名/域名        |
| **IPC**     | 隔离共享内存和消息机制 |
| **Mount**   | 隔离文件系统           |
| **Network** | 隔离网络               |
| **User**    | 隔离用户和用户组       |

拓展：**Docker 五种网络模型**

> Docker 有五种核心网络模式：bridge、host、none、container 和自定义 bridge。默认是 bridge；host 性能最好；none 完全隔离；container 共享网络栈；自定义 bridge 最实用且支持容器名互访；
>
> 大多数生产环境的单机容器都用自定义桥接网络模型，而不是默认 `bridge`；
>
> container 网络模型和 Kubernetes Pod 模型类似（多个容器共享 pause 的网络）。





# Service 服务发现

> 四种 service ：
>
> - clusterip
> - externalname
> - loadbalancer
> - nodeport

```powershell
ClusterIP 是 Kubernetes 集群内部访问 Pod 的稳定虚拟 IP，本身不转发流量，真正转发的是 kube-proxy 通过 iptables / ipvs 规则完成的。

ClusterIP 一个虚拟 IP ，只存在于 iptables / ipvs 规则里，由 kube-proxy 维护

客户端访问 Service ：curl http://10.96.100.10:80
这里的 10.96.100.10 是：Service 的 ClusterIP

kube-proxy 监听 Service / Endpoint 变化 → 写 iptables / ipvs 规则；

kube-proxy 不在数据转发路径上，它只负责维护转发规则。

kube-proxy 来到 k8s 集群就做三件事：监听 service、endpoint；计算哪个service到哪些pod后端；写入iptables、ipvs规则

Service 是一个“期望状态描述对象” ，描述三件事：一个稳定入口（ClusterIP）；选哪些 Pod（selector）；暴露哪些端口（ports）

Service 自己不存 Pod IP ，匹配 Pod label ，自动生成 Endpoint / EndpointSlice ，只靠 Endpoint 间接关联 Pod。

Service 只是：定义规则，生成 Endpoint ， Service 不负载均衡，iptables / ipvs 才负载均衡
```

```powershell
Pod Network： 实现集群内部任意 Pod 之间的互相通信。必须依赖 CNI 插件（如 Flannel, Calico, Weave Net 等）来实现这个扁平化的网络。 
Service Network： 为一组 Pods 提供一个稳定、不变的入口（Cluster IP），实现服务发现和负载均衡。
External Access：
Ingress（入站）： 允许外部用户访问集群内部的 Service。通常通过 NodePort、LoadBalancer 类型的 Service 或 Ingress Controller 来实现 L7 层的流量路由。
Egress（出站）： 允许集群内部的 Pods 访问外部互联网。这通常依赖宿主机（Node）的网络配置和 NAT。
```

service 实现

```powershell
# 三种方法
Userspace	# 已经淘汰
iptables	# 适用于中小规模，但不适用于大流量转发
ipvs		# 性能最好
# 查看当前实现 service 的方法 (默认是 iptables 规则)
curl 127.0.0.1:10249/proxyMode
```

##### 创建 cluster IP

kubectl create service clusterip 名称 --tcp 内部暴露的端口:Pod 实际端口

```powershell
kubectl run test1 --image=busybox -- sleep 500
kubectl label pod test1 app=myapp

kubectl create service clusterip myapp --tcp 88:80 --dry-run=client -o yaml		# 稳一手！看一下 selector 应该是 myapp
kubectl create service clusterip myapp --tcp 88:80							# 这里的 myapp 既是 svc 名称，也是标签
kubectl get svc
kubectl get endpoints
kubectl get pod --show-labels -o wide

# 如果有问题，使用 kubectl edit 修改 Service （保存，K8s 会立即应用更改。）
kubectl edit svc myapp
# 检查 Endpoints 是否已经自动更新
kubectl get endpoints myapp

# 在 kube-system 命名空间中为 kube-proxy SA 创建一个令牌 Secret
kubectl create token kube-proxy -n kube-system --duration 8760h 
# 记下返回的TOKEN (这个TOKEN是新的SA Token，不是旧版本的Secret)
# 如果您的K8s版本不支持create token命令，请跳过此命令，执行下面的步骤
# 获取 kube-proxy DaemonSet 名称:
kubectl get ds -n kube-system
# 执行滚动重启 (强制更新配置):（假设 DaemonSet 名称为 kube-proxy）
kubectl rollout restart daemonset/kube-proxy -n kube-system
# 检查新的 kube-proxy Pod 状态和日志
kubectl get pod -n kube-system -l k8s-app=kube-proxy -o wide
# 查看日志，新的 kube-proxy Pod 名称
kubectl logs -n kube-system kube-proxy-kzhg8 ; kubectl logs -n kube-system kube-proxy-qr2ts
```



##### Endpoint 

```powershell
Endpoint 是一个独立的 API 对象，由 controller-manager 中的 Endpoint Controller 维护

Endpoint 记录的是：某个 Service 当前实际可用的 Pod IP + Port 列表。

Endpoint 的局限性：当 Pod 很多时（比如 1000+）一个 Endpoint 对象会很大，etcd 压力大，kube-proxy 同步慢

EndpointSlice 把一个 Service 的后端 Pod 切成多个“切片”对象 | 最大 Pod 数 ：默认100 | 新版本 kube-proxy 优先监听 EndpointSlice
```



> Service 定义了 ClusterIP 和后端 Pod 选择关系，
> kube-proxy 将其转化为 iptables/ipvs 中的 DNAT 规则，
> 访问 ClusterIP 时，内核通过 DNAT 将流量改写为某个 PodIP:Port。

```powershell
Pod (app=nginx)
   │
   │ label 匹配
   ↓
Service (selector: app=nginx)
   │
   │ 自动生成
   ↓
Endpoint
   ├─ IP1:Port
   ├─ IP2:Port
   └─ IP3:Port 
```



```powershell
apiVersion: v1
kind: Service
metadata:
  name: nginx-svc
spec:
  selector:
    app: nginx
  ports:
  - port: 80        # Service 对外端口
    targetPort: 80  # Pod 容器端口
    
没有写 type，默认就是 ClusterIP
ClusterIP 会自动分配
selector 才是灵魂

kubectl get svc
kubectl get ep
kubectl describe svc
```

```powershell
Kubernetes 网络 = CNI 打地基 + kube-proxy 写转发规则 + NetworkPolicy 做安全控制

Flannel 解决“Pod 跨节点通信” ，让不同 Node 上的 Pod 能互相 ping 通

Calico 解决的不是“通信”，而是“控制通信” | Calico = 高性能网络 + 网络安全策略 | Calico 默认是 路由模式（BGP）

Calico 默认不做隧道，而是通过路由让 Pod IP 可达
```

```powershell
ClusterIP 是 Kubernetes 集群内部访问 Pod 的稳定虚拟 IP
NodePort 在每个节点上暴露一个端口（30000-32767），供集群外部访问内部 Pod，常用于测试。
ExternalName 用于将集群内 Pod 映射到集群外的服务或其他 Service，可理解为“别名服务”。
LoadBalancer 适用于集群部署在支持外部负载均衡器（LBaaS）的环境，为 Service 提供外部访问入口。需要第三方软件，简称 LB
```

| 类型         | 功能                                    | 访问范围       | 适用场景                   | 端口/备注                 |
| ------------ | --------------------------------------- | -------------- | -------------------------- | ------------------------- |
| NodePort     | 在每个节点暴露 Pod                      | 集群外部       | 测试、临时访问             | 30000-32767，可指定或随机 |
| ExternalName | 集群内 Pod 映射到外部服务或其他 Service | 集群内访问外部 | 做外部服务代理，“别名服务” | 无端口，由 DNS 解析       |
| LoadBalancer | 提供外部访问入口，通过外部 LB           | 集群外部       | 生产环境、正式服务         | 依赖云/LBaaS，自动创建 LB |



#### LoadBalancer

```powershell
LoadBalancer = NodePort + 集群外的 IP：Port
kubectl create svc loadbalancer myapp --tcp 88:80
kubectl get svc
```



#### MetalLB 实现 LBaaS 服务

> 下载地址：https://github.com/metallb/metallb
>
> 安装说明：https://metallb.universe.tf/installation
>
> MetalLB 是由 Google 开源提供, 当前属于 CNCF的 sandbox 项目
>
> MetalLB ：在「没有云厂商负载均衡器」的 Kubernetes 集群里，让 `Service type=LoadBalancer` 真的拥有一个“可从集群外访问的 IP”。
>
> LBaaS ≈ “我创建一个 Service，系统自动给我一个公网 / 可访问 IP，并帮我把流量转发到 Pod”

**设计图**

- 👉 MetalLB 只负责「进门」
- 👉 kube-proxy 才负责「分流」

```powershell
客户端
  ↓
MetalLB（ARP，把 IP 指向 Node）
  ↓
Node
  ↓
kube-proxy（iptables/ipvs）
  ↓
Service
  ↓
Pod
```

| 你做的事         | 实际意义                   |
| ---------------- | -------------------------- |
| strictARP        | 防止多个节点抢同一个 IP    |
| 安装 MetalLB     | 给 K8s 补 LB 实现          |
| IPAddressPool    | 告诉 MetalLB：哪些 IP 能用 |
| L2Advertisement  | 告诉局域网：IP 在哪台机器  |
| Service=LB       | 向系统“申请一个 LB”        |
| EXTERNAL-IP 出现 | MetalLB 接单成功           |
| curl 成功        | 全链路打通                 |



- 部署MetalLB 前准备

> - **如果 kube-proxy工作于ipvs模式，必须使用严格ARP（StrictARP）模式，因此若有必要，先运行如下命令，配置kube-proxy。**
> - 步骤说明：修改 `kube-proxy` 的配置：打开 `strictARP: true`
> - 作用：防止同一个 IP 被“多人认领”

```powershell
kubectl get configmap kube-proxy -n kube-system -o yaml | \
sed -e "s/strictARP: false/strictARP: true/" | \
kubectl apply -f - -n kube-system
kubectl rollout restart ds kube-proxy -n kube-system
```

- 部署 MetalLB 至 Kubernetes 集群
  - MetalLB 的两个核心组件


| 组件       | 干什么                       |
| ---------- | ---------------------------- |
| controller | 决定“哪个 Service 用哪个 IP” |
| speaker    | 在节点上发送 ARP / 宣告 IP   |

```powershell
METALLB_VERSION='v0.15.3'
wget https://raw.githubusercontent.com/metallb/metallb/${METALLB_VERSION}/config/manifests/metallb-native.yaml
kubectl apply -f metallb-native.yaml		# speaker 是 DaemonSet；意义是：每个节点都可能需要对外宣告 IP
kubectl get pods -n metallb-system
```

- 创建地址池

注意:：IPAddressPool **必须位于**

- 与Kuberetes集群节点 **同一二层网络**
- **但不能占用任何节点 / 网关 / DHCP 已使用的 IP**

```powershell
cat > service-metallb-IPAddressPool.yaml <<'eof'
apiVersion: metallb.io/v1beta1
kind: IPAddressPool
metadata:
  name: localip-pool
  namespace: metallb-system
spec:
  addresses:
  - 10.0.0.10-10.0.0.50
  # 这个地址池必须是在宿主机网段，但不能与宿主机冲突
  autoAssign: true
  avoidBuggyIPs: true
eof
```

- 创建二层公告机制
  - 配置意义：MetalLB 用哪种方式、在哪个接口上，对外宣告 IP


```powershell
cat > service-metallb-L2Advertisement.yaml <<'eof'
apiVersion: metallb.io/v1beta1
kind: L2Advertisement
metadata:
  name: localip-pool-l2a
  namespace: metallb-system
spec:
  ipAddressPools:
  - localip-pool
  interfaces:
  - eth0 				# 用于发送免费ARP公告
eof
```

```powershell
kubectl apply -f service-metallb-IPAddressPool.yaml && kubectl apply -f service-metallb-L2Advertisement.yaml
kubectl get svc
kubectl get IPAddressPool -n metallb-system
kubectl get all -n metallb-system
```

- 创建 Service 和 Deployment

创建 Deployment 和 LoadBalancer 类型的 Service，测试地址池是否能给 Service 分配 LoadBalancer IP

```powershell
# 创建Deployment和LoadBalancer类型的Service，测试地址池是否能给Service分配LoadBalancer IP
kubectl create deployment myapp --image=registry.cn-beijing.aliyuncs.com/wangxiaochun/pod-test:v0.1 --replicas=3
cat > service-loadbalancer-lbaas.yaml <<'eof'
apiVersion: v1
kind: Service
metadata:
  name: service-loadbalancer-lbaas
spec:
  type: LoadBalancer
  externalTrafficPolicy: Local
  selector:
    app: myapp
  ports:
  - name: http
    protocol: TCP
    port: 80
    targetPort: 80
eof
kubectl apply -f service-loadbalancer-lbaas.yaml
kubectl get ep
# 查看到分配了外部IP
kubectl get svc service-loadbalancer-lbaas -o wide
# 从集群外可以访问 (IP 地址视情况而定)
C:\Users\Administrator> curl 10.0.0.10
```





#### 待补充

coredns 配置；core DNS 工作机制，pod 的 DNS 解析策略和配置







##### Calico 

实操目标

- 用 Calico 的 NetworkPolicy 先把 Pod **全部锁死**
- 再 **只放行指定 Pod 的访问**

```powershell
kubectl run test1 --image=busybox -- sleep 500
kubectl run test2 --image=busybox -- sleep 500

cat > deny-all.yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: deny-all
  namespace: default
spec:
  podSelector: {}   # 选中 default 命名空间的所有 Pod
  policyTypes:
  - Ingress
  - Egress
# 应用
kubectl apply -f deny-all.yaml
# 验证：现在应该“全部断网” 
kubectl exec -it test1 -- sh
ping 8.8.8.8
```



```powershell
# 给 test2 打「server」标签；先给 Pod 打标签（非常关键）
kubectl label pod test2 role=server
# 给 test1 打「client」标签
kubectl label pod test1 role=client
# 确认标签
kubectl get pod --show-labels
# 放行规则：只允许 client 出去访问 server
cat > allow-client-egress.yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-client-egress
  namespace: default
spec:
  podSelector:
    matchLabels:
      role: client
  policyTypes:
  - Egress
  egress:
  - to:
    - podSelector:
        matchLabels:
          role: server

# 放行规则：只允许 client → server；只允许 test1 访问 test2
cat > allow-client-to-server.yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-client-to-server
  namespace: default
spec:
  podSelector:
    matchLabels:
      role: server
  policyTypes:
  - Ingress
  ingress:
  - from:
    - podSelector:
        matchLabels:
          role: client

# 应用
kubectl apply -f allow-client-to-server.yaml
kubectl apply -f allow-client-egress.yaml
# 验证：在 test1 中ping test2
kubectl exec -it test1 -- ping 192.168.166.130
# 验证：在 test2 中ping test1
kubectl exec -it test2 -- ping 192.168.166.129
# 列出 default 命名空间的所有网络策略
kubectl get networkpolicies

# 清空环境 （推荐这个方式）
kubectl delete -f deny-all.yaml
kubectl delete -f allow-client-egress.yaml
kubectl delete -f allow-client-to-server.yaml
```

#### Ingress

##### 背景

> 在 Kubernetes 中，Pod（容器）通常是内部运行的，不能直接从外部访问。要让外界可以访问这些 Pod，通常有三种方法：
>
> - **ClusterIP**：仅限集群内部访问。
> - **NodePort**：通过节点的 IP 和端口对外暴露服务。
> - **LoadBalancer**：通过云提供商的负载均衡器暴露服务。
>
> 但如果你没有云平台，想在本地实现负载均衡，**MetalLB** 是一种很好的解决方案。

> 什么是 Ingress ？
>
> - **Ingress** 是 Kubernetes 中用来管理外部访问集群内服务的资源。它充当了集群的入口，基于 HTTP 或 HTTPS 协议，可以根据请求的 URL 路由流量到不同的服务。Ingress 需要借助 **Ingress Controller** 来实际处理流量。
> - **Ingress** 本身只是一个**资源对象**（一段 YAML 配置），它规定了外部流量如何到达集群内部的服务。要让它起作用，必须配合 **Ingress Controller**（如 Nginx Ingress Controller）共同工作。
>
> 什么是 MetalLB？
>
> **MetalLB** 是一个 Kubernetes 的负载均衡插件，它可以在没有云负载均衡器的情况下提供类似的服务。MetalLB 通过配置 IP 地址池来为服务分配外部 IP 地址。它支持两种模式：
>
> - **Layer 2 模式**：通过 ARP 响应在局域网内自动将外部 IP 分配给节点。
> - **BGP 模式**：通过 BGP 路由协议进行 IP 地址的动态分配，适用于更复杂的网络环境。

> Ingress Controller 和 MetalLB 的结合
>
> - **MetalLB** 负责提供外部 IP 地址，使得 Kubernetes 集群可以暴露服务。
> - **Ingress Controller** 是负责解析 Ingress 资源的组件，比如 NGINX 、HAProxy 等。这个组件会监听 Ingress 资源，并根据规则将流量路由到相应的 Kubernetes 服务。
> - 二者配合使用时，**MetalLB** 提供外部访问入口，而 **Ingress Controller** 负责根据规则进行流量路由。

##### 工作原理

Ingress 的工作原理分为两部分：

> #### 第一部分：Ingress 资源（声明）
>
> 这就是你写的那个 YAML 文件（`kind: Ingress`）。它仅仅是存储在 etcd 数据库里的一条记录，定义了路由规则：
>
> - 域名是什么（host: example.com）
> - 路径对应哪个 Service（path: /test）
>
> #### 第二部分：Ingress Controller（实现）
>
> 这是一个运行在集群里的 **Pod**（通常是 Nginx、Traefik 或 HAProxy）。
>
> - 它的职责是 **“监听 (Watch)”**。
> - 它会不断询问 API Server：“有新的 Ingress 资源吗？”
> - 一旦发现有，它就会把 Ingress 里的规则翻译成 Nginx 配置，然后 reload 进程。
>
> ### 总结：Ingress 就是一个设计图纸，但是需要一个工程师部署，这个工程师就是控制器！Ingress Controller

##### 简单架构图

```powershell
[Client] --> [MetalLB (LoadBalancer)] --> [Ingress Controller (NGINX)] --> [Service A] (Pod1)
                                                              |
                                                              |----------> [Service B] (Pod2)
```

##### 安装部署

Ingress-nginx 有两种主要的部署方式：

- with **kubectl apply** , using YAML manifests
- with **Helm**, using the project repository chart

- **一定要看官方文档说明，查看该服务与 k8s 哪些版本兼容！**
- 下载链接：[kubernetes/ingress-nginx: Ingress NGINX Controller for Kubernetes](https://github.com/kubernetes/ingress-nginx/?tab=readme-ov-file)
- 指导文档：[Installation Guide - Ingress-Nginx Controller](https://kubernetes.github.io/ingress-nginx/deploy/)

###### 基于 kubectl apply 部署

```powershell
# 下载 YAML 文件
wget https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.14.1/deploy/static/provider/cloud/deploy.yaml
# 选择版本，添加变量
VERSION=1.14.1
# 查看资源
grep '^kind' deploy.yaml
修改文件
# 注释原来的镜像，添加国内镜像源；修改三处 image
image: registry.cn-hangzhou.aliyuncs.com/google_containers/nginx-ingress-controller:v1.14.1
image: registry.k8s.io/ingress-nginx/kube-webhook-certgen:v1.6.5
grep image: deploy.yaml

kubectl apply -f deploy.yaml
```

###### 创建 service Ingress

```powershell
# 准备环境实现两个 service 应用 pod-test1 和 pod-test2
kubectl create deployment pod-test1 --image=registry.cn-beijing.aliyuncs.com/wangxiaochun/pod-test:v0.1 --replicas=3
kubectl create service clusterip pod-test1 --tcp=80:80
kubectl create deployment pod-test2 --image=registry.cn-beijing.aliyuncs.com/wangxiaochun/pod-test:v0.2 --replicas=3
kubectl create service clusterip pod-test2 --tcp=80:80
# 查看
kubectl get svc,endpoints,po -o wide
# 创建 Ingress 规则 （不推荐）
kubectl create ingress ingress-duan --rule=www.duan.org/=pod-test1:80 --class=nginx
kubectl get ingress -o wide
```

```powershell
# 上面创建规则时过于死板，并不实用！
kubectl edit ingress ingress-duan 
pathType: Exact (精准匹配)	改为	pathType: Prefix (模糊匹配)
或者
kubectl delete ingress ingress-duan
kubectl create ingress ingress-duan --rule=www.duan.org/*=pod-test1:80 --class=nginx --dry-run=client -o yaml > ingress-duan.yaml
kubectl apply -f ingress-duan.yaml && kubectl get ingress
```

##### 单域名多URL

效果图：

![image-20251221144745437](https://cdn.jsdelivr.net/gh/duanxueli08-cell/Obsidian-Images@main/img/image-20251221144745437.png)



```powershell
# 清理环境
kubectl delete ingress ingress-duan 
# 创建 Ingress 规则
kubectl create ingress demo-ingress1 --rule=www.duan.org/v1=pod-test1:80 --rule=www.duan.org/v2=pod-test2:80  --class=nginx
# 查看
kubectl get ingress,svc
# 测试 ( 集群外访问失败，原因是后端服务没有对应的/v1这样的子 URL 资源 )
curl -H "host: www.duan.org" 10.0.0.10/v1
# 删除规则
kubectl delete ingress demo-ingress1

接下来需要实现单域名多URL的流量转发
# annotation nginx.ingress.kubernetes.io/rewrite-target="/" 参数意义：在转发请求给后端 Pod 之前，将匹配到的路径替换为指定的字符（这里是 /）。
kubectl create ingress demo-ingress1 --rule="www.duan.org/v1=pod-test1:80" --rule="www.duan.org/v2=pod-test2:80" --class=nginx --annotation nginx.ingress.kubernetes.io/rewrite-target="/"
kubectl get ingress -A
# 测试 ( 访问是没问题了，但是URL写死了！不具有实际意义！ )
curl -H "host: www.duan.org" 10.0.0.10/v1
curl -H "host: www.duan.org" 10.0.0.10/v1/hostname

接下来需要实现子URL的流量转发
# 删除规则
kubectl delete ingress demo-ingress1
# 新版变化：kubernetes-1.32.0 以后的版本使用指令式命令出错，无法实现，原因：不支持正则表达式！需要使用清单方式
# 解决办法：生成 YAML 文件，修改类型，默认类型为 Exact ；	pathType: Exact 改为 pathType: ImplementationSpecific
# 注意: '/$2' 是单引号,不能为双引号
kubectl create ingress demo-ingress1 --rule='www.duan.org/v1(/|$)(.*)=pod-test1:80' --rule='www.duan.org/v2(/|$)(.*)=pod-test2:80' --class=nginx --annotation nginx.ingress.kubernetes.io/rewrite-target='/$2' --dry-run=client -o yaml > demo-ingress1.yaml
vi demo-ingress1.yaml
kubectl apply -f demo-ingress1.yaml
# 测试
curl -H "host: www.duan.org" 10.0.0.10/v1/hostname
```



为什么需要 Ingress？（相比 NodePort 或 LoadBalancer）

| **特性** | **NodePort / LoadBalancer**      | **Ingress**                       |
| -------- | -------------------------------- | --------------------------------- |
| **层级** | 第 4 层 (TCP/UDP)                | 第 7 层 (HTTP/HTTPS)              |
| **路由** | 仅基于端口转发                   | 基于域名、URL 路径转发            |
| **成本** | 每个服务可能需要一个公网 IP (贵) | 多个服务共用一个 IP 和端口        |
| **功能** | 简单转发                         | 支持 SSL 卸载、灰度发布、重写路径 |

##### HTTPS

```powershell
# 基于TLS的Ingress要求事先准备好专用的“kubernetes.io/tls”类型的Secret资源对象
(umask 077; openssl genrsa -out www.duan.org.key 2048)

openssl req -new -x509 -key www.duan.org.key -out www.duan.org.crt -subj /C=CN/ST=Beijing/L=Beijing/O=SRE/CN=www.duan.org -days 365
# 创建Secret
kubectl create secret tls tls-duan --cert=./www.duan.org.crt --key=./www.duan.org.key

kubectl get secrets
kubectl describe secrets tls-duan

# 创建虚拟主机代理规则，同时将该主机定义为TLS类型，默认HTTP自动跳转至HTTPS
kubectl create ingress tls-demo-ingress --rule='www.duan.org/*=pod-test1:80,tls=tls-duan' --class=nginx --dry-run=client -o yaml > ingress-tls.yaml
kubectl apply -f ingress-tls.yaml
kubectl get ingress
# 测试
curl -H "host: www.duan.org" 10.0.0.10 -i 
curl -H "host: www.duan.org" https://10.0.0.10
curl -H "host: www.duan.org" https://10.0.0.10 -k
```

证书更新

```powershell
# HTTPS 的证书的有效期一般为1年,到期前需要提前更新证书

# 重新颁发证书
(umask 077; openssl genrsa -out duan.key 2048)
openssl req -new -x509 -key duan.key -out duan.crt -subj  /C=CN/ST=Beijing/L=Beijing/O=DevOps/CN=www.duan.org -days 3650

# 删除旧证书配置
kubectl delete secrets tls-duan
# 创建新证书配置
kubectl create secret tls tls-duan --cert=./duan.crt --key=./duan.key

浏览器输入  www.duan.org		可以看到证书组织 SRE 自动变更为 DevOps
```

##### 蓝绿发布

```powershell
# 实验完成，清理环境
kubectl delete  -f ingress-tls.yaml 
kubectl delete svc --all
kubectl delete deployments.apps --all
# 检查环境
kubectl get svc,deploy
```

准备新旧版本对应的各自独立的两套deployment和service

```powershell
cat > deploy-pod-test-v1.yaml <<'eof'
apiVersion: apps/v1
kind: Deployment
metadata:
  labels:
    app: pod-test
  name: pod-test-v1
spec:
  replicas: 3
  selector:
    matchLabels:
      app: pod-test
      version: v0.1
  strategy: {}
  template:
    metadata:
      labels:
        app: pod-test
        version: v0.1
    spec:
      containers:
      - image: registry.cn-beijing.aliyuncs.com/wangxiaochun/pod-test:v0.1
        name: pod-test
---
apiVersion: v1
kind: Service
metadata:
  labels:
    app: pod-test
  name: pod-test-v1
spec:
  ports:
  - name: http-80
    port: 80
    protocol: TCP
    targetPort: 80
  selector:
    app: pod-test
    version: v0.1
  type: ClusterIP
eof
```

```powershell
cat > deploy-pod-test-v2.yaml <<'eof'
apiVersion: apps/v1
kind: Deployment
metadata:
  labels:
    app: pod-test
  name: pod-test-v2
spec:
  replicas: 3
  selector:
    matchLabels:
      app: pod-test
      version: v0.2
  strategy: {}
  template:
    metadata:
      labels:
        app: pod-test
        version: v0.2
    spec:
      containers:
      - image: registry.cn-beijing.aliyuncs.com/wangxiaochun/pod-test:v0.2
        name: pod-test

---
apiVersion: v1
kind: Service
metadata:
  labels:
    app: pod-test
  name: pod-test-v2
spec:
  ports:
  - name: http-80
    port: 80
    protocol: TCP
    targetPort: 80
  selector:
    app: pod-test
    version: v0.2
  type: ClusterIP
eof
```

```powershell
# 应用
kubectl apply -f deploy-pod-test-v1.yaml -f deploy-pod-test-v2.yaml

# 查看
kubectl get svc,deploy

# 创建 Ingress 规则
kubectl create ingress ingress-duan --rule=www.duan.org/*=pod-test-v1:80 --class=nginx --dry-run=client -o yaml > ingress-duan.yaml
kubectl apply -f ingress-duan.yaml && kubectl get ingress

# 终端观察持续测试结果：
while true ; do curl -H"host:www.duan.org" http://10.0.0.10/ ; sleep 1 ; done
```



```powershell
# 终端观察持续测试结果，下面部署完成后可以看到 v1 版本切换到 v2
while true ; do curl -H"host:www.duan.org" http://10.0.0.10/ ; sleep 2 ; done
# 修改 Ingress 清单文件，对应使用的新版本应用
vi ingress-duan.yaml 
spec:
  ingressClassName: nginx
  rules:
  - host: www.duan.org
    http:
      paths:
      - backend:
          service:
            # name: pod-test-v1		# 修改此行，或者注释，添加新行
            name: pod-test-v2
            
# 应用
kubectl apply -f ingress-duan.yaml 
```





##### 金丝雀发布

###### 基于权重的金丝雀发布

```powershell
# 旧版应用,版本恢复到 v1
kubectl apply -f ingress-duan.yaml 
```

创建 Ingress 规则清单文件

```powershell
cat > canary-by-weight.yaml <<'eof'
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  annotations:
    #kubernetes.io/ingress.class: nginx
    nginx.ingress.kubernetes.io/canary: "true" 
    nginx.ingress.kubernetes.io/canary-weight: "1 0"       #指定使用金丝雀发布新版占用的百分比10
  name: pod-test-canary-by-weight 
spec:
  ingressClassName: nginx
  rules:
  - host: www.duan.org
    http:
      paths:
      - backend:
          service:
            name: pod-test-v2
            port:
              number: 80 
        path: /
        pathType: Prefix
eof
```

```powershell
# 终端观察持续测试结果：十次ping测有一个 v2 版本
while true ; do curl -H"host:www.duan.org" http://10.0.0.10/ ; sleep 1 ; done
# 应用
kubectl apply -f canary-by-weight.yaml
# 后续可以修改配置文件，加大比例观察测试！（可选）
```



###### 基于 Cookie 实现金丝雀发布

```powershell
# 清除规则
kubectl delete -f canary-by-weight.yaml
# 旧版应用（可选，目的达到就行！）版本恢复到 v1 
kubectl apply -f ingress-duan.yaml 
```

创建 Ingress 规则清单文件

```powershell
cat > canary-by-cookie.yaml <<'eof'
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  annotations:
    #kubernetes.io/ingress.class: nginx
    nginx.ingress.kubernetes.io/canary: "true"
    nginx.ingress.kubernetes.io/canary-by-cookie: "vip_user" # cookie 中 vip_user=always 时才用金丝雀发布下面新版本
  name: pod-test-canary-by-cookie
spec:
  ingressClassName: nginx
  rules:
  - host: www.duan.org
    http:
      paths:
      - backend:
          service:
            name: pod-test-v2
            port:
              number: 80
        path: /
        pathType: Prefix
eof
```

```powershell
# 应用
kubectl apply -f canary-by-cookie.yaml
# 带有 Cookie 键值对的会转接到 v2 版本
curl -b 'vip_user=always' www.duan.org -Iv
curl -H"host: www.duan.org" http://10.0.0.10
curl -H"host: www.duan.org" -b "vip_user=never" http://10.0.0.10
# 精准控制体验版本的人群，发送邀请函体验，在其 APP 中添加 Cookie 的键值对
```



###### 基于请求 Header 固定值的金丝雀发布

```powershell
# 清除规则
kubectl delete -f canary-by-cookie.yaml && kubectl get ingress
```

```powershell
cat > canary-by-header.yaml <<'eof'
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  annotations:
    #kubernetes.io/ingress.class: nginx
    nginx.ingress.kubernetes.io/canary: "true" 
    nginx.ingress.kubernetes.io/canary-by-header: "X-Canary" # X-Canary自定义的首部字段值为always时才使用金丝雀发布下面新版本,否则为旧版本
  name: pod-test-canary-by-header
spec:
  ingressClassName: nginx
  rules:
  - host: www.duan.org
    http:
      paths:
      - backend:
          service:
            name: pod-test-v2
            port: 
              number: 80
        path: /
        pathType: Prefix
eof
```

```powershell
# 应用
kubectl apply -f canary-by-header.yaml
# 测试
curl -H 'X-Canary: always' www.duan.org -Iv
curl -H"host:www.duan.org" -H"X-Canary: always" http://10.0.0.10
for i in {1..10}; do curl -H "X-Canary: always" www.duan.org; sleep 0.5; done
```







# 存储

> - K8S 把存储抽象出来，本质是为了让**开发**不用管底层是 SSD 还是云盘，让**运维**不用管具体的 Pod 怎么挂载。
> - K8S 存储的本质只有一句话：把“容器里的文件夹”映射到“外面的真实硬盘”上。
>
> PVC 是声明，PV 是资源，SC 是动态工厂
>
> - PV 是硬盘实体；
> - PVC 是存储资源的申请单；所有生产级数据，一律从 PVC 进
> - StorageClass ……怎么说呢！以前 PV 得手动创建，现在有了这玩意，只要 PVC 一申请，它自动去底层云商那给你拉出一块盘。

三种必须要懂的“存储模式”

你在定义存储时，如果不选对模式，Pod 启动时能让你报错报到怀疑人生。

| **模式缩写** | **全称**      | **通俗解释** | **典型场景**                                           |
| ------------ | ------------- | ------------ | ------------------------------------------------------ |
| **RWO**      | ReadWriteOnce | 单节点读写   | 数据库（MySQL/PostgreSQL），只能一个坑位蹲             |
| **ROX**      | ReadOnlyMany  | 多节点只读   | 静态资源库，大家都能看，谁也别想改                     |
| **RWX**      | ReadWriteMany | 多节点读写   | 文件共享（NFS/Ceph），大家一起拉屎一起擦（注意锁机制） |



------

### 第一部分：K8S 存储机制

在 Docker 时代，你挂载目录用 `-v /data:/data`。但在 K8S 这种集群环境里，Pod 是会“瞬移”的（在不同节点漂移）。如果只用本地目录，Pod 一漂移，数据就丢了。

所以 K8S 引入了 **两层抽象机制**：

1. 控制平面机制：存储编排

- **挂载（Mounting）**：把远程存储（比如阿里云盘、NFS）变成 Linux 能识别的一个挂载点。
- **绑定（Binding）**：把这个挂载点塞进容器的某个目录里。

2. 静态与动态供应机制

- **静态（Static）**：运维老哥手动去分盘，分好 10G、20G 的盘等在那（这就是 PV）。
- **动态（Dynamic）**：运维老哥写个脚本（StorageClass），开发一要盘，系统自动去后台划一块出来。**这是目前生产环境的主流，因为运维不想天天被开发骚扰。**

------

### 第二部分：存储类型

K8S 的存储卷（Volume）有很多种，我按重要程度给你排个序：

1. ##### 临时工：`emptyDir`

> **核心逻辑**：数据存放在 `kubelet` 工作目录，Pod 只要一死，数据直接火化。
>
> **优点**：
>
> - **快**：直接走本地 I/O。
> - **简单**：不需要任何外部存储插件。
>
> **缺点**：**不持久**。Pod 重启（只要没被重新调度）数据还在，但 Pod 一旦被删除重建，数据直接灰飞烟灭。
>
> **生产用途**：缓存、计算中间件、同一 Pod 内多个容器共享文件。
>
> **评价**：运维基本不管它，开发自己玩。

2. ##### 本地老古董：`hostPath`

> **核心逻辑**：挂载宿主机的某个目录。
>
> **优点**：
>
> - **性能极高**：原生磁盘性能，没有网络开销。
>
> **缺点**：
>
> - **不支持漫游**：Pod 漂移到别的节点直接变白板。
> - **不安全**：容器能直接改宿主机系统文件（比如挂载 `/etc`），容易被黑出详。
> - **无法限额**：没法自定义容量。
>
> **生产用途**：日志收集插件（读取宿主机日志）、监控组件（读取节点信息）。
>
> **槽点**：Pod 只要漂移到别的节点，数据就对不上了。就像你在 A 宾馆存了包，去了 B 宾馆找前台要，前台只会觉得你是来找茬的。

3. ##### NFS

> **逻辑**：通过网络协议挂载远程存储服务器。
>
> **优点**：
>
> - **支持数据漫游**：Pod 随便漂移，数据如影随形。
> - **支持多读多写（RWX）**：多个 Pod 同时读写同一个目录，做静态资源共享的神器。
>
> **缺点**：
>
> - **IO 垃圾**：数据过网络，延迟高，别想拿它跑高性能数据库。
> - **单点风险**：NFS 服务器挂了，集群里所有挂载它的 Pod 全得跪。
>
> **生产用途**：用户上传头像、静态 HTML、简单的配置文件共享。
>
> 评价：平民战神、万能胶

```powershell
# 将10.0.0.14服务器上的/data/目录挂载到本地/mnt/目录；效果是访问/mnt/就是访问对端服务器的/data/目录；临时的！！！
mount  -t  nfs  10.0.0.14:/data/  /mnt/
# 卸载mnt目录
umount  /mnt


永久挂载
# 方法一：挂载指令写入  /etc/rc.local  配置文件中
chmod +x  /etc/rc.d/rc.local
# 方法二：按照 /etc/fstab 格式要求书写
设备					挂载点		文件系统类型	 挂载参数		是否检查	是否备份
10.0.0.14:/data/	 /upload/	nfs			defaults	 0			0
```



4. ##### 网络存储

这是重点，因为只有网络存储才能解决 Pod 漂移后的数据一致性。

StorageClass 下的两大门派

**SC 的作用：** 在 Local PV 里，SC 最大的作用不是“创建盘”，而是 **“推迟绑定”**；即：K8S 会等 Pod 确定在哪落户了，再去找那台机器上的 PV 绑定。

| **特性**     | **Local Volume (本地卷派)**               | **NFS / 云盘 (网络卷派)**        |
| ------------ | ----------------------------------------- | -------------------------------- |
| **制备方式** | 多为 **静态 (Static)**，或半自动          | 绝对 **动态 (Dynamic)**          |
| **性能**     | **天花板级**。磁盘 I/O 零损耗             | 受网络带宽和延迟限制             |
| **数据漫游** | **不支持**。Pod 必须死磕这台机器          | **支持**。全集群节点随便漂移     |
| **核心参数** | `volumeBindingMode: WaitForFirstConsumer` | `reclaimPolicy: Delete/Retain`   |
| **典型代表** | 数据库（MySQL/ES）、大数据处理            | 配置文件、用户上传、Web 静态资源 |

> **逻辑**：这不是存储本身，这是**创建存储的规则**。
>
> **优点**：
>
> - **自动化**：开发写个 PVC 就能自动拿盘，运维不用手动 `mkdir` 建 PV。
> - **标准化**：统一了存储申请流程。
>
> **缺点**：
>
> - **门槛高**：你得先部署对应的 `CSI` 驱动（比如阿里云 CSI、Ceph CSI）。
>
> **生产用途**：**目前 90% 生产环境的标准配置**。
>
> 评价：自动提款机、高级猎头





> **NFS（中低端标配）**：
>
> - **特点**：便宜、好调。支持 RWX（多个 Pod 同时读写）。
> - **生产现状**：中小规模公司存个配置文件、用户头像、静态资源首选。
>
> **云硬盘（公有云王者）**：
>
> - **例子**：阿里云 ESSD、AWS EBS。
> - **生产现状**：**绝对主流**。稳定性最高，运维最省心（不用你自己修硬盘）。缺点是通常只支持 RWO（一个盘只能挂给一个 Pod）。
>
> **分布式存储（大厂自研/私有云）**：
>
> - **代表**：Ceph、GlusterFS、Longhorn。
> - **生产现状**：高端玩家。Ceph 强无敌但运维难度能让你掉头发，Longhorn 是目前比较火的轻量级选择。

------

### 第三部分：从“手动”到“全自动”

为了让你看清这些玩意怎么串起来的，我给你画个流程图：

**【手动时代 - 苦力活】**

1. 运维去 NFS 服务器：`mkdir /data/v1`
2. 运维在 K8S 建立 **PV**（指明这个目录是 10G）
3. 开发在 K8S 建立 **PVC**（我要 10G 盘）
4. K8S 发现两个正好匹配，**Bound（绑定）**！
5. Pod 在定义里写上：`volumes: persistentVolumeClaim: claimName: my-pvc`

**【自动时代 - 现代运维】**

1. 运维部署一个 **StorageClass**（告诉 K8S：去找阿里云/Ceph 自动要盘）。
2. 开发直接写个 **PVC**，并在里面写上 `storageClassName: fast-disk`。
3. **奇迹发生**：K8S 自动在后台帮你把 PV 建好了，盘也买好了，直接就能用。

------



### 生产参数的“潜规则”提炼

| **维度**     | **关键参数**        | **老东西的实战秘籍**                                         |
| ------------ | ------------------- | ------------------------------------------------------------ |
| **生命周期** | `reclaimPolicy`     | 生产**必选 `Retain`**（保留）。要是选 `Delete`，PVC 一删数据全没，到时候你就得去天台排队了。 |
| **调度策略** | `volumeBindingMode` | **本地盘必选 `WaitForFirstConsumer`**。别让 PV 瞎绑定，得等 Pod 确定在哪台机器落地了，再把盘分过去，否则 Pod 调度不上去。 |
| **读写权限** | `accessModes`       | 绝大多数数据库只认 `RWO`。别幻想用 `RWX` 给多个 MySQL 用，文件系统会碎给你看。 |
| **物理形态** | `volumeMode`        | 99% 选 `Filesystem`。除非你在搞超高性能数据库或虚拟化镜像，才会去碰 `Block`（裸块设备）。 |

------

选型决策树：什么时候用什么？

别听网上吹什么 Ceph、Lustre，**生产环境没那个金刚钻别揽瓷器活。**

1. **如果你在公有云（阿里云/AWS）：**
   - **首选：** 云盘 CSI（如阿里云 ESSD）。
   - **理由：** 稳定，支持动态创建，运维成本近乎为 0。
2. **如果你在物理机房（私有云）：**
   - **高性能/大数据（ES/ClickHouse）：** 必须用 **Local PV**。配合 `WaitForFirstConsumer`，把 IO 压榨到极致。
   - **共享配置/普通业务（日志、上传文件）：** 用 **NFS**。虽然 Low，但真的好修。
   - **核心数据库：** 建议用 **Ceph (RBD)**，如果你手底下的兄弟能搞定 Ceph 的运维。

------

StatefulSet 的“灵魂耦合”

- **逻辑：** StatefulSet 配合 `volumeClaimTemplates`。
- **现象：** Pod-0 永远绑定 PVC-0。Pod 死了重启，名字还是 Pod-0，哪怕飘到火星去，它也要回来找 PVC-0。
- **意义：** 这才是真正的“状态”，也是数据库能在 K8S 跑起来的基础。



#### NFS 实践案例

创建 NFS 服务

```powershell
# master1 节点
apt update && apt -y install nfs-server
systemctl status nfs-server.service
mkdir -p /data/sc-nfs
cat >> /etc/exports <<'eof'
# 授权worker节点的网段可以挂载 （这个 no_root_squash 一定要加，否则没有权限）
/data/sc-nfs *(rw,no_root_squash)
eof
exportfs -rv
# 挂载到 10.0.0.101 服务器 /data/sc-nfs 目录
mount nfs.wang.org:/data/sc-nfs  /mnt
# 测试
showmount -e 10.0.0.101
# 添加域名解析
sed -i 's#^10.0.0.101.*#10.0.0.101 master1.wang.org master1 nfs.wang.org#'  /etc/hosts && grep master1 /etc/hosts
# 所有节点同步
for host in 10.0.0.{104..106}; do
    scp /etc/hosts root@$host:/etc/hosts
done
# 在所有 worker 节点安装 NFS 客户端
apt update && apt -y install nfs-common
# 后续的测试验证
kubectl  get pod -o wide
redis-cli -h 10.244.1.11
dbsize
set class m65
get class
save
ls /data/sc-nfs
# 继续测试，改换节点，查看数据是否改在！
kubectl  delete -f redis-deployment.yaml 
vi redis-deployment.yaml		# node1 改为 node2 节点
kubectl  apply -f redis-deployment.yaml 
kubectl  get pod -o wide		# 查看pod状态，以及pod地址
redis-cli -h 10.244.4.2  get class		# 应该能看到 m65 
```

二选一

```powershell
cat > storage-nfs-1.yaml  <<'eof'
apiVersion: v1
kind: Pod
metadata:
    name: volumes-nfs
spec:
    nodeName: node1		# 节点的/etc/hosts文件或DNS解析此域名；节点对应的主机名必须与之相同
    volumes:
    - name: redisdatapath
      nfs:
        server: nfs.wang.org		# 注意:需要宿主机节点/etc/hosts文件或DNS解析此域名,而不是由Pod通过coreDNS完成解析
        path: /data/sc-nfs
    containers:
    - name: redis
      #image: redis:6.2.5
      image: registry.cn-beijing.aliyuncs.com/wangxiaochun/redis:6.2.5
      volumeMounts:
      - name: redisdatapath
        mountPath: /data
eof

kubectl apply -f storage-nfs-1.yaml
```

二选一

```powershell
cat > redis-deployment.yaml <<'eof'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: redis-nfs-deployment
  labels:
    app: redis
spec:
  replicas: 1
  selector:
    matchLabels:
      app: redis
  template:
    metadata:
      labels:
        app: redis
    spec:
      # 保持你在原 Pod 中的节点亲和性/指定
      nodeName: node1		# 节点的/etc/hosts文件或DNS解析此域名；节点对应的主机名必须与之相同
      volumes:
      - name: redisdatapath
        nfs:
          server: nfs.wang.org
          path: /data/sc-nfs
      containers:
      - name: redis
        image: registry.cn-beijing.aliyuncs.com/wangxiaochun/redis:6.2.5
        imagePullPolicy: IfNotPresent
        ports:
        - containerPort: 6379
        volumeMounts:
        - name: redisdatapath
          mountPath: /data
eof

kubectl apply -f redis-deployment.yaml
```

注释

```powershell
apiVersion: apps/v1             # 资源版本，Deployment 固定使用 apps/v1
kind: Deployment                # 资源类型：部署。负责维持 Pod 的数量和更新策略
metadata:
  name: redis-nfs-deployment    # 这个 Deployment 自己的名字
  labels:                       # 给这个 Deployment 打上标签，方便过滤查找
    app: redis
spec:                           # 【核心规格】定义你期望的状态
  replicas: 1                   # 副本数：只运行 1 个 Redis 实例
  selector:                     # 【选择器】告诉 Deployment 它该管哪些 Pod
    matchLabels:
      app: redis                # 必须与下面的 template.metadata.labels 一致
  template:                     # 【模版】定义具体要创建出来的 Pod 是什么样的
    metadata:
      labels:                   # Pod 的标签，被上面的 selector 选中
        app: redis
    spec:                       # Pod 内部的具体配置
      # --- 节点约束 ---
      nodeName: node1           # 强制指定运行在名为 node1 的节点上（建议慎用，除非确定节点名准确）

      # --- 存储定义 (声明书) ---
      volumes:                  # 定义这个 Pod 能够使用的所有“磁盘”
      - name: redisdatapath     # 卷的自定义名称，给下面的 container 引用
        nfs:                    # 存储类型：直接连接 NFS 服务器
          server: nfs.wang.org  # NFS 服务器地址（需确保 Worker 节点能解析此域名）
          path: /data/sc-nfs    # NFS 上的共享目录

      # --- 容器定义 ---
      containers:
      - name: redis             # 容器名字
        image: registry.cn-beijing.aliyuncs.com/wangxiaochun/redis:6.2.5
        imagePullPolicy: IfNotPresent # 镜像拉取策略：如果本地有就用本地的，没有再下载
        ports:
        - containerPort: 6379   # 容器内部监听的端口
        
        # --- 存储挂载 (实施) ---
        volumeMounts:           # 将上面定义的卷“插”进容器的某个目录
        - name: redisdatapath   # 引用上面 volumes 里的名字
          mountPath: /data      # 映射到容器内部的目录。Redis 的数据默认存这里
```



#### PV 和 PVC 

![image-20251218162459707](https://cdn.jsdelivr.net/gh/duanxueli08-cell/Obsidian-Images@main/img/image-20251218162459707.png)

![image-20251218162512918](https://cdn.jsdelivr.net/gh/duanxueli08-cell/Obsidian-Images@main/img/image-20251218162512918.png)

PV 状态

- Availabled；空闲状态，表示PV没有被其他PVC对象使用
- Bound；绑定状态，表示PV已经被其他PVC对象使用
- Released；未回收状态，表示PVC已经被删除了，但是资源还没有被回收
- Faild；资源回收失败

通过 kubectl patch 命令可以直接修改 PV 的状态，使其从 Released 状态变为 Available 状态。

```powershell
kubectl patch persistentvolume <pv-name> -p '{"spec":{"claimRef": null}}'
```

AccessMode 访问模式

- ReadWriteOnce（RWO）：单节点读写
- ReadOnlyMany（ROX）：多节点只读
- ReadWriteMany（RWX）：多节点读写
- ReadWriteOncePod(RWOP)：待补充！

PV 资源回收策略

Retain：当PVC删除后，会保留对应的PV和存储空间数据，后续数据的删除需要人工干预，一般推荐使用此项；
Delete：当PVC删除后，相关的PV和数据都一起删除，动态存储一般会默认采用此方式；
Recycle：当前此项已废弃，保留PV，但清空存储空间的数据，仅支持NFS和hostPath

案例

以 NFS 类型创建一个3G大小的存储资源对象 PV

```powershell
# 准备NFS共享存储
mkdir -p /nfsdata/www
apt update &&apt -y install nfs-server
echo "/nfsdata *(rw,no_root_squash)" >> /etc/exports
echo "Hello world" >> /nfsdata/www/index.html
exportfs -r && exportfs -v
# 在所有worker节点安装nfs软件
apt -y install nfs-common
```

PV

```powershell
# 准备PV,定制一个具体空间大小的存储对象
cat > storage-pv.yaml <<'eof'
apiVersion: v1
kind: PersistentVolume
metadata:
  name: pv-test  # 正确：只包含小写字母、数字和连字符
spec:
  # storageClassName: manual   # 用于分类，指定 pv 绑定到指定的 pvc ，不用这个参数分配随机
  capacity:
    storage: 3Gi
  accessModes:
    - ReadWriteOnce
    - ReadWriteMany
    - ReadOnlyMany
  nfs:
    path: /nfsdata/www
    server: nfs.wang.org  # 确保所有节点都能解析此域名
eof
# 虽然我们在创建pv的时候没有指定回收策略，而其策略自动帮我们配置了Retain
kubectl apply -f storage-pv.yaml
kubectl get pv
```

PVC

```powershell
# 准备PVC,定义一个资源对象，请求空间1Gi
cat > storage-pvc.yaml <<'eof'
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: pvc-test
spec:
  # storageClassName: manual   # 用于分类，指定 pvc 绑定到指定的 pv ，不用这个参数分配随机
  accessModes:
    - ReadOnlyMany
  resources:
    requests:
      storage: 1Gi		 # #注意：请求的资源大小必须在 pv资源的范围内。
eof
# 一旦启动pvc会自动去搜寻合适的可用的pv，然后绑定在一起；如果pvc找不到对应的pv资源，状态会一直处于pending
kubectl apply -f storage-pvc.yaml
kubectl get pv
```

Pod

```powershell
# 准备 pod
cat > storage-nginx-pvc.yaml <<'eof'
apiVersion: v1
kind: Pod
metadata:
  name: pod-nginx
spec:
  volumes:
    - name: volume-nginx
      persistentVolumeClaim:
        claimName: pvc-test
  containers:
    - name: pvc-nginx-container
      image: registry.cn-beijing.aliyuncs.com/wangxiaochun/nginx:1.20.0
      volumeMounts:
        - name: volume-nginx
          mountPath: "/usr/share/nginx/html"
eof
# 属性解析：
# spec.volumes 是针对pod资源申请的存储资源来说的，这里使用的是pvc的方式。
# spec.containers.volumeMounts 是针对pod资源对申请的存储资源的信息。将pvc挂载的容器目录
kubectl apply -f storage-nginx-pvc.yaml
kubectl get pod -o wide
# 测试 （应该看到已经定义好的字段：Hello world）
curl 10.244.4.3 
```

```powershell
注意：删除时要按顺序删除,先删除应用 pod 再删除 pvc 最后删除 pv ; 否则会出现卡死现象
# 删除 pod
kubectl delete -f storage-nginx-pvc.yaml
# 删除 PVC
kubectl delete -f storage-pvc.yaml
kubectl get pvc
# 最后删除 PV
kubectl delete -f storage-pv.yaml
kubectl get pv
```



#### StorageClass 

Provisioner：存储制备器；每个 StorageClass 都有一个制备器 Provisioner ，用于提供存储驱动，用来决定使用哪个卷插件制备 PV。 该字段必须指定。

##### 静态配置

```powershell
# Local PV 不会自动创建目录 ( 在指定节点创建 )
mkdir -p /data/mysql


cat > storage-sc-local-pv-pvc-mysql-pod.yaml <<'eof'
---
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: local-storage
provisioner: kubernetes.io/no-provisioner
volumeBindingMode: WaitForFirstConsumer  #延迟绑定，只有Pod启动后再绑定PV到Pod所在节点，否则PVC处理Pending状态
# 没有制备器上面的是形式内容，最大的作用是延迟绑定，没有了延迟绑定创建后立刻绑定，所以不加上面的几乎没有影响；

---
apiVersion: v1
kind: PersistentVolume
metadata:
  name: pv-sc-local
spec:
  capacity:
    storage: 10Gi
  volumeMode: Filesystem
  accessModes:
  - ReadWriteOnce
  persistentVolumeReclaimPolicy: Delete # 因为静态置配，所以当PVC删除后，不会删除PV和数据
  storageClassName: local-storage
  local:
    path: /data/mysql
  nodeAffinity:
    required:
      nodeSelectorTerms:        # 指定节点
      - matchExpressions:
        - key: kubernetes.io/hostname
          operator: In
          values:
          - node2

---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: pvc-sc-local
spec:
  storageClassName: local-storage
  accessModes: ["ReadWriteOnce"]
  resources:
    requests:
      storage: 10Gi

---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: mysql
spec:
  selector:
    matchLabels:
      app: mysql
  strategy:
    type: Recreate
  template:
    metadata:
      labels:
        app: mysql
    spec:
      containers:
      - image: registry.cn-beijing.aliyuncs.com/wangxiaochun/mysql:8.0.29-oracle
        name: mysql
        env:
          # 在实际中使用 secret
        - name: MYSQL_ROOT_PASSWORD
          value: "123123"
        ports:
        - containerPort: 3306
          name: mysql
        volumeMounts:
        - name: mysql-persistent-storage
          mountPath: /var/lib/mysql
      volumes:
      - name: mysql-persistent-storage
        persistentVolumeClaim:
          claimName: pvc-sc-local
eof
kubectl apply -f storage-sc-local-pv-pvc-mysql-pod.yaml
kubectl get pv,pvc,pod
```

##### 动态配置

```powershell
# 准备NFS共享存储
mkdir -p /data/sc-nfs
apt update &&apt -y install nfs-server
echo "/data/sc-nfs *(rw,no_root_squash)" >> /etc/exports
exportfs -r && exportfs -v
# 在所有worker节点安装nfs软件
apt -y install nfs-common
```

```powershell
# 创建独立的名称空间
kubectl create ns sc-nfs
# 指定名称空间
cat > rbac.yaml <<'eof'
apiVersion: v1
kind: ServiceAccount
metadata:
  name: nfs-client-provisioner
  # replace with namespace where provisioner is deployed
  #namespace: default
  namespace: sc-nfs 
---
kind: ClusterRole
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: nfs-client-provisioner-runner
rules:
  - apiGroups: [""]
    resources: ["nodes"]
    verbs: ["get", "list", "watch"]
  - apiGroups: [""]
    resources: ["persistentvolumes"]
    verbs: ["get", "list", "watch", "create", "delete"]
  - apiGroups: [""]
    resources: ["persistentvolumeclaims"]
    verbs: ["get", "list", "watch", "update"]
  - apiGroups: ["storage.k8s.io"]
    resources: ["storageclasses"]
    verbs: ["get", "list", "watch"]
  - apiGroups: [""]
    resources: ["events"]
    verbs: ["create", "update", "patch"]
---
kind: ClusterRoleBinding
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: run-nfs-client-provisioner
subjects:
  - kind: ServiceAccount
    name: nfs-client-provisioner
    # replace with namespace where provisioner is deployed
    #namespace: default
    namespace: sc-nfs
roleRef:
  kind: ClusterRole
  name: nfs-client-provisioner-runner
  apiGroup: rbac.authorization.k8s.io
---
kind: Role
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: leader-locking-nfs-client-provisioner
  # replace with namespace where provisioner is deployed
  #namespace: default
  namespace: sc-nfs
rules:
  - apiGroups: [""]
    resources: ["endpoints"]
    verbs: ["get", "list", "watch", "create", "update", "patch"]
---
kind: RoleBinding
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: leader-locking-nfs-client-provisioner
  # replace with namespace where provisioner is deployed
  #namespace: default
  namespace: sc-nfs
subjects:
  - kind: ServiceAccount
    name: nfs-client-provisioner
    # replace with namespace where provisioner is deployed
    #namespace: default
    namespace: sc-nfs
roleRef:
  kind: Role
  name: leader-locking-nfs-client-provisioner
  apiGroup: rbac.authorization.k8s.io
eof

kubectl apply -f rbac.yaml
kubectl get sa
```

部署 NFS-Subdir-External-Provisioner 对应的 Deployment

```powershell
cat > nfs-client-provisioner.yaml <<'eof'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nfs-client-provisioner
  labels:
    app: nfs-client-provisioner
  # replace with namespace where provisioner is deployed
  #namespace: default
  namespace: sc-nfs
spec:
  replicas: 1	# 这里的副本数根据实际情况决定；为了实现高可用
  strategy:
    type: Recreate
  selector:
    matchLabels:
      app: nfs-client-provisioner
  template:
    metadata:
      labels:
        app: nfs-client-provisioner
    spec:
      serviceAccountName: nfs-client-provisioner
      containers:
        - name: nfs-client-provisioner
          image: registry.cn-beijing.aliyuncs.com/wangxiaochun/nfs-subdir-external-provisioner:v4.0.2
          #image: wangxiaochun/nfs-subdir-external-provisioner:v4.0.2
          #image: k8s.gcr.io/sig-storage/nfs-subdir-external-provisioner:v4.0.2
          imagePullPolicy: IfNotPresent
          volumeMounts:
            - name: nfs-client-root
              mountPath: /persistentvolumes
          env:
            - name: PROVISIONER_NAME
              value: k8s-sigs.io/nfs-subdir-external-provisioner #名称确保与 nfs-StorageClass.yaml文件中的provisioner名称保持一致
            - name: NFS_SERVER
              value: nfs.wang.org # NFS SERVER_IP 
            - name: NFS_PATH
              value: /data/sc-nfs  # NFS 共享目录
      volumes:
        - name: nfs-client-root
          nfs:
            server: nfs.wang.org  # NFS SERVER_IP 
            path: /data/sc-nfs  # NFS 共享目录
eof

kubectl apply -f nfs-client-provisioner.yaml
kubectl get deployments.apps -A
kubectl get pod -A
# 注意:如果失败,检查是否worker节点安装了nfs-client
```

创建 NFS 资源的 StorageClass

```powershell
cat > nfs-StorageClass.yaml <<'eof'
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: sc-nfs 
  annotations:
    storageclass.kubernetes.io/is-default-class: "false"  # 是否设置为默认的storageclass
provisioner: k8s-sigs.io/nfs-subdir-external-provisioner # or choose another name, must match deployment's env PROVISIONER_NAME'
parameters:
  archiveOnDelete: "true" # 设置为"false"时删除PVC不会保留数据,"true"则保留数据
eof

kubectl apply -f nfs-StorageClass.yaml
kubectl get sc -A
```

创建 PVC

```powershell
cat > pvc.yaml <<'eof'
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: pvc-nfs-sc
spec:
  storageClassName: sc-nfs  #需要和前面创建的storageClass名称相同
  accessModes: ["ReadWriteMany","ReadOnlyMany"]
  resources:
    requests:
      storage: 100Mi
eof

kubectl apply -f pvc.yaml
# 此时应该能看到 PV 自动创建完成，并自动与 PVC 绑定
kubectl get pv,pvc
# 查看自动在NFS服务器创建的目录
ls /data/sc-nfs/
```

好了，啰嗦了这么多，也该创建业务容器了吧！

```powershell
cat > pod-test.yaml <<'eof'
apiVersion: v1
kind: Pod
metadata:
  name: pod-nfs-sc-test
spec:
  containers:
  - name: pod-nfs-sc-test
    image: registry.cn-beijing.aliyuncs.com/wangxiaochun/nginx:1.20.0
    volumeMounts:
      - name: nfs-pvc
        mountPath: "/usr/share/nginx/html/"
  restartPolicy: "Never"
  volumes:
    - name: nfs-pvc
      persistentVolumeClaim:
        claimName: pvc-nfs-sc  #指定前面创建的PVC名称
eof

kubectl apply -f pod-test.yaml
# 测试！！！
echo "Hello World" >> /data/sc-nfs/default-pvc-nfs-sc-pvc-f2c167da-69d1-4dbe-b70b-91ae6c92b97b/index.html
kubectl get po -o wide
curl 10.244.1.15
```









# K8s 的配置管理

> **K8s 的配置管理，本质就是：
>  把“配置”从“镜像/代码”里剥离出来，由集群统一管理，并按需注入到 Pod。**

核心目标只有三个：

1. **配置与镜像解耦**
2. **配置可动态变更**
3. **配置可权限控制、可审计**

在 K8s 中，配置不是一个东西，而是**四大类**

| 类型         | 资源                | 是否敏感 | 典型用途          |
| ------------ | ------------------- | -------- | ----------------- |
| 普通配置     | ConfigMap           | 否       | 参数、URL、开关   |
| 敏感配置     | Secret              | 是       | 密码、Token、证书 |
| 应用启动配置 | PodSpec / Env       | 否       | 启动参数          |
| 集群级配置   | kubelet / apiserver | 高危     | 系统级行为        |

👉 **90% 的业务配置 = ConfigMap + Secret**



### ConfigMap

ConfigMap 主要功能：

1. **存储配置数据**：
    ConfigMap 可以存储多个配置信息，如配置文件、环境变量、命令行参数等。它使得配置可以在不同环境中动态地修改，而无需重建镜像或重新部署应用。
2. **与 Pod 配合使用**：
    可以将 ConfigMap 的内容挂载到 Pod 中，以便容器读取这些配置。ConfigMap 可以通过两种方式暴露配置：
   - **环境变量**：通过 `envFrom` 或 `env` 字段将 ConfigMap 中的键值对作为环境变量传递给容器。
   - **挂载为文件**：通过 `volumeMounts` 和 `volumes` 将 ConfigMap 中的数据作为文件挂载到 Pod 的文件系统中。

配置更新逻辑：

- **原子更新**：为了防止文件更新到一半被程序读取导致报错，K8S 会先创建一个带**时间戳**的新目录，把新配置塞进去。
- **瞬间切换**：等新目录准备好了，直接把 `..data` 这个软链接指向新的时间戳目录。
- **清理旧账**：过一会儿再把旧的时间戳目录删掉。

> 基本上业务配置都是 ConfigMap 以及 ConfigMap 搭配其他配置方案
>
> 本质就是一个 **key-value 配置仓库**
>
> ConfigMap 是 **K8s 中存储非敏感配置的 API 对象**
>
> ConfigMap 更新不是魔法，是**软链接切换**。如果你看到文件没变，先去查查你是用 `env` 挂载的还是 `volume` 挂载的。

ConfigMap 怎么用？

| **使用方式**       | **更新是否需要重启 Pod**                  | **典型场景**                       |
| ------------------ | ----------------------------------------- | ---------------------------------- |
| **1. 环境变量**    | **是**（必须重建 Pod 才能生效）           | 基础信息、少量非敏感开关           |
| **2. Volume 挂载** | **否**（Kubelet 自动更新文件，约 10-60s） | 配置文件（nginx.conf, redis.conf） |
| **3. 启动参数**    | **是**                                    | 强制依赖命令行启动的项目           |
| **4. API 调用**    | **否**（完全由代码逻辑控制）              | 深度定制的微服务、配置中心         |

使用挂载文件方式时，通常需要配合以下方案之一：

1. **应用热加载**：程序本身支持监听文件变化（如 Nginx 的 `reload` （热加载）或 Go 的 `fsnotify`）。
2. **Reloader 控制器**：使用开源工具（如 `stakater/Reloader`），当 ConfigMap 变化时，自动帮你触发 Pod 的滚动更新。

指令创建

```powershell
kubectl create configmap my-config --from-literal=key1=value1 --from-literal=key2=value2
kubectl get cm
kubectl get cm -o yaml
```





### Secret 

前言

K8S 默认的 Secret 并不是真正的“加密”，它只是 **Base64 编码**。防君子不防小人

在真正的金融级或高安全需求生产环境中，我们一般会配合 KMS 对 Secret 进行静态加密。否则，只要有人能进 etcd，你的秘密就是全透明的。

Secret 的三大核心用法

| **场景**                  | **俗称** | **实际用途**                                                 |
| ------------------------- | -------- | ------------------------------------------------------------ |
| **Service Account Token** | 身份牌   | Pod 想调用 API Server 时自报家门的凭证。                     |
| **docker-registry**       | 进门条   | 你的私有镜像仓库（如 Harbor）的账号密码，没它 Pod 拉不下镜像。 |
| **Opaque Secret**         | 杂货铺   | 存数据库密码、SSL 证书、各种加密 Key。                       |

把秘密“喂”给 Pod

在 K8S 里，Secret 进入 Pod 主要有两种姿势：挂载为文件 ；映射为环境变量

> 挂载为文件 —— **推荐做法**
>
> - 这种方式最安全。Secret 会以文件的形式出现在容器的某个目录下。
> - **优点**：支持**热更新**。你在集群里改了 Secret，容器里的文件过一会儿（通常一分钟内）会自动变。
> - **坑**：你的程序得支持“监控文件变化并重新加载”，否则还是得重启 Pod。
>
> 映射为环境变量
>
> - **优点**：程序读取最简单，直接 `os.getenv("DB_PASSWORD")`。
> - **缺点**：**不支持热更新**。Secret 改了，Pod 必须重启才能生效。而且，万一 Pod 崩了报堆栈信息，环境变量很容易泄露到日志里。

潜规则

> 隐藏的“亲儿子”：ServiceAccount Token：
>
> - 不创建 Secret，Pod 里就没秘密了？
> - 每个 Pod 启动时，K8S 默认都会自动挂载一个 Secret。你进 Pod 敲一下 `ls /var/run/secrets/kubernetes.io/serviceaccount/` 看看。 这就是 **ServiceAccount (SA)**。它是 Pod 的身份身份证。
> - 如果你这个 Pod 根本不需要调 API（比如只是个前端 Nginx），记得在 Pod 定义里加上 `automountServiceAccountToken: false`。**少开一个口子，多一分安全。**
>
> Immutable Secrets（不可变秘密）：
>
> - 这是 K8S 1.21 之后转正的“神技”。 以前 Secret 是默认可以随时改的，但 Kubelet 会不停地去轮询 etcd 看它改没改。如果你的集群有几万个 Secret，etcd 的压力能大到让你想砸电脑。
>
> - YAML 配置：
>
>   ```powershell
>   kind: Secret
>   apiVersion: v1
>   metadata:
>     name: my-secret
>   immutable: true  # 重点在这里
>   data:
>     api-key: dXNlci1wYXNz
>   ```
>
>   一旦设为 `true`，这个 Secret 就锁死了，谁也别想改。**想改？只能删了重建。**
>
> - **好处**：极大减轻 API Server 负担；防止误操作改了配置导致生产事故。
>
> 当 Secret 挂载到 Pod 时，K8S 使用的是 **tmpfs**（内存文件系统）这意味着：
>
> - 秘密只存在于**内存**里。
> - Pod 一死，内存释放，痕迹全无。
>
> 









![image-20251219094822861](https://cdn.jsdelivr.net/gh/duanxueli08-cell/Obsidian-Images@main/img/image-20251219094822861.png)











### PodSpec 

由于不多用，就不多赘述了！

- 由 K8s 控制
- **一旦 Pod 创建，无法热修改**

和 ConfigMap 的关系是：

- PodSpec = 框架级
- ConfigMap = 业务级



### 配置是如何“流动”的

```powershell
etcd
 └── ConfigMap / Secret
      └── kube-apiserver
           └── kubelet
                └── Pod
                     ├── env
                     └── volume
```

- kubelet **watch API Server**
- 配置变化 → kubelet 同步 → 写入容器文件系统
- **不是容器主动拉**



# CRD

操作流程：

- **第一步：安装规矩** `kubectl apply -f my_crd.yaml` 
  （此时，K8s 就像学会了新技能。但此时集群里什么都没发生，没有 Pod 被创建。）
- **第二步：部署控制器** 
  （你会部署一个 Deployment，里面运行着 Controller 的代码。它会开始盯着 API Server 看。）
- **第三步：提交订单（创建 CR）** `kubectl apply -f zhang_san.yaml` 
  （这时候，Controller 发现多了一个 `Student` 资源，于是立刻跳出来，按照代码逻辑去干活，比如在数据库里给张三开个账户。）

Operator：

- CRD + Controller = Operator
- Operator：为有状态服务提供的私人订制 （ CRD + Controller  ）；



安装 Operator

```powershell
kubectl create -f https://download.elastic.co/downloads/eck/3.2.0/crds.yaml
# 查看相关CRD
kubectl get crd --sort-by='{.metadata.creationTimestamp}'|tail
# 安装 operator 相关 RBAC 规则
kubectl apply -f https://download.elastic.co/downloads/eck/3.2.0/operator.yaml
# 在 elastic-system 名称空间查看相关资源
kubectl get all -n elastic-system
```

部署 Elasticsearch

```powershell
# 准备业务的名称空间
kubectl create ns demo
需要提前准备sc-nfs的storageClass
节点内存需要4G以上
# 准备 elasticsearch-cluster 清单文件
cat > operator-elasticsearch-cluster.yaml <<'eof'
apiVersion: elasticsearch.k8s.elastic.co/v1
kind: Elasticsearch
metadata:
  name: my-es-cluster
  namespace: demo
spec:
  version: 9.2.1
  nodeSets:
    - name: default
      count: 3
      config:
        node.store.allow_mmap: false
      volumeClaimTemplates:
        - metadata:
            name: elasticsearch-data
          spec:
            accessModes:
              - ReadWriteOnce
            resources:
              requests:
                storage: 2Gi
            storageClassName: sc-nfs
eof
```

```powershell
# 应用
kubectl apply -f operator-elasticsearch-cluster.yaml
# 查看结果
kubectl get all -n demo && kubectl get pv,pvc -n demo
# 取出ES的访问密码
PASSWORD=$(kubectl get secret my-es-cluster-es-elastic-user -n demo -o jsonpath={.data.elastic} -n demo|base64 -d)
echo $PASSWORD
# 开启一个新的Pod测试访问 ES Cluster
kubectl run --env="PASSWORD=$PASSWORD" client-$RANDOM --image registry.cn-beijing.aliyuncs.com/wangxiaochun/admin-box:v0.1 -it --rm --restart=Never --command -- /bin/bash
curl -u "elastic:$PASSWORD" -k https://my-es-cluster-es-http.demo:9200
curl -u "elastic:$PASSWORD" -k https://my-es-cluster-es-http.demo:9200/_cat/health
curl -u "elastic:$PASSWORD" -k https://my-es-cluster-es-http.demo:9200/_cat/nodes
```













# 课外阅读

#### 常用指令

------

```powershell
# base64 编码指令 （ -n 选项确保 echo 不会输出尾随的换行符 ）
echo -n 123456 | base64

# base64 解码指令 （ -d 选项，将 Base64 编码的内容解码 ）
echo MTIzNDU2 | base64 -d
```

```powershell
查
kubectl get pod -A          # 查看所有命名空间的 Pod
kubectl get svc,deploy,cm   # 一次性查看 Service, Deployment, ConfigMap
kubectl describe node node1 # 查看节点的详细状态、资源占用和事件
kubectl logs -f <pod-name> -n <namespace> 		# -f 表示持续输出日志；
# 查看资源的实时消耗 (需要安装 metrics-server)
kubectl top node   # 查看节点 CPU/内存
kubectl top pod    # 查看 Pod 消耗
kubectl version
增
# 根据文件创建/更新资源
kubectl apply -f filename.yaml
# 创建一个命名空间
kubectl create ns my-namespace
删
# 根据文件删除资源
kubectl delete -f filename.yaml
kubectl delete po <pod-name> -n <namespace>
改
# 在线编辑资源配置 (就像 vi 一样)
kubectl edit cm coredns -n kube-system
# 扩缩容 (调整副本数)
kubectl scale deployment wordpress --replicas=3
# 更换容器镜像
kubectl set image deployment/wordpress mysql=mysql:5.7
```



#### 查日志

在 SRE 的日常工作中，**80% 的时间都在查日志**，剩下的 20% 时间在想为什么日志里啥都没有。

1. 基础中的基础：`kubectl logs`

 这是你最先要掌握的“起手式”。
>
>- **常规用法**：`kubectl logs <pod_name>`
>- **侧重点**：**快速定位单个容器的问题**。
>- **常用参数**：
>  - `-f` (follow)：实时滚动，运维排障必带。
>  - `--tail=100`：只看最后 100 行，避免大日志刷屏把终端卡死。
>  - `-p` (previous)：**极其重要！** 查看容器重启前（上一个状态）的日志。如果 Pod 崩溃重启了，不加 `-p` 你只能看到启动后的日志，找不到崩溃的原因。
>  - `-c` (container)：如果一个 Pod 里有多个容器（比如 Sidecar 模式），必须指定容器名。
>
>------
>
2. 宏观视角：`kubectl describe`

严格来说，这不叫“看日志”，但它是**排障的第一步**。

>- **指令**：`kubectl describe pod <pod_name>`
>- **侧重点**：**看“元数据”和“事件（Events）”**。
>- **应用场景**：如果 Pod 状态是 `Pending`、`ImagePullBackOff` 或 `CrashLoopBackOff`，这时候 `kubectl logs` 往往是空的，因为容器根本没跑起来！你得用 `describe` 去看 K8s 调度层的日志，看看是不是由于节点资源不足、镜像拉不下来或者挂载卷失败导致的。
>
>------
>
3. 多副本联合查杀：`stern` 或 `kubectl logs -l`

当你有一个 Deployment 跑了 10 个副本，报错随机出现在其中一个身上时，逐个查 Pod 简直是噩梦。

>- **进阶用法**：`kubectl logs -l app=nginx -f`
>- **第三方神器 (Stern)**：运维大厂标配，指令：`stern nginx`
>- **侧重点**：**多容器/多 Pod 聚合日志**。
>- **应用场景**：它能把匹配标签的所有 Pod 日志聚合在一个窗口，并且用**不同的颜色**区分不同的 Pod。这对于排查分布式系统的链路问题简直是神技！
>
4. 宿主机降维打击：`journalctl`

别忘了你是个 Linux 运维！有些问题 K8s 内部是看不到的。

>- **指令**：`journalctl -u kubelet -f` 或查看 `/var/log/syslog` (Ubuntu) / `/var/log/messages` (CentOS)。
>- **侧重点**：**K8s 组件级错误**。
>- **应用场景**：当 `kubectl` 命令都报错，或者 Pod 莫名其妙在大规模重启时，可能是宿主机的 `kubelet` 崩了，或者是 Docker/Containerd 引擎挂了。这时候你要 SSH 到 Node 节点上去看系统日志。




| **排障阶段** | **使用指令** | **侧重点**    | **解决什么问题**                        |
| ------------ | ------------ | ------------- | --------------------------------------- |
| **第一步**   | `describe`   | 事件 (Events) | 为什么跑不起来？(调度/镜像/挂载)        |
| **第二步**   | `logs`       | 应用日志      | 程序逻辑报错、代码异常、数据库连不上。  |
| **第三步**   | `logs -p`    | 临终遗言      | 容器刚才为什么突然重启了？              |
| **第四步**   | `stern`      | 聚合日志      | 多个副本里，到底是哪个在报错？          |
| **最终手段** | `journalctl` | 系统日志      | 整个节点或者 K8s 核心组件是不是拉稀了？ |





#### K8s 优化

```powershell
iptables 改为 ipvs 模式
```



#### k9s

```powershell
wget https://github.com/derailed/k9s/releases/download/v0.50.16/k9s_Linux_amd64.tar.gz
tar xf k9s_Linux_amd64.tar.gz && ls
ldd k9s
mv k9s /usr/local/bin
```

#### 好习惯

```bash
1. 凡事先声明，必留痕迹（GitOps）
做法：永远不要在命令行用 kubectl edit 直接改运行中的配置。所有变更都应该修改 YAML 文件，并提交到 Git。

理由：万一你改崩了，你可以一键回滚。如果直接在集群里改，第二天你可能就忘了自己改了啥。

2. 必须给资源设置限制（Resource Quotas）
做法：所有的 Deployment 必须写上 requests 和 limits（CPU 和内存）。

理由：防止某个贪婪的服务吃掉整台宿主机的资源，导致连 kubelet 都被挤死（OOM），最后引发集群雪崩。

3. 健康检查是标配（Liveness & Readiness）
做法：必须配置存活检查（Liveness）和就绪检查（Readiness）。

理由：别让程序还没启动完就开始接流量，也别让死掉的程序占着位子不干活。

4. 善用 Label 和 Annotation
做法：建立一套规范的标签体系（如 app: nginx, env: prod, tier: frontend）。

理由：当你面对成千上万个 Pod 时，清晰的标签就是你唯一的“救命稻草”，能让你瞬间定位问题。

5. 永远不要相信“Latest”标签
做法：镜像版本号必须明确（如 nginx:1.21.0），严禁使用 nginx:latest。

理由：latest 是个盲盒，你永远不知道下次拉镜像时会拉下来什么鬼东西，这会让生产环境失去一致性。
```

#### 坏习惯

```bash
1. 迷恋 kubectl exec
坏习惯：一有问题就钻进容器里修配置、改代码。

后果：你改的东西重启就丢了！这种“临时补丁”是典型的无状态思维陷阱。记住：容器应该是易碎品（Cattle, not Pets）。

2. 使用 Default 命名空间
坏习惯：所有的服务都堆在 default 下面。

后果：管理混乱，RBAC 权限无法精细化控制。就像把你家所有的衣服、碗筷、工具都堆在客厅正中央。

3. 以 Root 身份运行容器
坏习惯：镜像里直接用 root 用户跑程序。

后果：安全隐患巨大。一旦容器被攻破，黑客可能直接通过内核漏洞控制你的物理机。

4. 裸跑 Pod (Naked Pod)
坏习惯：直接 kubectl run 一个单独的 Pod，而不是用 Deployment 或 StatefulSet 管理。

后果：Pod 挂了没人管，没人会自动帮你拉起。在 K8s 里，没有“监护人”的 Pod 就像流浪汉。

5. 忽略日志收集和监控
坏习惯：只管跑，不看日志，不搭 Prometheus。

后果：这就是“盲人开车”。出故障时，除了重启你没有任何手段分析原因。
```



## 故障录

在这个故障之前还发生了另一个故障，导致我对 etc/kubernetes/manifests/kube-apiserver.yaml  文件进行了手工修改；也因此导致后续很多麻烦！
配置文件中原内容：    - --authorization-mode=Node,RBAC
修改后配置文件内容：    - --authorization-mode=AlwaysAllow

`--authorization-mode` 是用来定义集群如何审批 API 请求的。当你为了解决“权限报错”而将其改为 `AlwaysAllow` 时，本质上是关闭了集群的所有权限检查门禁。

虽然这解决了眼下的 `Forbidden` 错误，但会引发一系列非常严重的连锁反应；

1. 核心问题：安全性完全裸奔 （影响于未来）
2. 对集群组件的影响 （影响在当下 k8s 集群运行）

Kubernetes 的许多核心组件（如 `kubelet`、`scheduler`、`controller-manager`）都极度依赖 **Node** 和 **RBAC** 鉴权模式来保证各自的工作边界。

- **Kubelet 状态异常：** 原本的配置里有 `Node` 模式，这是专门给节点心跳和状态更新用的。改为 `AlwaysAllow` 后，虽然它们还能工作，但失去了审计这些组件行为的能力。
  
- **插件失效：** 某些依赖特定 RBAC 权限才能运行的 CNI 网络插件或存储插件，可能会因为整体授权逻辑的变化而出现行为异常。

3. “无法回退”的隐患（之后回退，出现的情况与该描述相同，于是开启下面的修复工程）

如果在 `AlwaysAllow` 模式下创建了大量资源，一旦将来想改回 `RBAC`，会发现之前“顺手”部署的很多应用都会因为没有配置对应的 `Role` 和 `RoleBinding` 而集体挂掉。

下面这份可以直接当 **kubeadm 集群急救手册**。



- 现象：cluster-info not found
- 根因：bootstrap token 没配置

```powershell
# 修复：
kubeadm init phase bootstrap-token
# 验证：
kubectl get cm -n kube-public cluster-info
```



- 现象：configmaps "kubeadm-config" not found
- 根因：init 阶段没完整执行 ；或者手动删过 kube-system 里的 CM

```powershell
# 修复：
kubeadm init phase upload-config kubeadm
# 验证：
kubectl get cm -n kube-system kubeadm-config
```



- 现象：User "system:bootstrap:xxxx" cannot get resource "configmaps"
- 根因：bootstrap RBAC 被删 / 未创建 ；或者`system:node-config-reader` 缺失

```powershell
# 创建 ClusterRole（如果没有）
kubectl get clusterrole system:node-config-reader \
|| kubectl create clusterrole system:node-config-reader \
  --verb=get,list,watch \
  --resource=configmaps
# 创建 ClusterRoleBinding（关键）
kubectl get clusterrolebinding system:node-config-reader \
|| kubectl create clusterrolebinding system:node-config-reader \
  --clusterrole=system:node-config-reader \
  --group=system:bootstrappers:kubeadm:default-node-token
# 验证：
kubectl describe clusterrolebinding system:node-config-reader
# 必须看到该内容：Group: system:bootstrappers:kubeadm:default-node-token
```



- 现象：

  ```powershell
  configmaps "kubelet-config" not found
  configmaps "kube-proxy" not found
  ```

- 根因：

  - init 产物缺失
  - kubeadm init 没跑完整

```powershell
# 补 kubelet-config
kubeadm init phase upload-config kubelet
# 验证：
kubectl get cm -n kube-system kubelet-config
# 补 kube-proxy
kubeadm init phase addon kube-proxy
# 验证
kubectl get cm -n kube-system kube-proxy
```

创建删除查看 token

```powershell
# 在 master 上生成新的 join 命令：
kubeadm token create --print-join-command
# 删除指定 token
kubeadm token delete uh7uw6.21za7ma0w9cbv1tq
# 查看 token 列表
kubeadm token list
# 确保节点通信正常
curl -k https://kubeapi.wang.org:6443/version
# 加上 verbose 查看详细进度
kubeadm join kubeapi.wang.org:6443 --token wd871e.i03nde59f3r3y3c5 \
  --discovery-token-ca-cert-hash sha256:59f295053e6017ef2324c61d290e4f4d0652aad58fbd43f685e85ddc83b7f922 \
  --v=5
```

k8s kubernetes-admin 用户赋权 （根据实际情况决定）

```powershell
# 手动操作绑定 kubernetes-admin 到 Role / ClusterRole
kubectl create clusterrolebinding kubernetes-admin \
  --clusterrole=cluster-admin \
  --user=kubernetes-admin
```

## 故障录

背景：

在做关于 ingress 相关的实验时，发现老师的实验环境早已将 haproxy 和 keepalived 高可用移除。为了同步老师的实验环境，我也将这两个服务移除，（虽然我也是一主三从的框架，但是还保留了 haproxy 和 keepalived 高可用服务）

步骤：

```powershell
# 关闭服务，多此一举！这两个服务器我都不会开机的！！！
systemctl  disable  --now  haproxy.service && systemctl  disable --now keepalived
# 编辑 /etc/hosts 文件 （这是最快最安全的办法！）
vi /etc/hosts
10.0.0.101 kubeapi.wang.org kubeapi master1.wang.org master1 nfs.wang.org
# 重点：同步到其它节点
for i in {104..106} ; do scp /etc/hosts 10.0.0.$i:/etc/hosts done
# 各节点执行
systemctl restart kubelet
# 验证 ( Ready )
kubectl get node
```



## 故障录

故事背景

> 在 k8s 集群 （架构：一主三从）中部署一套 Prometheus 体系，完成后网站无法访问，但是服务都是正常，没有相关报错！诡异！
> 通过修改 CR 清单文件 prometheus-service.yaml 中的 targetPort 参数，强制指定端口号为9090，然后重新声明这个 YAML 文件，才勉强能访问 Prometheus 网站；
> 但是这是投机取巧，因为真正的原因不是这个！正所谓前途是光明的，道路是曲折的，铺垫了前进的阶梯；
> 后续修正回来，将目光转向修改 CR 实例，但是发现有 Operator 巡回校正；
> 此时渐渐走向了正规，已经在修改 CR 清单文件；修改后声明这个清单文件，生成 CR 实例；
> 在修改 CR 清单文件中，知道了关于查看 CRD 支持的字段。
> 由于没有存活探针和就绪探针的字段，但是可以通过添加 containers 字段，在该字段中添加需要的探针配置！
>
> 在寻找真相的过程中，最困难的莫过于没有相关的报错提示，一片虚假的 Ready 和 Running。集群已失明，日志在沉默，焦急的攻城狮在排障！！！

教训

> 循序渐进，稳扎稳打，先对基础建设进行勘察！
> 修改配置必须走 CRD/CR 路径，严禁直接动底层资源。

扩展

```bash
SRE 进阶知识点： 
Prometheus Operator 为了保持灵活性，提供了一个“逃生舱门”——也就是这个 containers 字段。它允许你通过 Strategic Merge Patch（策略性合并补丁） 来修改 Operator 原生生成的容器属性。
```



结语

> 这个算是一份 “ CoreDNS 异常引发的 Prometheus 监控体系雪崩 ” 的故障样式之一了！

部分过程

> ```powershell
> # 对 CR 实例编辑失败，原因是 CRD 中没有对应的字段模板样式
> kubectl edit alertmanager main -n monitoring 
> 
> # 查看 Alertmanager 真正的定义到底支持哪些字段
> kubectl explain alertmanager.spec
> 
> # 修改 CRD 文件前，首先清除原来的资源
> kubectl delete  -f alertmanager-alertmanager.yaml 
> 
> # 通过 containers 下的定义字段添加存活等探针
> vi alertmanager-alertmanager.yaml 
> spec:
>   # ... 原有的 replicas, version 等保持不变 ...
>   containers: # 在这里动手脚
>     - name: alertmanager # 必须叫这个名，才能匹配到主容器
>       livenessProbe:
>         httpGet:
>           path: /-/healthy
>           port: web
>           scheme: HTTP
>         initialDelaySeconds: 60 # 老师建议直接给 60s，如果是虚拟机实验环境，别太吝啬
>         periodSeconds: 10
>         failureThreshold: 10
>       readinessProbe:
>         httpGet:
>           path: /-/ready
>           port: web
>           scheme: HTTP
>         initialDelaySeconds: 60
>         periodSeconds: 10
>         failureThreshold: 10
> 		
> # 应用
> kubectl apply -f alertmanager-alertmanager.yaml 
> ```
>
> 





## 综合案例

------

#### 基本需求：

- 独立部署两个wordpress Pod实例实现负载均衡和高可用，它们使用NFS StorageClass 存储卷存储用户上传的图片或文件等数据；以ConfigMap和Secret提供必要的配置
- 部署一个MySQL数据库，使用NFS StorageClass 存储卷存储，以ConfigMap和Secret提供必要的配置
- service 暴露 wordpress 的服务

#### 部署 CoreDNS 服务

```powershell
wget -O coredns.yaml https://raw.githubusercontent.com/coredns/deployment/master/kubernetes/coredns.yaml.sed
# 下载完这个文件也是有很多坑的！这是个模版文件，需要进行自定义的修改！
修改内容汇总
sed -i "s#}STUBDOMAINS#}#" coredns.yaml
vim coredns.yaml
CLUSTER_DOMAIN REVERSE_CIDRS 改为 cluster.local in-addr.arpa ip6.arpa
UPSTREAMNAMESERVER 改为 /etc/resolv.conf
CLUSTER_DNS_IP: 10.96.0.10
# 查看 coredns 地址 （如果输出是 10.96.0.0/12 或 10.96.0.0/16，那么 10.96.0.10 就是合法的 DNS 地址。）
kubectl get pod kube-apiserver-master1 -n kube-system -o yaml | grep service-cluster-ip-range

kubectl apply -f coredns.yaml
# 下面是我修改好的 YAML 文件，拿去用时注意 coredns 地址的变更哦！
cat > coredns.yaml  <<'eof'
apiVersion: v1
kind: ServiceAccount
metadata:
  name: coredns
  namespace: kube-system
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  labels:
    kubernetes.io/bootstrapping: rbac-defaults
  name: system:coredns
rules:
  - apiGroups:
    - ""
    resources:
    - endpoints
    - services
    - pods
    - namespaces
    verbs:
    - list
    - watch
  - apiGroups:
    - discovery.k8s.io
    resources:
    - endpointslices
    verbs:
    - list
    - watch
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  annotations:
    rbac.authorization.kubernetes.io/autoupdate: "true"
  labels:
    kubernetes.io/bootstrapping: rbac-defaults
  name: system:coredns
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: system:coredns
subjects:
- kind: ServiceAccount
  name: coredns
  namespace: kube-system
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: coredns
  namespace: kube-system
data:
  Corefile: |
    .:53 {
        errors
        health {
          lameduck 5s
        }
        ready
        kubernetes cluster.local in-addr.arpa ip6.arpa {
          fallthrough in-addr.arpa ip6.arpa
        }
        prometheus :9153
        forward . /etc/resolv.conf {
          max_concurrent 1000
        }
        cache 30
        loop
        reload
        loadbalance
    }
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: coredns
  namespace: kube-system
  labels:
    k8s-app: kube-dns
    kubernetes.io/name: "CoreDNS"
    app.kubernetes.io/name: coredns
spec:
  # replicas: not specified here:
  # 1. Default is 1.
  # 2. Will be tuned in real time if DNS horizontal auto-scaling is turned on.
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxUnavailable: 1
  selector:
    matchLabels:
      k8s-app: kube-dns
      app.kubernetes.io/name: coredns
  template:
    metadata:
      labels:
        k8s-app: kube-dns
        app.kubernetes.io/name: coredns
    spec:
      priorityClassName: system-cluster-critical
      serviceAccountName: coredns
      tolerations:
        - key: "CriticalAddonsOnly"
          operator: "Exists"
      nodeSelector:
        kubernetes.io/os: linux
      affinity:
         podAntiAffinity:
           requiredDuringSchedulingIgnoredDuringExecution:
           - labelSelector:
               matchExpressions:
               - key: k8s-app
                 operator: In
                 values: ["kube-dns"]
             topologyKey: kubernetes.io/hostname
      containers:
      - name: coredns
        image: coredns/coredns:1.9.4
        imagePullPolicy: IfNotPresent
        resources:
          limits:
            memory: 170Mi
          requests:
            cpu: 100m
            memory: 70Mi
        args: [ "-conf", "/etc/coredns/Corefile" ]
        volumeMounts:
        - name: config-volume
          mountPath: /etc/coredns
          readOnly: true
        ports:
        - containerPort: 53
          name: dns
          protocol: UDP
        - containerPort: 53
          name: dns-tcp
          protocol: TCP
        - containerPort: 9153
          name: metrics
          protocol: TCP
        securityContext:
          allowPrivilegeEscalation: false
          capabilities:
            add:
            - NET_BIND_SERVICE
            drop:
            - all
          readOnlyRootFilesystem: true
        livenessProbe:
          httpGet:
            path: /health
            port: 8080
            scheme: HTTP
          initialDelaySeconds: 60
          timeoutSeconds: 5
          successThreshold: 1
          failureThreshold: 5
        readinessProbe:
          httpGet:
            path: /ready
            port: 8181
            scheme: HTTP
      dnsPolicy: Default
      volumes:
        - name: config-volume
          configMap:
            name: coredns
            items:
            - key: Corefile
              path: Corefile
---
apiVersion: v1
kind: Service
metadata:
  name: kube-dns
  namespace: kube-system
  annotations:
    prometheus.io/port: "9153"
    prometheus.io/scrape: "true"
  labels:
    k8s-app: kube-dns
    kubernetes.io/cluster-service: "true"
    kubernetes.io/name: "CoreDNS"
    app.kubernetes.io/name: coredns
spec:
  selector:
    k8s-app: kube-dns
    app.kubernetes.io/name: coredns
  clusterIP: 10.96.0.10
  ports:
  - name: dns
    port: 53
    protocol: UDP
  - name: dns-tcp
    port: 53
    protocol: TCP
  - name: metrics
    port: 9153
    protocol: TCP
eof
```



#### 准备基于NFS的 StorageClass

```powershell
# 准备NFS共享存储
mkdir -p /data/sc-nfs
apt update &&apt -y install nfs-server
echo "/data/sc-nfs *(rw,no_root_squash)" >> /etc/exports
exportfs -r && exportfs -v
# 在所有worker节点安装 nfs 客户端
apt -y install nfs-common
```

```powershell
# 创建独立的名称空间
kubectl create ns sc-nfs
# 指定名称空间
cat > rbac.yaml <<'eof'
apiVersion: v1
kind: ServiceAccount
metadata:
  name: nfs-client-provisioner
  # replace with namespace where provisioner is deployed
  #namespace: default
  namespace: sc-nfs
---
kind: ClusterRole
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: nfs-client-provisioner-runner
rules:
  - apiGroups: [""]
    resources: ["nodes"]
    verbs: ["get", "list", "watch"]
  - apiGroups: [""]
    resources: ["persistentvolumes"]
    verbs: ["get", "list", "watch", "create", "delete"]
  - apiGroups: [""]
    resources: ["persistentvolumeclaims"]
    verbs: ["get", "list", "watch", "update"]
  - apiGroups: ["storage.k8s.io"]
    resources: ["storageclasses"]
    verbs: ["get", "list", "watch"]
  - apiGroups: [""]
    resources: ["events"]
    verbs: ["create", "update", "patch"]
---
kind: ClusterRoleBinding
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: run-nfs-client-provisioner
subjects:
  - kind: ServiceAccount
    name: nfs-client-provisioner
    # replace with namespace where provisioner is deployed
    #namespace: default
    namespace: sc-nfs
roleRef:
  kind: ClusterRole
  name: nfs-client-provisioner-runner
  apiGroup: rbac.authorization.k8s.io
---
kind: Role
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: leader-locking-nfs-client-provisioner
  # replace with namespace where provisioner is deployed
  #namespace: default
  namespace: sc-nfs
rules:
  - apiGroups: [""]
    resources: ["endpoints"]
    verbs: ["get", "list", "watch", "create", "update", "patch"]
---
kind: RoleBinding
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: leader-locking-nfs-client-provisioner
  # replace with namespace where provisioner is deployed
  #namespace: default
  namespace: sc-nfs
subjects:
  - kind: ServiceAccount
    name: nfs-client-provisioner
    # replace with namespace where provisioner is deployed
    #namespace: default
    namespace: sc-nfs
roleRef:
  kind: Role
  name: leader-locking-nfs-client-provisioner
  apiGroup: rbac.authorization.k8s.io
eof

kubectl apply -f rbac.yaml
kubectl get sa
```

部署 NFS-Subdir-External-Provisioner 对应的 Deployment

```powershell
cat > nfs-client-provisioner.yaml <<'eof'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nfs-client-provisioner
  labels:
    app: nfs-client-provisioner
  # replace with namespace where provisioner is deployed
  #namespace: default
  namespace: sc-nfs
spec:
  replicas: 1	# 这里的副本数根据实际情况决定；为了实现高可用
  strategy:
    type: Recreate
  selector:
    matchLabels:
      app: nfs-client-provisioner
  template:
    metadata:
      labels:
        app: nfs-client-provisioner
    spec:
      serviceAccountName: nfs-client-provisioner
      containers:
        - name: nfs-client-provisioner
          image: registry.cn-beijing.aliyuncs.com/wangxiaochun/nfs-subdir-external-provisioner:v4.0.2
          #image: wangxiaochun/nfs-subdir-external-provisioner:v4.0.2
          #image: k8s.gcr.io/sig-storage/nfs-subdir-external-provisioner:v4.0.2
          imagePullPolicy: IfNotPresent
          volumeMounts:
            - name: nfs-client-root
              mountPath: /persistentvolumes
          env:
            - name: PROVISIONER_NAME
              value: k8s-sigs.io/nfs-subdir-external-provisioner #名称确保与 nfs-StorageClass.yaml文件中的provisioner名称保持一致
            - name: NFS_SERVER
              value: nfs.wang.org # NFS SERVER_IP 
            - name: NFS_PATH
              value: /data/sc-nfs  # NFS 共享目录
      volumes:
        - name: nfs-client-root
          nfs:
            server: nfs.wang.org  # NFS SERVER_IP 
            path: /data/sc-nfs  # NFS 共享目录
eof

kubectl apply -f nfs-client-provisioner.yaml
kubectl get deployments.apps -n sc-nfs 
kubectl get pod -A
# 注意:如果失败,检查是否worker节点安装了nfs-client
```

创建 NFS 资源的 StorageClass

```powershell
cat > nfs-StorageClass.yaml <<'eof'
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: sc-nfs 
  annotations:
    storageclass.kubernetes.io/is-default-class: "false"  # 是否设置为默认的storageclass
provisioner: k8s-sigs.io/nfs-subdir-external-provisioner # or choose another name, must match deployment's env PROVISIONER_NAME'
parameters:
  archiveOnDelete: "true" # 设置为"false"时删除PVC不会保留数据,"true"则保留数据
eof

kubectl apply -f nfs-StorageClass.yaml
kubectl get sc
```







#### 部署 Metallb 的 LB 服务

- 部署MetalLB 前准备

> - **如果 kube-proxy工作于ipvs模式，必须使用严格ARP（StrictARP）模式，因此若有必要，先运行如下命令，配置kube-proxy。**
> - 步骤说明：修改 `kube-proxy` 的配置：打开 `strictARP: true`
> - 作用：防止同一个 IP 被“多人认领”

```powershell
kubectl edit configmap kube-proxy -n kube-system -o yaml > kube-proxy.yaml
sed -e "s/strictARP: false/strictARP: true/" kube-proxy.yaml
kubectl apply -f - -n kube-system
kubectl rollout restart ds kube-proxy -n kube-system
```

- 部署 MetalLB 至 Kubernetes 集群

```powershell
METALLB_VERSION='v0.15.3'
wget https://raw.githubusercontent.com/metallb/metallb/${METALLB_VERSION}/config/manifests/metallb-native.yaml
kubectl apply -f metallb-native.yaml		# speaker 是 DaemonSet；意义是：每个节点都可能需要对外宣告 IP
kubectl get pods -n metallb-system
```

- 创建地址池

```powershell
cat > service-metallb-IPAddressPool.yaml <<'eof'
apiVersion: metallb.io/v1beta1
kind: IPAddressPool
metadata:
  name: localip-pool
  namespace: metallb-system
spec:
  addresses:
  - 10.0.0.10-10.0.0.50
  # 这个地址池必须是在宿主机网段，但不能与宿主机冲突
  autoAssign: true
  avoidBuggyIPs: true
eof
```

- 创建二层公告机制


```powershell
cat > service-metallb-L2Advertisement.yaml <<'eof'
apiVersion: metallb.io/v1beta1
kind: L2Advertisement
metadata:
  name: localip-pool-l2a
  namespace: metallb-system
spec:
  ipAddressPools:
  - localip-pool
  interfaces:
  - eth0 				# 用于发送免费ARP公告
eof
```

```powershell
kubectl apply -f service-metallb-IPAddressPool.yaml && kubectl apply -f service-metallb-L2Advertisement.yaml
kubectl get svc
kubectl get IPAddressPool -n metallb-system
kubectl get all -n metallb-system
```

- 创建 Service 和 Deployment

```powershell
# 创建Deployment和LoadBalancer类型的Service，测试地址池是否能给Service分配LoadBalancer IP
kubectl create deployment myapp --image=registry.cn-beijing.aliyuncs.com/wangxiaochun/pod-test:v0.1 --replicas=3
cat > service-loadbalancer-lbaas.yaml <<'eof'
apiVersion: v1
kind: Service
metadata:
  name: service-loadbalancer-lbaas
spec:
  type: LoadBalancer
  externalTrafficPolicy: Local
  selector:
    app: myapp
  ports:
  - name: http
    protocol: TCP
    port: 80
    targetPort: 80
eof
kubectl apply -f service-loadbalancer-lbaas.yaml
kubectl get ep
# 查看到分配了外部IP
kubectl get svc service-loadbalancer-lbaas -o wide
# 从集群外可以访问 (IP 地址视情况而定)
C:\Users\Administrator> curl 10.0.0.10
```



#### 部署 MySQL 的相关资源

```powershell
cat > storage-wordpress-mysql.yaml <<'eof'
apiVersion: v1
kind: Secret
metadata:
  name: mysql-pass
type: kubernetes.io/basic-auth
#type: Opaque  #也可以用Opaque类型
data:
  password: MTIzNDU2             # key 名称:password，value 为 123456
  
---
apiVersion: v1
kind: Service
metadata:
  name: wordpress-mysql
  labels:
    app: wordpress
spec:
  ports:
    - port: 3306
  selector:
    app: wordpress
    tier: mysql
  clusterIP: None
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: mysql-pv-claim
  labels:
    app: wordpress
spec:
  storageClassName: sc-nfs  # 需要和前面创建的storageClass名称相同,如果是默认的storageClass,此项可选
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 20Gi
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: wordpress-mysql
  labels:
    app: wordpress
spec:
  selector:
    matchLabels:
      app: wordpress
      tier: mysql
  strategy:
    type: Recreate
  template:
    metadata:
      labels:
        app: wordpress
        tier: mysql
    spec:
      containers:
      - image: registry.cn-beijing.aliyuncs.com/wangxiaochun/mysql:8.0.29-oracle
        name: mysql
        env:
        - name: MYSQL_ROOT_PASSWORD
          valueFrom:
            secretKeyRef:
              name: mysql-pass
              key: password
        - name: MYSQL_DATABASE
          value: wordpress
        - name: MYSQL_USER
          value: wordpress
        - name: MYSQL_PASSWORD
          valueFrom:
            secretKeyRef:
              name: mysql-pass
              key: password
        ports:
        - containerPort: 3306
          name: mysql
        volumeMounts:
        - name: mysql-persistent-storage
          mountPath: /var/lib/mysql
      volumes:
      - name: mysql-persistent-storage
        persistentVolumeClaim:
          claimName: mysql-pv-claim
eof

kubectl apply -f storage-wordpress-mysql.yaml
kubectl get pod
```

#### 部署 wordpress 相关资源

```powershell
cat > storage-wordpress-wordpress.yaml <<'eof'
apiVersion: v1
kind: Service
metadata:
  name: wordpress
  labels:
    app: wordpress
spec:
  ports:
    - port: 80
  selector:
    app: wordpress
    tier: frontend
  type: LoadBalancer
  sessionAffinity: ClientIP    # 会话保持
  externalTrafficPolicy: Local # DNAT
  # type: ClusterIP  # 如果部署了ingress 可以使用此项
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: wp-pv-claim
  labels:
    app: wordpress
spec:
  storageClassName: sc-nfs  # 需要和前面创建的 storageClass 名称相同,如果是默认的 storageClass ，此项可选
  accessModes:
    - ReadWriteMany
  resources:
    requests:
      storage: 20Gi
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: wordpress
  labels:
    app: wordpress
spec:
  replicas: 1
  selector:
    matchLabels:
      app: wordpress
      tier: frontend
  strategy:
    type: Recreate
  template:
    metadata:
      labels:
        app: wordpress
        tier: frontend
    spec:
      containers:
      - image: registry.cn-beijing.aliyuncs.com/wangxiaochun/wordpress:php8.2-apache
        name: wordpress
        env:
        - name: WORDPRESS_DB_HOST
          value: wordpress-mysql
        - name: WORDPRESS_DB_PASSWORD
          valueFrom:
            secretKeyRef:
              name: mysql-pass
              key: password
        - name: WORDPRESS_DB_USER
          value: wordpress
        ports:
        - containerPort: 80
          name: wordpress
        volumeMounts:
        - name: wordpress-persistent-storage
          # mountPath: /var/www/html  # 此方式性能较差
          mountPath: /var/www/html/wp-content/uploads # 此方式性能较好，wordpress的配置不能实现多个Pod同步
      volumes:
      - name: wordpress-persistent-storage
        persistentVolumeClaim:
          claimName: wp-pv-claim

eof

kubectl apply -f storage-wordpress-wordpress.yaml
kubectl get pv,pvc,po
ls /data/sc-nfs
kubectl get svc
# 进行扩容
kubectl  scale deployment wordpress --replicas 2
# 查看
kubectl  get pod -o wide
```

> 至此，粗略的完成了使用持久卷和 CM 等部署 WordPress 和 MySQL 任务；
>
> - 虽然对 wordpress 进行了高可用的扩容，但是 MySQL 容器还是单点，所以 MySQL 所在的设备出故障，服务也得挂！
> - 因为没有做会话保持，所以 wordpress 容器漂移或者重启都会对业务产生较大的影响！影响最直接最明显的就是重新登录！

扩展需求

- 部署一个独立的ingress或者nginx Pod实例，为wordpress提供反向代理
- 同时提供https和http虚拟主机，其中发往http的请求都重定向给https；以ConfigMap和Secret提
- 供必要的配置
- 动态的蓝绿发布和滚动发布
  - 对于wordpress 来说，没有本质的区别
  - nginx的更新，依赖configmap和secret的内容

##### Ingress

###### 基于 kubectl apply 部署 

```powershell
# 下载 YAML 文件
wget https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.14.1/deploy/static/provider/cloud/deploy.yaml
# 选择版本，添加变量
VERSION=1.14.1
# 查看资源
grep '^kind' deploy.yaml
修改文件
# 注释原来的镜像，添加国内镜像源；修改三处 image
# 另外建立将副本数设置为二个或三个！默认是一个！
image: registry.cn-hangzhou.aliyuncs.com/google_containers/nginx-ingress-controller:v1.14.1
image: registry.k8s.io/ingress-nginx/kube-webhook-certgen:v1.6.5
grep image: deploy.yaml

kubectl apply -f deploy.yaml
```

###### 创建 service Ingress

```powershell
# 准备环境实现两个 service 应用 pod-test1 和 pod-test2
kubectl create deployment pod-test1 --image=registry.cn-beijing.aliyuncs.com/wangxiaochun/pod-test:v0.1 --replicas=3
kubectl create service clusterip pod-test1 --tcp=80:80
kubectl create deployment pod-test2 --image=registry.cn-beijing.aliyuncs.com/wangxiaochun/pod-test:v0.2 --replicas=3
kubectl create service clusterip pod-test2 --tcp=80:80
# 查看
kubectl get svc,endpoints,po -o wide
# 创建 Ingress 规则
kubectl create ingress ingress-duan --rule=www.duan.org/*=pod-test1:80 --class=nginx --dry-run=client -o yaml > ingress-duan.yaml
kubectl apply -f ingress-duan.yaml && kubectl get ingress
# 测试
curl -H "Host: www.duan.org" 10.0.0.10
```

###### 实验后续拓展

改 LoadBalance 为 Noteport  

从外面访问一个 k8s 集群，除了 LoadBalance 就是 Noteport，接下来改用 Noteport 作为对外的窗口！

```powershell
# 停止 IP 地址池供应，或者停止其他的 Metallb 服务；主要是模拟没有 Metallb 的环境
kubectl delete -f service-metallb-IPAddressPool.yaml
# 停止 nginx-controller 服务，编辑 nginx-controller yaml文件
kubectl delete -f deploy.yaml
# 将 Service 类型由 LoadBalancer 改为 NodePort
sed -i 's#type: LoadBalancer#type: NodePort#' deploy.yaml
vi deploy.yaml
externalTrafficPolicy: Local	改为	externalTrafficPolicy: Cluster		
# 若是 LoadBalance 对外提供 IP ，则使用默认的 Local，而且不需要改动！
# 因为设置为 Cluster，所以访问 node1 的 30080 时，即使 node1 上的 Pod 没准备好，node1 的 kube-proxy 也会把流量通过隧道转发给 Ready 的 Pod。

kubectl apply -f deploy.yaml
kubectl get  svc -n ingress-nginx  -o yaml | grep externalTrafficPolicy
```

```powershell
# 固定七层访问端口
kubectl edit svc ingress-nginx-controller -n ingress-nginx
# 修改内容如下：
spec:
  type: NodePort
  ports:
  - name: http
    port: 80
    protocol: TCP
    targetPort: http
    nodePort: 30080  # 固定 HTTP 端口
  - name: https
    port: 443
    protocol: TCP
    targetPort: https
    nodePort: 30443  # 固定 HTTPS 端口
```

```powershell
# 找一台设备，安装 HAProxy ，（ 这里我复用的 10.0.0.106 设备 ）编辑配置文件
vi /etc/haproxy/haproxy.cfg
backend ingress
    mode tcp
    bind *:80
    server node1 10.0.0.104:30080 check inter 3s fall 3 rise 3
    server node2 10.0.0.105:30080 check inter 3s fall 3 rise 3

systemctl reload haproxy
```

```powershell
# 在宿主机添加域名，并测试
10.0.0.106 www.duan.org
# 测试
curl -H "host: www.duan.org" 10.0.0.104:30080
# 流量图
客户端请求 ————> HAProxy(10.0.0.106:80) ————> 任意Node(10.0.0.x:30080) ————> iptables转发 ————> Ready状态的Ingress Pod ————> 后端业务Pod
```



改 Noteport 为 LoadBalance 

```powershell
systemctl  disable  --now  haproxy.service

kubectl apply -f service-metallb-IPAddressPool.yaml
# type: NodePort 改为 type: LoadBalancer ；externalTrafficPolicy: Cluster	改为	externalTrafficPolicy: 	Local
kubectl  edit svc ingress-nginx-controller  -n ingress-nginx 
# 验证
kubectl  get svc ingress-nginx-controller  -n ingress-nginx -o yaml | egrep "externalTrafficPolicy|LoadBalancer"
kubectl get svc,IPAddressPool -A -o wide
```





# K8s 集成 Prometheus

**基于 Operator 部署 Prometheus**

- 下载网址：[prometheus-operator/kube-prometheus: Use Prometheus to monitor Kubernetes and applications running on Kubernetes](https://github.com/prometheus-operator/kube-prometheus)

```powershell
# 查看 K8S 版本，然后下载对应的 operator 版本
kubectl version
# 获取代码
cd /usr/local
VERSION=0.16
wget https://github.com/prometheus-operator/kube-prometheus/archive/refs/tags/v${VERSION}.0.tar.gz
tar xf v${VERSION}.0.tar.gz
cd /usr/local/kube-prometheus-${VERSION}.0/manifests/
du -sh /usr/local/kube-prometheus-${VERSION}.0
```

#### 修改配置

```powershell
# 创建命名空间
kubectl create ns monitoring
# 修改 prometheus 的 service ; 安装 Metallb 参考之前的笔记！
vim /usr/local/kube-prometheus-0.16.0/manifests/prometheus-service.yaml
spec:
  type: LoadBalancer		# 修改类型
  ports:
  - name: web
    port: 9090
    targetPort: web			# 如果后续对外暴露的IP不能登录，很可能是端口冲突；可以强制指向 Pod 里的 Prometheus 业务端口
    nodePort: 30090			# 固定端口号
# 修改grafana的service
vim /usr/local/kube-prometheus-0.16.0/manifests/grafana-service.yaml
spec:
  type: LoadBalancer
  ports:
  - name: http
    port: 3000
    targetPort: http
    nodePort: 30030
# 修改 alertmanager 的 service
vim /usr/local/kube-prometheus-0.16.0/manifests/alertmanager-service.yaml
spec:
  type: LoadBalancer
  ports:
  - name: web
    port: 9093
    targetPort: web
    nodePort: 30093
```

相信科学！

```powershell
# 默认有些镜像无法下载,修改依赖镜像,将相关镜像都改为私有仓库里面的镜像
cd /usr/local/kube-prometheus-0.16.0/manifests/
# 如果不能科学上网，参考课件 11.1.3.4
```

#### 启动项目

```powershell
# 如果提示 Too long 出错，基本上可以肯定是用 apply 启动；
# 推荐 apply 启动，因为其具有幂等性；但是由于文件太大，只能使用 create 启动；
cd /usr/local/kube-prometheus-0.16.0/manifests && kubectl create  -f setup/ 
# 检查效果
kubectl get crd | grep monitoring.coreos.com 
cd /usr/local/kube-prometheus-0.16.0/manifests && kubectl apply -f ./
# 检查效果  
kubectl  get pod -n monitoring 
```

Prometheus 监控 K8s 资源默认仅支持这五个组件资源：

- node

- svc

- ingress

- port

- endpoint


如果需要扩展监控的资源类型，需要 kube-state-metrics 这个插件，相当于 K8s  exporter （暴露指标！）

```powershell
# 查看对外暴露的 IP 和端口号
kubectl  get svc -n monitoring 
登录 Prometheus ：10.0.0.12:9090		或者	10.0.0.101：30090
# 测试，创建 pod ，观察 Prometheus 网页变化
kubectl create deployment myapp --image registry.cn-beijing.aliyuncs.com/wangxiaochun/pod-test:v0.1 --replicas 3
kubectl get pod
网页：kube_pod_info  或者  kube_deployment_created

登录 Alertmanager	：10.0.0.10:9093

登录 Grafana	：10.0.0.11:3000		# 账户密码默认 admin
Connectins ——> Data sources ——> prometheus
Dashboards ——> 
```

重点

```powershell
# 注意:新版中需要删除相应的 networkPolicy 才能访问，如果是使用calico的网络插件，需要删除下面的 networkPolicy
kubectl delete -f manifests/prometheus-networkPolicy.yaml
kubectl delete -f manifests/grafana-networkPolicy.yaml
```

#### 创建 Ingress （可选）

默认 SVC 是 clusterIP 模式，无法外部访问，可以创建 Ingress 实现外部访问；（上面部署是通过 Metallb LB 实现的外部访问）

用 ingress 做外部访问，就不需要上面添加端口的操作了！通过域名访问网站；

```powershell
cat > kube-prometheus-ingress.yaml <<'eof'
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: prometheus
  namespace: monitoring
  labels:
    app: prometheus
spec:
  ingressClassName: nginx
  rules:
  - host: prometheus.duan.org
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: prometheus-k8s
            port:
              number: 9090
  - host: grafana.duan.org
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: grafana
            port:
              number: 3000
  - host: alertmanager.duan.org
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: alertmanager-main
            port:
              number: 9093
  - host: blackbox.duan.org
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: blackbox-exporter
            port:
              number: 19115
eof
```

```powershell
# 下载 YAML 文件
wget https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.14.1/deploy/static/provider/cloud/deploy.yaml
```

```powershell
# 应用
kubectl apply -f kube-prometheus-ingress.yaml  -f deploy.yaml 
kubectl apply -f probe-example.yaml -f servicemonitor-example.yaml 
# 查看对外暴露的 IP 地址
kubectl get svc -n ingress-nginx
# 测试
curl -L -H "Host: prometheus.duan.org" http://10.0.0.13 -v
# 浏览器访问，需要提前做域名解析
10.0.0.13 prometheus.duan.org  grafana.duan.org alertmanager.duan.org lackbox.duan.org
```

#### 准备黑盒监控信息

```powershell
cat > probe-example.yaml <<'eof'
apiVersion: monitoring.coreos.com/v1
kind: Probe
metadata:
  name: web-probe-demo
  namespace: monitoring
spec:
  jobName: http-get
  interval: 60s
  module: http_2xx
  prober:
    url: blackbox-exporter.monitoring.svc:19115
    scheme: http
    path: /probe
  targets:
    staticConfig:
      static:
      - http://www.wangxiaochun.com
      - https://www.google.com
eof
```

准备Service的监控信息

```powershell
cat > servicemonitor-example.yaml <<'eof'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: metrics-app
spec:
  replicas: 2
  selector:
    matchLabels:
      app: metrics-app
      controller: metrics-app
  template:
    metadata:
      labels:
        app: metrics-app
        controller: metrics-app
      annotations:
        prometheus.io/scrape: "true"        # 允许prometheus抓取指标，默认不允许
        prometheus.io/port: "80"            # 允许prometheus抓取指标的端口
        prometheus.io/path: "/metrics"      # 允许prometheus抓取指标的URL，此为默认值
    spec:
      containers:
      - image: registry.cn-beijing.aliyuncs.com/wangxiaochun/metrics-app:v0.1
        name: metrics-app
        ports:
        - name: web
          containerPort: 80
        resources:
          requests:
            memory: "256Mi"
            cpu: "500m"
          limits:
            memory: "256Mi"
            cpu: "500m"
---
apiVersion: v1
kind: Service
metadata:
  name: metrics-app
  labels:
    app: metrics-app
spec:
  type: ClusterIP
  ports:
  - name: web
    port: 80
    targetPort: 80
  selector:
    app: metrics-app
    controller: metrics-app
---
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: metrics-app-servicemonitor
  labels:
    app: metrics-app
    release: prometheus
spec:
  selector:
    matchLabels:
      app: metrics-app
  # namespaceSelector:
  #   matchNames:
  #   - default
  endpoints:
  - port: web
    interval: 15s
eof
```





# Helm

官方网址：[舵手](https://helm.sh/)

插件：https://artifacthub.io/packages/search?kind=6

相关概念

Helm 3 的变化

### 安装部署

```powershell
wget https://get.helm.sh/helm-v4.0.4-linux-amd64.tar.gz
tar xf helm-v4.0.4-linux-amd64.tar.gz  -C /usr/local/
ls /usr/local/linux-amd64/
ln -s /usr/local/linux-amd64/helm /usr/local/bin/
ldd /usr/local/bin/helm
# Helm命令补会,重新登录生效
helm completion bash > /etc/bash_completion.d/helm && exit
```

### 指令

```powershell
# 添加远程仓库并命名,如下示例
helm repo add bitnami https://charts.bitnami.com/bitnami
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo add myharbor https://harbor.wangxiaochun.com/chartrepo/myweb --username admin --password 123456
```

```powershell
# 查看本地配置的仓库
helm repo list
# 从 hub 官方仓库搜索 Mysql
helm search hub mysqls
# 从本地配置的仓库地址去搜 Mysql
helm search repo mysql
# 从本地配置的仓库地址去搜指定版本的 Mysql （注意：这个版本号是 Chart）
helm search repo mysql --versions 10.3.0
# 添加一个 Chart 仓库，生成的仓库配置内容存放在 ~/.config/helm/repositories.yaml 文件中；URL 链接就在该文件中定义的！
tree ~/.config
# 拉取文件
helm pull oci://registry-1.docker.io/bitnamicharts/mysqls
```

```powershell
# 更新仓库,相当于apt update
helm repo update
# 删除仓库
helm remove 仓库名
```

### 案例：安装单机 MySQL 8.0

默认配置了魔法！

**StorageClass 类型存储参考之前的笔记**；

作为运维工程师，我们不建议直接 `helm install`，而是先拉取配置，改好了再上线。

在 Kubernetes (K8s) 环境下，部署 MySQL 的“工业标准”通常是使用 **Bitnami** 提供的 Helm Chart。它封装得非常好，安全且易于扩展。

```powershell
# 添加 StorageClass 存储类，名称：sc-nfs
# 添加并更新仓库
helm repo add bitnami https://charts.bitnami.com/bitnami
helm repo update
helm repo list
# 下载 chart 包
helm pull bitnami/mysql --version 10.3.0
tar xf mysql-10.3.0.tgz && cd mysql && ls
# 安装 （ 拉不下来 ）
helm install mysql bitnami/mysql --version 10.3.0 --set primary.persistence.storageClass=sc-nfs
# 清空，我来助你！！！
helm install mysql bitnami/mysql --version 10.3.0 \
  --set primary.persistence.storageClass=sc-nfs \
  --set image.registry=registry.cn-beijing.aliyuncs.com \
  --set image.repository=wangxiaochun/bitnami-mysql \
  --set image.tag=8.0.37-debian-12-r
下载完成后保存界面信息
# 查看密码 （相关信息在下载后的界面信息中显示）
kubectl get secret --namespace default mysql -o jsonpath="{.data.mysql-root-password}" | base64 -d
# 定义密码变量
MYSQL_ROOT_PASSWORD=$(kubectl get secret --namespace default mysql -o jsonpath="{.data.mysql-root-password}" | base64 -d)
# 测试启动
kubectl run mysql-client --rm --tty -i --restart='Never' --image  registry.cn-beijing.aliyuncs.com/wangxiaochun/bitnami-mysql:8.0.37-debian-12-r --namespace default --env MYSQL_ROOT_PASSWORD=$MYSQL_ROOT_PASSWORD --command -- bash
mysql -h mysql.default.svc.cluster.local -uroot -p"$MYSQL_ROOT_PASSWORD"
或者通过无头服务访问
mysql -h mysql-headless.default.svc.cluster.local -uroot -p"$MYSQL_ROOT_PASSWORD"
```

```powershell
# 查看
kubectl get po,pvc,svc,sts,cm
kubectl describe po mysql-0   
回退 （没问题，别动这个！）
helm uninstall mysql && kubectl delete pvc data-mysql-0 && kubectl get pvc,pod && helm list
# 扩展指令：移除远程仓库
helm repo remove bitnami ingress-nginx && helm repo list
```

二选一

```powershell
# 添加 StorageClass 存储类，名称：sc-nfs
# 添加并更新仓库
helm repo add bitnami https://charts.bitnami.com/bitnami
helm repo update && helm repo list
# 指定值文件 values.yaml 内容实现定制 Release
helm show values bitnami/mysql --version 10.3.0 > values.yaml
vim values.yaml
image:
  registry: registry.cn-beijing.aliyuncs.com
  repository: wangxiaochun/bitnami-mysql
  tag: 8.0.37-debian-12-r
auth:
  rootPassword: "123123"
  database: m65
  username: duan
  password: "234234"
persistence:
  storageClass: "sc-nfs"

helm install mysql bitnami/mysql --version 10.3.0 -f values.yaml
# 测试
MYSQL_ROOT_PASSWORD=$(kubectl get secret --namespace default mysql -o jsonpath="{.data.mysql-root-password}" | base64 -d)
kubectl run mysql-client --rm --tty -i --restart='Never' --image  registry.cn-beijing.aliyuncs.com/wangxiaochun/bitnami-mysql:8.0.37-debian-12-r --namespace default --env MYSQL_ROOT_PASSWORD=$MYSQL_ROOT_PASSWORD --command -- bash
mysql -h mysql.default.svc.cluster.local -uroot -p123123
show databases;
exit
mysql -h mysql.default.svc.cluster.local -uduan -p234234
show databases;
```

注意事项：

- #### 安装时必须指定存储卷，否则会处于 Pending 状态；

  - 如果指定了默认的storageClass，可以不提定primary.persistence.storageClass=sc-nfs
    helm install mysql bitnami/mysql --version 10.3.0 --set primary.persistence.storageClass=sc-nfs

- MySQL 8.0 的密码插件问题

- MySQL 是内存大户。在 `values.yaml` 里一定要限制 `resources.limits.memory`





### 案例：MySQL 主从复制

默认配置了魔法！

**StorageClass 类型存储参考之前的笔记**；

```powershell
# 添加 StorageClass 存储类，名称：sc-nfs
# 添加并更新仓库
helm repo add bitnami https://charts.bitnami.com/bitnami
helm repo update && helm repo list

方法一：通过仓库
略

方法二：通过OCI协议一键安装
helm install mysql bitnami/mysql --version 10.3.0 \
--set image.registry=registry.cn-beijing.aliyuncs.com \
--set image.repository=wangxiaochun/bitnami-mysql \
--set image.tag=8.0.37-debian-12-r \
--set auth.rootPassword='P@ssw0rd' \
--set global.storageClass=sc-nfs \
--set auth.database=wordpress \
--set auth.username=wordpress \
--set auth.password='P@ssw0rd' \
--set architecture=replication \
--set secondary.replicaCount=1 \
--set auth.replicationPassword='P@ssw0rd' \
-n wordpress --create-namespace

MYSQL_ROOT_PASSWORD=$(kubectl get secret --namespace wordpress mysql -o jsonpath="{.data.mysql-root-password}" | base64 -d)
kubectl run mysql-client --rm --tty -i --restart='Never' --image  registry.cn-beijing.aliyuncs.com/wangxiaochun/bitnami-mysql:8.0.37-debian-12-r --namespace wordpress --env MYSQL_ROOT_PASSWORD=$MYSQL_ROOT_PASSWORD --command -- bash
mysql -h mysql-primary.wordpress.svc.cluster.local -uroot -p"$MYSQL_ROOT_PASSWORD"
mysql -h mysql-secondary.wordpress.svc.cluster.local -uroot -p"$MYSQL_ROOT_PASSWORD"
show processlist;
```

```powershell
回退
helm uninstall mysql -n wordpress && kubectl  get all -n wordpress && kubectl get ns		# 清理干净之后再删除空间名称
kubectl  delete ns wordpress && kubectl get ns
```



### 案例：基于 Helm 部署 Harbor

官方网址：https://goharbor.cn/docs/2.13.0/install-config

官方网站：https://artifacthub.io/packages/helm

推荐将 Harbor 部署在 k8s 集群之外；

- 镜像仓库是运维的“命根子”。如果 K8s 集群炸了，你的恢复工具（镜像）还在这个集群里，那就会陷入“先有鸡还是先有蛋”的死循环。

**先决条件**

- Kubernetes 集群 1.10+
- Helm 2.8.0+
- 具体的查看官方文档

**实现流程**

- 使用 helm 将 harbor 部署到 kubernetes 集群
- 使用 ingress 发布到集群外部
- 使用 PVC 持久存储

**默认安装**

```powershell
# 安装前准备，比如：metallb、添加仓库、helm 等部署前准备
# ingress controller 基于nginx实现
# SC名称为sc-nfs，并设为默认的SC

kubectl get sc
# 把 sc-nfs 设为默认存储类
kubectl patch storageclass sc-nfs -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"true"}}}'
# 在 artifacthub 官网搜索
helm search hub harbor
# 添加仓库配置
helm repo add harbor https://helm.goharbor.io
helm repo list
# 基于本地添加仓库搜索
helm search repo harbor

方法一：
helm install myharbor harbor/harbor \
  --set expose.ingress.className=nginx \
  --set expose.tls.enabled=false  # 如果没配证书，建议先关掉，否则会跳404或证书错误
方法二 （不推荐）
# 安装
helm install myharbor harbor/harbor
# 修改ingressClass
kubectl edit ingress myharbor-ingress
spec: #添加下面一行
  ingressClassName: nginx
# 查看分配到的 IP
kubectl get ingress

# 域名解析 core.harbor.domain --> 10.0.0.13
# 默认值，用户名密码		admin	Harbor12345
# 浏览器访问默认域名 ： https://core.harbor.domain/
```

- 使用默认安装，第一个harbor表示repo仓库名，第二个harbor表示chart名；
- 此方式如果没有配置默认的SC,会因为缺少持久化存储配置导致 pending
  

```powershell
回退
helm uninstall myharbor &&  kubectl get pvc			# 手动将相关的 PVC 删除
# 如果不是默认的 SC ，但是又没有指定，可以试试这个
helm upgrade myharbor harbor/harbor \
  --set persistence.persistentVolumeClaim.registry.storageClass=sc-nfs \
  --set persistence.persistentVolumeClaim.chartmuseum.storageClass=sc-nfs \
  --set persistence.persistentVolumeClaim.jobservice.storageClass=sc-nfs \
  --set persistence.persistentVolumeClaim.database.storageClass=sc-nfs \
  --set persistence.persistentVolumeClaim.redis.storageClass=sc-nfs
```



# 自定义 Chart



```powershell
# 示例：下载 harbor 的 chart 文件
helm pull harbor/harbor
# 查看压缩包里面的 chart 文件
tar tf harbor*

helm show chart harbor	=	cat harbor/Chart.yaml
```

隋唐小测试

```powershell
helm create mychart
rm -rf mychart/templates/* mychart/charts
tree mychart
# 修改 Chart.yaml
grep -v "#" mychart/Chart.yaml
apiVersion: v2
name: myapp
description: A Helm chart for Kubernetes
type: application
version: 1.2.3
appVersion: "6.6.6"

# 修改 values.yaml
vim mychart/values.yaml
NAME: "wangxiaochun"
USER:
  AGE: "18"
  CITY: "beijing"

# 修改 templates.yaml
vim mychart/templates/configmap.yaml
apiVersion: v1
kind: ConfigMap
metadata:
    name: {{ .Release.Name }}-configmap
    namespace: {{ .Release.Namespace }}-
data:
    data1: "{{ .Release.Revision }}" # 获取此次修订的版本号。初次安装时为1，每次升级或回滚都会递增
    data2: "{{ .Release.Service }}" # 获取渲染当前模板的服务名称。一般都是 Helm
    data3: "{{ .Release.IsInstall }}" # 如果当前操作是安装，该值为 true
    data4: "{{ .Release.IsUpgrade }}" # 如果当前操作是升级或回滚，该值为true
    data5: "{{ .Release.Name }}" # Release 名称
    data6: "{{ .Release.Namespace }}" # 名称空间
    data7: "{{ .Values.NAME }}"
    data8: "{{ .Values.USER.AGE }}"
    data9: "{{ .Values.USER.CITY }}"
    data10: "{{ .Chart.Name }}"
    data11: "{{ .Chart.Version }}"
    data12: "{{ .Capabilities.APTversions }}"
    data13: "{{ .Capabilities.APTversions.Has "apps/v1/Deployment" }}"
    data14: "{{ .Capabilities.kubeversion }}"
    data15: "{{ .Capabilities.kubeversion.Version }}"
    data16: "{{ .Capabilities.kubeversion.Major }}"
    data17: "{{ .Capabilities.kubeversion.Minor }}"
    data18: "{{ .Template.BasePath }}"
    data19: "{{ .Template.Name }}"
    
# 模拟运行
helm install myapp ./mychart -n demo --create-namespace --debug --dry-run
# 定制环境安装；启动时修改 values 变量 
helm install myapp ./mychart -n demo --create-namespace --debug --dry-run --set USER.AGE=28,NAME=M65
```

### 案例：固定配置的 Chart 

- 缺乏灵活性，意义不大！

```powershell
helm create myapp-chart
tree myapp-chart
rm -rf myapp-chart/templates/* myapp-chart/values.yaml myapp-chart/charts/
tree myapp-chart
# 生成相关的资源清单文件
kubectl create deployment myapp --image registry.cn-beijing.aliyuncs.com/wangxiaochun/pod-test:v0.1 --replicas 3 --dry-run=client -o yaml > myapp-chart/templates/myapp-deployment.yaml
kubectl create service loadbalancer myapp --tcp 80:80 --dry-run=client -o yaml > myapp-chart/templates/myapp-service.yaml

tree myapp-chart/
# 修改清单文件
vim myapp-chart/templates/myapp-deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  labels:
    app: myapp
  name: myapp
spec:
  replicas: 3
  selector:
    matchLabels:
      app: myapp
  template:
    metadata:
      labels:
        app: myapp
    spec:
      containers:
      - image: registry.cn-beijing.aliyuncs.com/wangxiaochun/pod-test:v0.1
        name: pod-test
# 修改配置
vim myapp-chart/Chart.yaml
apiVersion: v2
name: myapp-chart
description: A Helm chart for Kubernetes
type: application
version: 0.0.1
appVersion: "0.1.0

# 检查语法
helm lint myapp-chart/
# 打包
helm package ./myapp-chart
```

```powershell
# 部署应用
# 方法1
helm install myapp ./myapp-chart/ --create-namespace --namespace demo
# 方法2
helm install myapp myapp-chart-0.0.1.tgz --create-namespace --namespace demo
# 查看结果
kubectl get all -n demo

# 卸载
helm uninstall myweb -n demo && helm list -n demo && kubectl get all -n demo
```



### 案例：可变配置的 Chart

```powershell
helm create myweb-chart && tree myweb-chart
rm -rf myweb-chart/templates/* myweb-chart/charts/ && tree myweb-chart
# 生成模板文件
kubectl create deployment myweb --image registry.cn-beijing.aliyuncs.com/wangxiaochun/pod-test:v0.1 --replicas 3 --dry-run=client -o yaml > myweb-chart/templates/myweb-deployment.yaml
kubectl create service loadbalancer myweb --tcp 80:80 --dry-run=client -o yaml > myweb-chart/templates/myweb-service.yaml

# 修改相关资源的模板文件,添加变量引用
vim myweb-chart/templates/myweb-deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: {{ .Values.deployment.deployment_name }}
  # namespace: {{ .Values.namespace }}
  namespace: {{ .Release.Namespace }}
spec:
  replicas: {{ .Values.deployment.replicas }}
  selector:
    matchLabels:
      app: {{ .Values.deployment.pod_label }}
  template:
    metadata:
      labels:
        app: {{ .Values.deployment.pod_label }}
    spec:
      containers:
      - image: {{ .Values.deployment.image }}:{{ .Values.deployment.imageTag }}
        name: {{ .Values.deployment.container_name }}
        ports:
        - containerPort: {{ .Values.service.containerport }}

# 修改相关资源的模板文件,添加变量引用
vim myweb-chart/templates/myweb-service.yaml
apiVersion: v1
kind: Service
metadata:
  name: {{ .Values.service.service_name }}
  # namespace: {{ .Values.namespace }}
  namespace: {{ .Release.Namespace }}
spec:
  type: LoadBalancer
  ports:
  - port: {{ .Values.service.port }}
    protocol: TCP
    targetPort: {{ .Values.service.targetport }}
    # nodePort: {{ .Values.service.nodeport }}
  selector:
    app: {{ .Values.deployment.pod_label }}

# 创建默认值文件
vim myweb-chart/values.yaml
deployment:
  deployment_name: myweb-deployment
  replicas: 3
  pod_label: myweb-pod-label
  # image: wangxiaochun/pod-test
  image: registry.cn-beijing.aliyuncs.com/wangxiaochun/pod-test
  imageTag: v0.1
  container_name: myweb-container
service:
  service_name: myweb-service
  port: 80
  targetport: 80
  containerport: 80
  # nodeport: 30080

# Chart.yaml 在此处使用默认值
grep -v "#" myweb-chart/Chart.yaml
apiVersion: v2
name: myweb-chart
description: A Helm chart for Kubernetes
type: application
version: 0.1.0
appVersion: "1.16.0"

tree myweb-chart/
# 检查语法
helm lint myweb-chart/
#打包
helm package ./myweb-chart && ll -h myweb-chart-0.1.0.tgz
```

```powershell
# 安装：使用默认值安装
# 方法1:
helm install myweb ./myweb-chart/ --create-namespace --namespace demo
# 方法2
helm install myweb myweb-chart-0.1.0.tgz --create-namespace --namespace demo

# 定制安装 （参数较少时使用比较好）
helm install --set deployment.replicas=1,deployment.imageTag=v0.2 myweb myweb-chart-0.1.0.tgz --create-namespace --namespace demo2


```

验证 Chart

```powershell
helm list -n demo
kubectl get all -n demo
# 查看生成的清单文件内容
helm get manifest -n demo myweb
# 测试
curl 10.0.0.13:30080
```

升级和回滚

```powershell
# 升级方法1
helm upgrade myweb ./myweb-chart -n demo --set deployment.image=registry.cn-beijing.aliyuncs.com/wangxiaochun/pod-test --set deployment.imageTag=v0.2
# 升级方法2
vim myweb-chart/values.yaml
imageTag: v0.2
helm upgrade myweb ./myweb-chart -n demo -f myweb-chart/values.yaml

# 查看版本历史
helm history -n demo myweb
# 验证升级成功
kubectl get pod -n demo
# 测试
curl 10.0.0.13:30080
# 回滚到指定REVESION号，如果不指定版本，默认回滚至上一个版本,而且只能回滚一个版本
helm rollback -n demo myweb 1
```

```powershell
helm package ./myweb-chart/  &&  ll myweb-chart-0.1.0.tgz

helm uninstall -n demo myweb && helm list -n demo && kubectl get all -n demo
```

上传到 Harbor

```powershell
# 首先登录 harbor （如果是 http 需要加 --insecure 选项）（二选一）
helm registry login --insecure harbor.wang.org -u magedu -p Magedu123
# 如果 http 上传失败，需要下载 harbor 证书导入相关文件中；
cat harbor.wang.org.crt >> /etc/ssl/certs/ca-certificates.crt
# 如果 https 使用自签名证书,需要 Helm 客户端信任 Harbor 证书的 CA （二选一）
cat harbor.wang.org.crt >> /etc/ssl/certs/ca-certificates.crt
cat ca.crt >> /etc/ssl/certs/ca-certificates.crt
# 上传 chart 到 harobr
helm push myweb-chart-0.1.0.tgz oci://harbor.wang.org/helm
# 在线安装
helm install myweb -n demo --create-namespace oci://harbor.wang.org/helm/myweb-chart --version 0.1.0
# 测试
kubectl get ppod,svc -n demo
curl 10.0.0.13
# 测试从 harbor 下载 chart
helm pull oci://harbor.wang.org/helm/myapp-chart --version 0.1.0 && ll myapp-chart-0.1.0.tgz
```

```powershell
# 准备包文件
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo list
# 下载为tgz文件
helm pull prometheus-community/prometheus && ls -l prometheus-27.11.0.tgz
# 上传 chart 到 harobr
helm push prometheus-27.11.0.tgz oci://harbor.wang.org/helm
# 测试从 harbor 下载 chart
helm pull oci://harbor.wang.org/helm/prometheus/prometheus --version 27.11.0 && ls -l prometheus-27.11.0.tgz
```

















 









