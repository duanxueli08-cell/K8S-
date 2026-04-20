



## ELK Stack

### 理论概念：

##### **ELK Stack 由四个主要组件组成：**

1. **Elasticsearch (E):** 存储、搜索和分析数据的核心引擎。
2. **Logstash (L):** 数据收集、过滤和转发；
3. **Kibana (K):** 数据可视化和用户界面。
4. **Beats (B):** 轻量级单用途数据采集器（如 Filebeat, Metricbeat）。

##### 基础概念：

- 数据以 **文档** 的形式存储。
- 多个相似的文档构成一个 **索引**。
- **索引** 被分成多个 **主分片**，以实现分布式存储和处理。
- 每个 **主分片** 都有一个或多个 **副本**，以实现高可用和高查询性能。

| **概念**                                  | **含义**                                                     | **作用**                                                     |
| ----------------------------------------- | ------------------------------------------------------------ | ------------------------------------------------------------ |
| **索引 (Index)**                          | 类似关系数据库中的“数据库”。它是具有相似特征的文档集合。     | 数据的逻辑分组，是执行搜索、更新和删除操作的入口点。         |
| **文档 (Document)**                       | 类似关系数据库中的“行”。它是可以被索引的基本信息单元，以 JSON 格式存储。 | 实际存储的数据载体，是 Elasticsearch 中最小的存储和搜索单元。 |
| **分片 (Shard) / 主分片 (Primary Shard)** | 索引被**水平切分**成若干个分片。每个分片都是一个独立的、功能完整的搜索引擎实例。 | **实现数据的分布式存储和处理**。它允许索引容量突破单个节点的限制，并支持并行操作以**提高性能**。主分片的数量在索引创建时确定且不可更改。 |
| **副本 (Replica Shard)**                  | 主分片的**精确拷贝**，可以有零个或多个副本。                 | 1. **高可用性/故障转移**：当主分片节点失效时，副本分片会被提升为新的主分片，确保数据不丢失。 2. **负载均衡/提高性能**：搜索请求可以由主分片或副本分片处理，Elasticsearch 会自动对搜索请求进行**负载均衡**，提升查询并发能力。副本分片的数量可以动态调整。 |

##### ELK 工作流程

> - **Filebeat:** 轻量级采集器，对服务器资源占用小。
> - **Kafka:** 引入消息队列作为**缓冲区 (Buffer)**，实现了**削峰填谷**，防止 Logstash/ES 处理不过来时日志丢失，这是生产环境的**最佳实践**。
> - **Logstash:** 负责复杂的数据清洗和标准化。
> - **Elasticsearch:** 负责高速存储和分析。
> - **Kibana:** 提供了最终的用户界面和可视化能力。

```powershell
┌─────────────────┐
│   应用服务器     │
│   ┌─────────┐   │
│   │ 日志文件 │   │
│   └────┬────┘   │
└────────┼────────┘
         │ Filebeat
         ▼
┌─────────────────┐
│     Kafka       │◄──缓冲/解耦
│   (消息队列)    │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│    Logstash     │◄──过滤/解析/转换
│   (数据处理)    │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ Elasticsearch   │◄──存储/索引/搜索
│   (数据存储)    │
└────────┬────────┘
         │ API
         ▼
┌─────────────────┐
│     Kibana      │◄──仪表盘/查询/分析
│   (可视化)      │
└─────────────────┘
```



##### 常见的集群模式

- 将核心职责分离，以保障集群的稳定性和高可用性。这是生产环境推荐的最小化高可用配置。
- 在 Elasticsearch 中，通过配置 `node.roles` 数组，您可以灵活地为集群中的每个服务器定义其职责。
- **协调节点**是一个**隐式**的角色。**任何一个接收到客户端请求的节点，即使它没有被明确配置为 `coordinating` 角色，也会扮演协调节点的职责**。
- 设置 node.master:true 指定是否参与 Master 节点选举，默认是true ；如果改为 flase 则不参与后续的 Master 选举；
- 设置 node.data:true 指定为 data 节点，默认是 true ，即默认所有节点都是 data 节点类型；
- 设置 node.coordinating:true 指定为 coordinating 节点，前提是：node.master:flase node.data:flase node.ingest:flase 

| **节点**       | **角色分配**   | **数量**              | **作用**                                               |
| -------------- | -------------- | --------------------- | ------------------------------------------------------ |
| **专有主节点** | `master`       | $3$ 个（推荐奇数）    | 负责整个集群的增删改；比如索引，节点和分片的重新分配； |
| **数据节点**   | `data, ingest` | $N$ 个（至少 $2$ 个） | 专职负责数据存储和查询。                               |
| **协调节点**   | `coordinating` | $M$ 个（可选）        | 专职负责客户端请求的路由和聚合。                       |



##### 索引

> **注意：ES的副本指不包括主分片的其它副本,即只包括备份，这与Kafka是不同的**
>
> 创建索引，安装插件，通过插件 Head 查看索引，以及分片和副本
>
> 创建的分片最佳数量是与节点数量相等；

```powershell
# 创建索引index1,简单输出
curl -XPUT 'http://10.0.0.201:9200/index1'
# Elasticsearch 默认数据存储路径
ls /var/lib/elasticsearch
# 查看 Elasticsearch 全部索引列表
curl 'http://10.0.0.201:9200/_cat/indices?v'
# 创建3个分片和2个副本的索引
curl -X PUT "10.0.0.202:9200/index2" -H "Content-Type: application/json" -d '{
    "settings": {
      "index": {
        "number_of_shards": 3,
        "number_of_replicas": 1
      }
    }
  }'
```

> 索引虽然从逻辑上用于数据分组，但是删除索引会立即删除底层所有真实数据文件；
>
> ES 的真实数据结构是这样的：
>
> ```powershell
> 索引 index
> ├── 主分片 shard 0
> │    ├── segment_1
> │    ├── segment_2
> │    └── ...
> ├── 主分片 shard 1
> └── 副本分片 shard 0
> ```



##### ES 文档

默认情况下，ES 使用 **文档 ID** 作为路由键：

- **同一个文档 ID → 永远落在同一个主分片**
- 副本分片只是主分片的复制

```powershell
shard = hash(_id) % number_of_primary_shards
```

文档写入流程：

```powershell
客户端写入文档
     ↓
协调节点（coordinating node）
     ↓
根据 文档id 计算 hash
     ↓
定位主分片（比如 shard 1）
     ↓
写入 shard 1 主分片
     ↓
同步到 shard 1 的副本分片
```

Elasticsearch 创建文档

- 文档 ID 是哈希算法得出的结果；

```powershell
# 自动生成 ES 文档 ID
curl -X POST "http://10.0.0.201:9200/user/_doc" \
-H "Content-Type: application/json" \
-d '{
  "name": "张三",
  "age": 25,
  "city": "Beijing"
}'
```

Elasticsearch 查询文档

```powershell
curl -X GET "http://10.0.0.201:9200/user/_doc/test"
```

基于 DSL 语句查询

- `_search`：搜索接口
- `match`：全文检索
- `"name": "韩"`：如果 `name` 是 `text + 中文分词`，会匹配包含“韩”的文档

```powershell
POST 10.0.0.93:9200/oldboyedu-linux92/_search
{
  "query": {
    "match": {
      "name": "韩"
    }
  }
}
```

ES 修改文档

```powershell
POST oldboyedu-linux92/_update/202407101700001
{
  "doc": {
    "school": "修改内容"
  }
}
```

ES 删除文档

```powershell
DELETE oldboyedu-linux92/_doc/202407101700001
```



##### ES 集群常见术语

- ES cluster：指的是 ES 集群的各个节点；
- index：索引。用于数据读取的逻辑单元；一个索引最少要有一个分片；
- shard：分片，用于实际存储数据信息的；
- replica：对分片进行备份的 shard；
  - primary shard：负责数据的读写；（主分片）
  - replica shard：从 primary shard 同步数据且负责读的负载均衡；（从分片）
- document：实际数据；氛围元数据和源数据；
  - 元数据：描述数据的数据，比如： _index,_id,_type,_source,...
  - 源数据：用户实际的存储数据，数据存储在 ”——source“ 字段中；
- allocation：将索引的不同分片分配到整个集群的过程；（分配）

##### ES 集群状况

- green 绿色状态：表示集群各节点运行正常，而且没有丢失任何数据；
- yellow 黄色状态：部分副本分片异常；
- red 红色状态：部分主分片异常；





##### Filebeat 收集日志

- Logstash 也可以直接收集日志,但需要安装JDK并且会占用至少 500M 以上的内存；
- 生产一般使用filebeat代替logstash, 基于go开发,部署方便,重要的是只需要10M多内存,比较节约资源；



###### Filebeat 安装

> - 下载地址：[Download Filebeat | Elastic](https://www.elastic.co/cn/downloads/beats/filebeat)
> - 官方文档：https://www.elastic.co/docs/reference/beats/filebeat

```powershell
dpkg -i filebeat-9.2.2-amd64.deb
systemctl start filebeatps aux|grep filebeat
```

- filebeat 服务以 root 身份启动



###### Filebeat 配置

- 默认配置文件路径：/etc/filebeat/filebeat.yml

```powershell
systemctl cat filebeat.service
file /usr/share/filebeat/bin/filebeat
ldd /usr/share/filebeat/bin/filebeat
/usr/share/filebeat/bin/filebeat --help
```

```powershell
vim /etc/filebeat/stdin.yml
filebeat.inputs:
- type: stdin
  enabled: true
  json.keys_under_root: true # 解析json
  tags: ["stdin-tags","myapp"] #添加新字段名tags，可以用于判断不同类型的输入，实现不同的输出
  fields:
    status_code: "200" #添加新字段名fields.status_code，可以用于判断不同类型的输入，实现不同的输出
    author: "wangxiaochun"
output.console:
  pretty: true
  enable: true

# 检查配置语法和结构
filebeat test config -c /etc/filebeat/stdin.yml
# 检查输出端是否能连通（ES / Logstash）
filebeat test output -c /etc/filebeat/stdin.yml
```

```powershell
# 用指定配置文件启动 Filebeat 服务，真实执行日志采集、处理并发送到配置的输出端。
filebeat -c /etc/filebeat/stdin.yml
# 输入一段字符串测试，然后稍等片刻，会在以 JSON 格式的日志输出到终端
hello duan
# 输入json格式，进行解析
{"name" : "wangxiaochun", "age" : "18", "phone" : "0123456789"}
```

```powershell
vim /etc/filebeat/file.yaml
filebeat.inputs:
- type: filestream
  id: my-filestream
  enabled: true
  paths:
    - /var/log/test.log
  parsers:
    - ndjson:
        target: ""
output.console:
  pretty: true
  enable: true
```



##### Logstash 

###### 安装

```powershell
dpkg -i logstash-7.6.2-amd64.deb
# 服务方式启动,由于默认没有配置文件,所以7.X无法启动，8.X可以启动
systemctl start logstash.service ; systemctl status logstash.service
# 生成专有用户logstash,以此用户启动服务,后续使用时可能会存在权限问题
id logstash
```



```powershell
vim /etc/filebeat/stdin.yml
filebeat.inputs:
- type: log
  enabled: true # 开启日志
  paths:
  - /var/log/nginx/access_json.log # 指定收集的日志文件
  json.keys_under_root: true
  tags: ["nginx-access"]
- type: log
  enabled: true # 开启日志
  paths:
  - /var/log/syslog # 指定收集的日志文件
  fields:
    logtype: "syslog" # 添加自定义字段logtype
output.logstash:
  hosts: ["10.0.0.104:5044"] # 指定Logstash服务器的地址和端口
```










#### Elasticsearch

- 下载地址：https://www.elastic.co/cn/downloads/elasticsearch

- 内置JAVA

  - 基于 JAVA 的应用，而且安装时会自动内嵌 JAVA 环境，但是 Elasticsearch 的 JAVA 环境仅仅自己能用，不能共享；
  - /usr/share/elasticsearch/jdk/bin/java -version

- dpkg 与 apt install 安装包有什么区别？

  - dpkg 只安装包本身，不会自动解决依赖。
  - apt 会自动解决依赖、自动下载缺少的包，并更安全；（实际最常用）
  - dpkg 负责解包，apt 负责依赖。线上用 apt，离线用 dpkg。

- JVM优化

  - 编辑 /etc/elasticsearch/jvm.options 文件，添加或修改参数：-Xms128m   和 -Xmx128m

  - `-Xms` = JVM 初始堆大小

    `-Xmx` = JVM 最大堆大小

  - 生产环境设置规则：

    - **Elasticsearch 要求 Xms 和 Xmx 保持一致**，否则频繁扩容堆会导致 Stop-The-World 卡顿。
    - **堆大小占系统物理内存的 50% 左右** （官方建议）。
    - 最大不要超过 30GB ；超过 30GB 就会失效 → 性能立刻下降 ；日志类业务更依赖磁盘吞吐，而不是堆大小！
    - 堆越大 → GC 扫描越多 → STW 时间更长
    - 堆超过 30GB → 禁用 Compressed Oops → 内存占用变大 → GC 负担剧增 → STW 更长
    - 若是容器启动，则另说！

- 下载安装包建议先查看产品文档，当前的系统版本与 Elasticsearch 的兼容性；[支持矩阵 | Elastic](https://www.elastic.co/cn/support/matrix)

- 强制要求：必须以普通用户身份启动，不能以超级用户身份启动，否则失败；

- Elasticsearch JAVA 比较吃内存，实验时建议设置为4GB内存；

- Elasticsearch 安装完成时会显示登录密码；

  - 重置密码：/usr/share/elasticsearch/bin/elasticsearch-reset-password -u elastic

- 默认 9.X 开启 xpack 安全，导致无法直接访问  curl 127.0.0.1:9200  这样直接访问会失败！

  - 关闭XPACK功能，就可以直接访问  curl 127.0.0.1:9200
    - 修改 /etc/elasticsearch/elasticsearch.yml 文件   xpack.security.enabled: false # 修改为false

- 登录：curl -u"elastic:$PASSWORD" -k https://127.0.0.1:9200

##### 包安装（单机）

```powershell
wget https://artifacts.elastic.co/downloads/elasticsearch/elasticsearch-9.2.1-amd64.deb
apt install ./elasticsearch-9.2.1-amd64.deb
free -h
/usr/share/elasticsearch/jdk/bin/java -version
systemctl start elasticsearch.service
curl https://127.0.0.1:9200 -k
/usr/share/elasticsearch/bin/elasticsearch-reset-password -u elastic
PASSWORD=cz+1XmXs9lPgOYWockJq
curl -u"elastic:$PASSWORD" -k https://127.0.0.1:9200
sed -i 's#^xpack.security.enabled#xpack.security.enabled: false#' /etc/elasticsearch/elasticsearch.yml
vim /etc/elasticsearch/jvm.options
-Xms2G
-Xmx2G
sudo sed -i '/Xmx4g$/a -Xms2G\n-Xmx2G' /etc/elasticsearch/jvm.options
sudo sed -i 's#128m#2G#' /etc/elasticsearch/jvm.options
grep -- Xm /etc/elasticsearch/jvm.options

systemctl restart elasticsearch.service
ps aux | grep java | grep Xms
```

```powershell
curl 127.0.0.1:9200/_cat/health
```

##### ES 单点卸载

- 卸载步骤：
  1. 停服务；
  2. 卸载软件；(此操作不会删除ES 的数据)
  3. 删除数据；（生产环境不建议这样做！）
  4. 删除日志；
  5. 清空临时数据；

```powershell
systemctl stop elasticsearch
dpkg -r elasticsearch
rm -rf /var/lib/elasticsearch/*
ll /var/{var,log}/elasticsearch
rm -rf /tmp/*
```



##### ES  集群部署

- 8.X 以上版本集群配置

- 编辑 /etc/elasticsearch/elasticsearch.yml 文件配置

  - node.name: node-1      修改此行，每个节点不同；

  - http.port: 9200  默认也是9200；

  - network.host: 0.0.0.0    集群模式必须修改此行，否则集群节点无法通过9300端口通信；每个节点相同；

  - 去注释 cluster.name: my-application ；这是集群名，名称无所谓，但是同集群内这个名称必须唯一；

  - discovery.seed_hosts: ["10.0.0.201", "10.0.0.202","10.0.0.203"]               修改此行，每个节点相同；

  - cluster.initial_master_nodes: ["10.0.0.201", "10.0.0.202","10.0.0.203"]     修改此行，每个节点相同；这个参数有两个，记得要注释其中一个；

    - 仅仅生效于首次选举；第二次第三次及以后的选举与此配置无关；
    - 设置 node.master:true 指定是否参与 Master 节点选举，默认是true ；如果改为 flase 则不参与后续的 Master 选举；

  - xpack.security.enabled: false       修改此行，每个节点相同；

  - bootstrap.memory_lock: true        （优化）内存锁；开启此功能导 8.X 致集群模式无法启动，但单机模式可以启动；

    - ```powershell
      sudo sed -i '/^\[Service\]/a LimitMEMLOCK=infinity' /usr/lib/systemd/system/elasticsearch.service
      ```

      作用：允许 Elasticsearch 进程锁定不限量内存，否则启用 bootstrap.memory_lock 会直接报错。

```powershell
wget https://artifacts.elastic.co/downloads/elasticsearch/elasticsearch-9.2.1-amd64.deb
apt install ./elasticsearch-9.2.1-amd64.deb

vi /etc/elasticsearch/elasticsearch.yml
node.name: node-1
network.host: 0.0.0.0
xpack.security.enabled: false
cluster.name: my-application
discovery.seed_hosts: ["10.0.0.201","10.0.0.202","10.0.0.203"]
cluster.initial_master_nodes: ["10.0.0.201","10.0.0.202","10.0.0.203"]
#cluster.initial_master_nodes: ["MINIO-201"]	# 有两个相同的参数，只能留一个！

for i in {201..203} ; do scp /etc/elasticsearch/elasticsearch.yml 10.0.0.$i:/etc/elasticsearch/elasticsearch.yml ; done
sed -i 's#^node.name.*#node.name: node-2#' /etc/elasticsearch/elasticsearch.yml && grep 'node-2' /etc/elasticsearch/elasticsearch.yml
sed -i 's#^node.name.*#node.name: node-3#' /etc/elasticsearch/elasticsearch.yml && grep 'node-3' /etc/elasticsearch/elasticsearch.yml
grep cluster.initial_master_nodes /etc/elasticsearch/elasticsearch.yml

sudo sed -i 's#2G#1G#' /etc/elasticsearch/jvm.options && grep -- Xm /etc/elasticsearch/jvm.options

sudo systemctl daemon-reload
systemctl restart elasticsearch.service && systemctl status elasticsearch.service
ss -ntlp |grep -E '9200|9300'

# 通过浏览器访问 Elasticsearch 服务端口
http://10.0.0.201:9200/ 
```

```powershell
curl http://10.0.0.201:9200/_cat/health
curl -s 10.0.0.201:201/_cat/nodes
curl -s 10.0.0.201:[201..203] | grep cluster_uuid
```





##### 插件

- 通过使用各种插件可以实现对 ES 集群的状态监控, 数据访问, 管理配置等功能;

Cerebro 插件

- 个人不喜欢这个插件，所以没有做这个服务！

Head 插件

- git地址：https://github.com/mobz/elasticsearch-head
- 浏览器安装：管理扩展 —— 添加扩展 —— 添加完成后，点击该插件使用

![image-20251204220901976](https://cdn.jsdelivr.net/gh/duanxueli08-cell/Obsidian-Images@main/img/image-20251204220901976.png)

##### 故障自愈

- 当节点宕机后，Elasticsearch 会自动检测到分片丢失，并在其他节点重建副本，恢复节点后再进行分片均衡，从而实现真正意义上的“故障自愈”。

> 准备工作：完成上面的集群；安装插件；
>
> ```powershell
> # 创建一个索引 index2，包含 3 个主分片（P）+ 1 个副本分片（R）：
> curl -X PUT "10.0.0.202:9200/index2" -H "Content-Type: application/json" -d '{
>  "settings": {
>    "index": {
>      "number_of_shards": 3,
>      "number_of_replicas": 1
>    }
>  }
> }'
> systemctl stop elasticsearch
> ```
>
> 此时在 3 节点集群中，**每个主分片 P 都会被分布到不同的节点上，每个副本 R 也会分布在不同节点**，确保没有 P 和 R 落在同一节点上。

> 模拟节点故障（下线 10.0.0.201）
>
> ```powershell
> systemctl stop elasticsearch
> ```
>
> **健康状态从 green → yellow**
>
> - 某个节点宕机后，落在该节点上的 **副本分片（Replica）不可用**。
> - 主分片仍在其他节点上，所以 **数据依然能读写**。
> - 副本分片缺失 → 集群状态变为 **Yellow（部分副本缺失）**。
>
> 👉 **Yellow 表示数据可用，但冗余不足。**

> **Elasticsearch 自动故障自愈**
>
> 当节点 10.0.0.201 下线后，过一段时间（默认 1 分钟左右），ES 会触发以下动作：
>
> **自动重新分配副本（Replica Reallocation）**
>
> - ES 会检测到某节点不可用
> - 集群会在剩余健康的节点上 **自动重建副本分片**
> - 冗余恢复完整后，状态从 **Yellow → Green**
>
> 👉 此过程称为：
>
> **❗ 自动分片重分配（Auto Shard Reallocation）**
>
> 也被称为：
>
> - 副本自愈
> - 分片修复机制
> - 集群再均衡

> 恢复节点后（重新启动 10.0.0.201）
>
> ```powershell
> systemctl start elasticsearch
> ```
>
> 节点重新加入集群后：
>
> **集群重新平衡（Shard Rebalancing）**
>
> - ES 会将部分主分片或副本分片迁回到这个节点
> - 最终再次达到分片均衡状态（平衡负载）
>
> 👉 这称为：
>
> **❗ 自动分片重新均衡（Auto Shard Rebalancing）**
>
> 恢复后集群再次保持：
>
> - 状态：**Green**
> - 主分片正常
> - 副本分片完整
> - 负载均衡

![image-20251204221226150](https://cdn.jsdelivr.net/gh/duanxueli08-cell/Obsidian-Images@main/img/image-20251204221226150.png)

Elasticsearch 数据的更改是由主分片决定的，主分片执行完增删改后同步到副分片中；



### ELK 综合实战案例

```powershell
做一个方案（实验）：Filebeat 收集Nginx日志利用 Redis 缓存发送至 Elasticsearch；
nginx服务器：10.0.0.100
Filebeat服务：10.0.0.100	对应版本：filebeat-9.2.2-amd64.deb
redis服务器：10.0.0.201
logstash服务器：10.0.0.100	对应版本：logstash-9.2.2-amd64.deb
Elasticsearch服务集群：10.0.0.201；10.0.0.202；10.0.0.203	对应版本：elasticsearch-9.2.1-amd64.deb
kibana服务器：10.0.0.200		对应版本：kibana-9.2.2-amd64.deb
备注：都是Ubuntu2404系统；
```

#### 案例一

拓扑图

```powershell
Nginx ——> Redis/Kafka ——> Logstash ——> ES ——> kibana ——> 世界地图
  |                          |
  |————> kibana 安全认证      |————> Mysql
```



- Filebeat 收集 Nginx 日志利用 Redis 缓存发送至 Elasticsearch ；
  - 利用 Redis 缓存日志数据,主要解决应用解耦，异步消息，流量削锋等问题；
  - 局限性：不支持Redis 集群，存在单点问题，但是可以多节点负载均衡；Redis 基于内存，因此存放数据量有限

##### Redis  （二选一）

```powershell
apt update && apt -y install redis
vim /etc/redis/redis.conf
bind 0.0.0.0
save "" #禁用rdb持久保存
# cluster-enabled no  # 确保是 no 或者注释
requirepass 123123

systemctl restart redis
```

查看 Redis 中的数据

```powershell
# 查看所有键：
redis-cli -a 123123 --no-auth-warning keys '*'
# 查看 filebeat 键的数据类型：
redis-cli -a 123123 --no-auth-warning type filebeat
# 查看 filebeat 键中的前两个数据：
redis-cli -a 123123 --no-auth-warning lrange filebeat 0 1

keys *
llen filebeat
```

##### Kafka  集群（二选一）

- 基于 zookeeper 安装 （主流）
- 以三个节点搭建一个 Kafka 集群

```powershell
# 修改每个kafka节点的主机名
hostnamectl set-hostname node1
hostnamectl set-hostname node2
hostnamectl set-hostname node3
# 在所有kafka节点上实现主机名称解析
cat >> /etc/hosts <<eof
10.0.0.91 node3
10.0.0.92 node1
10.0.0.93 node2
eof
# 安装 JAVA
apt update && apt -y install openjdk-21-jre
java -version
update-alternatives --config java
# 下载二进制包并安装
wget https://mirrors.aliyun.com/apache/kafka/3.9.1/kafka_2.13-3.9.1.tgz
tar xf kafka_2.13-3.9.1.tgz -C /usr/local/
cd /usr/local/ && ls
ln -s /usr/local/kafka_2.13-3.9.1/ /usr/local/kafka && ls /usr/local/kafka
# 修改配置文件，此目录无需手动创建，启动会自动创建
sed -i "s#^dataDir.*#dataDir=/data/zookeeper#" /usr/local/kafka/config/zookeeper.properties
sed -i "s#^log.dirs.*#log.dirs=/data/kafka-logs#" /usr/local/kafka/config/server.properties
# 临时启动 （可选）
/usr/local/kafka/bin/zookeeper-server-start.sh /usr/local/kafka/config/zookeeper.properties
/usr/local/kafka/bin/kafka-server-start.sh /usr/local/kafka/config/server.properties
```

```powershell
mkdir -p /usr/local/kafka/data/
# 集群配置必须配置时间相关 （三个节点就配置相同）
vim /usr/local/kafka/config/zookeeper.properties
#必须添加时间相关配置
tickTime=2000
initLimit=10
syncLimit=5
#保留下面内容
clientPort=2181
maxClientCnxns=0
admin.enableServer=false
#添加下面集群配置
dataDir=/usr/local/kafka/data/
server.1=10.0.0.91:2888:3888
server.2=10.0.0.92:2888:3888
server.3=10.0.0.93:2888:3888

# 主机：10.0.0.91
echo 1 > /usr/local/kafka/data/myid
# 主机：10.0.0.92
echo 2 > /usr/local/kafka/data/myid	
# 主机：10.0.0.93
echo 3 > /usr/local/kafka/data/myid
```

```powershell
# 各节点部署 Kafka 配置文件 （单机部署不需要改配置，但是集群部署必须要修改一些参数！）
vi /usr/local/kafka/config/server.properties 
# 每个节点id号唯一 （10.0.0.91对应1；以此类推）
broker.id=1
# kafka监听端口，默认9092 (每个节点写自身的ip地址)
listeners=PLAINTEXT://10.0.0.91:9092
log.dirs=/usr/local/kafka/data
zookeeper.connect=10.0.0.91:2181,10.0.0.92:2181,10.0.0.93:2181

———— 分割线 ————

ls /root/.ssh/id_rsa.pub | ssh-keygen -t rsa
for host in 10.0.0.{92,93}; do ssh-copy-id -i /root/.ssh/id_rsa.pub -o StrictHostKeyChecking=no root@$host ;  done

for i in {92,93} ; do scp /etc/hosts  10.0.0.$i:/etc/hosts; done
for i in {92,93} ; do scp /usr/local/kafka/config/zookeeper.properties  10.0.0.$i:/usr/local/kafka/config/zookeeper.properties ; done
for i in {92,93} ; do scp /usr/local/kafka/config/server.properties  10.0.0.$i:/usr/local/kafka/config/server.properties ; done
sed -i "s#//10.0.0.91#//10.0.0.92#" /usr/local/kafka/config/server.properties && grep "10.0.0." /usr/local/kafka/config/server.properties
sed -i "s#broker.id=1#broker.id=2#" /usr/local/kafka/config/server.properties && grep "^broker" /usr/local/kafka/config/server.properties

sed -i "s#//10.0.0.91#//10.0.0.93#" /usr/local/kafka/config/server.properties && grep "10.0.0." /usr/local/kafka/config/server.properties
sed -i "s#broker.id=1#broker.id=3#" /usr/local/kafka/config/server.properties && grep "^broker" /usr/local/kafka/config/server.properties
```

```powershell
# 创建service文件
cat > /lib/systemd/system/zookeeper.service <<EOF
[Unit]
Description=zookeeper.service
After=network.target

[Service]
Type=forking
ExecStart=/usr/local/kafka/bin/zookeeper-server-start.sh -daemon /usr/local/kafka/config/zookeeper.properties
ExecStop=/usr/local/kafka/bin/zookeeper-server-stop.sh
ExecReload=/bin/kill -HUP \$MAINPID

[Install]
WantedBy=multi-user.target
EOF
# 创建service文件
cat > /lib/systemd/system/kafka.service <<EOF
[Unit]
Description=kafka.service
After=network.target zookeeper.service

[Service]
Type=forking
ExecStart=/usr/local/kafka/bin/kafka-server-start.sh -daemon /usr/local/kafka/config/server.properties
ExecStop=/usr/local/kafka/bin/kafka-server-stop.sh
ExecReload=/bin/kill -HUP \$MAINPID

[Install]
WantedBy=multi-user.target
EOF

systemctl  start zookeeper && systemctl  status zookeeper
systemctl  start kafka && systemctl  status kafka
ss -tunlp | grep 9092

# 进入图形客户端后，在brokers的ids文件夹中可以看到012这三个brokers编号！
```



##### Nginx

- 部署 Nginx 服务配置 Json 格式的访问日志
- 修改nginx访问日志为Json格式
- 默认开启nginx的错误日志,但如果是ubuntu,还需要修改下面行才能记录错误日志
- 验证访问日志的json格式

```powershell
apt update && apt -y install nginx
vim /etc/nginx/nginx.conf
http {
    log_format access_json '{"@timestamp":"$time_iso8601",'
    '"host":"$server_addr",'
    '"clientip":"$remote_addr",'
    '"size":$body_bytes_sent,'
    '"responsetime":$request_time,'
    '"upstreamtime":"$upstream_response_time",'
    '"upstreamhost":"$upstream_addr",'
    '"http_host":"$host",'
    '"uri":"$uri",'
    '"domain":"$host",'
    '"xff":"$http_x_forwarded_for",'
    '"referer":"$http_referer",'
    '"tcp_xff":"$proxy_protocol_addr",'
    '"http_user_agent":"$http_user_agent",'
    '"status":"$status"}';

    access_log /var/log/nginx/access.log access_json;
}
# 默认开启nginx的错误日志,但如果是ubuntu,还需要修改下面行才能记录错误日志
vim /etc/nginx/sites-available/default
    location / {
        # First attempt to serve request as file, then
        # as directory, then fall back to displaying a 404.
        try_files $uri $uri/ =404; # 将此行注释

# 验证访问日志的json格式
tail -n 1 /etc/nginx/nginx.conf/access_json.log

systemctl restart nginx
```

##### Filebeat 

- **利用 Filebeat 收集日志到 Redis （二选一）**

```powershell
dpkg -i filebeat-9.2.2-amd64.deb

cat > /etc/filebeat/filebeat.yml <<'eof'
filebeat.inputs:
  # Nginx访问日志（JSON格式）
  - type: filestream
    id: my-filestream-id-1
    enabled: true
    tags: ["nginx-access"]
    paths:
      - /var/log/nginx/access_json.log
    # 只有JSON格式的日志才使用ndjson解析器
    parsers:
      - ndjson:
          target: ""  # 解析结果存放在根下
          # message_key: message  # 仅当JSON在message字段中时才需要

  # Nginx错误日志（文本格式）
  - type: filestream
    id: my-filestream-id-2
    enabled: true
    tags: ["nginx-error"]
    paths:
      - /var/log/nginx/error.log
    # 文本格式日志不需要ndjson解析器
    # 如果需要结构化解析，应该使用grok模式或dissect处理器

  # Syslog（文本格式）
  - type: filestream
    id: my-filestream-id-3
    enabled: true
    tags: ["syslog"]
    paths:
      - /var/log/syslog
    # 文本格式日志不需要ndjson解析器
    # 可以使用syslog解析器或后期处理

# 输出配置
output.redis:
  hosts: ["10.0.0.91:6379"]
  password: "123123"
  db: "0"
  key: "filebeat"
eof

# 检查配置语法和结构
filebeat test config -c /etc/filebeat/filebeat.yml

systemctl restart filebeat.service ; systemctl status filebeat.service
```

- **利用 Filebeat 收集日志到 Kafka （二选一）**

```powershell
cat > /etc/filebeat/filebeat.yml <<'eof'
filebeat.inputs:
  - type: filestream
    id: nginx-access
    enabled: true
    paths:
      - /var/log/nginx/access_json.log
    json:
      keys_under_root: true
      overwrite_keys: true
    tags: ["nginx-access"]

  - type: filestream
    id: nginx-error
    enabled: true
    paths:
      - /var/log/nginx/error.log
    tags: ["nginx-error"]

  - type: filestream
    id: syslog
    enabled: true
    paths:
      - /var/log/syslog
    tags: ["syslog"]

output.kafka:
  hosts: ["10.0.0.91:9092", "10.0.0.92:9092", "10.0.0.93:9092"]
  topic: filebeat-log

  partition.round_robin:
    reachable_only: true

  required_acks: 1
  compression: gzip
  max_message_bytes: 1000000
eof

grep -Ev "#|^$" /etc/filebeat/filebeat.yml
# 重启 filebeat 服务，不出意外的话在 kafka 图形工具展示中就能看到 指定的 kafka topic
filebeat test config
filebeat test output
systemctl restart filebeat
# 在 vi  /var/log/nginx/access.log 中写入日志数据， 在kafka查看是否有数据
/usr/local/kafka/bin/kafka-topics.sh --list --bootstrap-server 10.0.0.91:9092
/usr/local/kafka/bin/kafka-console-consumer.sh --topic filebeat-log --bootstrap-server 10.0.0.91:9092 --from-beginning
```



##### Logstash

- 创建 Logstash 的 pipeline 配置文件；

  - 从 Redis 里取 Filebeat 推送的日志 → 处理（GeoIP/字段类型转换）→ 按 tag 写入不同的 Elasticsearch 索引；

  - 它遵循 Logstash 的三段式结构（非常重要）：

    ```powershell
    input   →  filter  →  output
    ```

  - input / redis ：从 Redis list(filebeat) 中阻塞读取日志事件；

  - filter / geoip + mutate：对 nginx-access 日志做增强处理；

    - geoip：给 IP 打上国家 / 城市 / 经纬度；
    - mutate.convert：把字符串变成数值，方便 ES 聚合（avg / max）

  - output / 条件路由：不同日志 → 不同索引

```powershell
# 8.X 要求JDK11或17
apt update && apt -y install openjdk-17-jdk
dpkg -i logstash-9.2.2-amd64.deb

systemctl start logstash.service ; systemctl status logstash.service
# 生成专有用户logstash,以此用户启动服务,后续使用时可能会存在权限问题
id logstash
```

- 配置 Logstash 读取 Redis 日志发送到 Elasticsearch （二选一）

```powershell
# 创建 Logstash 的 pipeline 配置文件
cat > /etc/logstash/conf.d/redis-to-es.conf << 'EOF'
input {
  redis {
    host => "10.0.0.91"
    port => 6379
    password => "123123"
    db => 0
    key => "filebeat"
    data_type => "list"
    threads => 2
  }
}

filter {
  if [message] {
    json {
      source => "message"
      target => "parsed"
    }
  }
  
  if "nginx-access" in [tags] {
    if [parsed][upstreamtime] {
      mutate {
        convert => { "[parsed][upstreamtime]" => "float" }
      }
    }
    
    if [parsed][responsetime] {
      mutate {
        convert => { "[parsed][responsetime]" => "float" }
      }
    }
    
    if [parsed][size] {
      mutate {
        convert => { "[parsed][size]" => "integer" }
      }
    }
    
    if [parsed][status] {
      mutate {
        convert => { "[parsed][status]" => "integer" }
      }
    }
  }
  
  date {
    match => [ "@timestamp", "ISO8601" ]
    target => "@timestamp"
  }
}

output {
  if "syslog" in [tags] {
    elasticsearch {
      hosts => ["10.0.0.201:9200", "10.0.0.202:9200", "10.0.0.203:9200"]
      index => "syslog-%{+YYYY.MM.dd}"
    }
  }
  
  if "nginx-access" in [tags] {
    elasticsearch {
      hosts => ["10.0.0.201:9200", "10.0.0.202:9200", "10.0.0.203:9200"]
      index => "nginx-access-%{+YYYY.MM.dd}"
      template_overwrite => true
    }
    
    stdout {
      codec => rubydebug
    }
  }
  
  if "nginx-error" in [tags] {
    elasticsearch {
      hosts => ["10.0.0.201:9200", "10.0.0.202:9200", "10.0.0.203:9200"]
      index => "nginx-error-%{+YYYY.MM.dd}"
      template_overwrite => true
    }
  }
}
EOF

# 停止服务，以 logstash 用户在前台启动配置文件
systemctl  stop logstash.service
sudo -u logstash /usr/share/logstash/bin/logstash -f /etc/logstash/conf.d/redis-to-es.conf -r
# 在 filebeat 服务所在的设备进行模拟日志数据变更，然后在 logstash 服务器进行观察
mv mall_app.log  /var/log/mall_app.log 
# logstash 服务器收到 filebeat 收集的数据，整理并发送到 ES 中，在 ES 可视化图形界面中可以看到这个索引
mall-app-2025.12.09
```

##### 添加地理位置信息

- 将日志中的客户端IP添加地理位置信息 ；（可选）

```powershell
cat > /etc/logstash/conf.d/redis-to-es.conf <<'eof'
input {
  redis {
    host     => "10.0.0.91"
    port     => "6379"
    password => "123123"
    db       => "0"
    key      => "filebeat"
    data_type => "list"
  }
}

filter {

  if "nginx-access" in [tags] {
    geoip {
      source => "clientip"
      target => "geoip"
      database => "/usr/share/logstash/vendor/bundle/jruby/3.1.0/gems/logstash-filter-geoip-7.3.1-java/vendor/GeoLite2-City.mmdb"
      add_field => ["[geoip][coordinates]", "%{[geoip][geo][location][lon]}"]
      add_field => ["[geoip][coordinates]", "%{[geoip][geo][location][lat]}"]
    }

    mutate {
      convert => { "[geoip][coordinates]" => "float" }
    }
  }

  mutate {
    convert => { "upstreamtime" => "float" }
  }

}

output {

  if "syslog" in [tags] {
    elasticsearch {
      hosts => ["10.0.0.201:9200", "10.0.0.202:9200", "10.0.0.203:9200"]
      index => "syslog-%{+YYYY.MM.dd}"
    }
  }

  if "nginx-access" in [tags] {
    elasticsearch {
      hosts => ["10.0.0.201:9200", "10.0.0.202:9200", "10.0.0.203:9200"]
      index => "nginxaccess-%{+YYYY.MM.dd}"
      template_overwrite => true
    }
    stdout {
      codec => rubydebug
    }
  }

  if "nginx-error" in [tags] {
    elasticsearch {
      hosts => ["10.0.0.201:9200", "10.0.0.202:9200", "10.0.0.203:9200"]
      index => "nginxerrorlog-%{+YYYY.MM.dd}"
      template_overwrite => true
    }
  }

}
eof
```

```powershell
# 测试
logstash
sudo -u logstash /usr/share/logstash/bin/logstash -r -f /etc/logstash/conf.d/redis-to-es.conf

# 在 Nginx 服务器将地理坐标文件刷到日志文件中，在 logstash 中观察；
如果刷入日志数据不能生效，则尝试刷入少量数据
head -n20 nginx.access_json.log-20210421 > /var/log/nginx/access_json.log
cat nginx.access_json.log-20210421   > /var/log/nginx/access_json.log 


# 查看并添加 Kibana 样例地图 （具体操作可见视频或者课件 6.3.7.1 ）
# 生成索引模板，复制上面 GET 查询索引的结果中mappings开始的行到 settings 行之前结束,并最后再加一个 }
# 将 GET 得出的 mappings 部分内容复制到 PUT 模板中，只修改"coordinates": { "type": "geo_point" } 部分
GET /nginx-access-2025.12.09
PUT /_template/template_nginx_accesslog
# 将 GET 内容替换掉 PUT 内容后，将修改后的模板在开发工具的控制台输入，执行 ok 则后续要删除旧的索引数据,上面修改才能生效（必须）

```



- 配置 Logstash 读取 Kafka 日志发送到 Elasticsearch （二选一）

```powershell
cat > /etc/logstash/conf.d/kafka-to-es.conf <<'eof'
input {
  kafka {
    bootstrap_servers => "10.0.0.91:9092,10.0.0.92:9092,10.0.0.93:9092"
    topics => "filebeat-log"
    codec => "json"

    # group_id => "logstash"          # 消费者组名称
    # consumer_threads => "3"         # 建议和 kafka 分区数一致
    # topics_pattern => "nginx-.*"    # 通过正则表达式匹配topic，而非用上面topics=>指定固定值
  }
}

filter {
  if "nginx-access" in [tags] {
    geoip {
      source => "clientip"
      target => "geoip"
      add_field => ["[geoip][coordinates]", "%{[geoip][geo][location][lon]}"]
      add_field => ["[geoip][coordinates]", "%{[geoip][geo][location][lat]}"]
    }

    mutate {
      convert => ["[geoip][coordinates]", "float"]
    }
  }

  mutate {
    convert => ["upstreamtime", "float"]
  }
}

output {
  # stdout {}   # 调试使用

  if "nginx-access" in [tags] {
    elasticsearch {
      hosts => ["10.0.0.201:9200"]
      index => "logstash-kafka-nginx-accesslog-%{+YYYY.MM.dd}"
    }
  }

  if "nginx-error" in [tags] {
    elasticsearch {
      hosts => ["10.0.0.201:9200"]
      index => "logstash-kafka-nginx-errorlog-%{+YYYY.MM.dd}"
    }
  }

  if "syslog" in [tags] {
    elasticsearch {
      hosts => ["10.0.0.201:9200"]
      index => "logstash-kafka-syslog-%{+YYYY.MM.dd}"
    }
  }
}
eof

# 停止服务，以 logstash 用户在前台启动配置文件
systemctl  stop logstash.service
sudo -u logstash /usr/share/logstash/bin/logstash -f /etc/logstash/conf.d/kafka-to-es.conf -r
# 在 filebeat 服务所在的设备进行模拟日志数据变更，然后在 logstash 服务器进行观察
mv mall_app.log  /var/log/mall_app.log 
# logstash 服务器收到 filebeat 收集的数据，整理并发送到 ES 中，在 ES 可视化图形界面中可以看到这个索引
mall-app-2025.12.09
```

```powershell
# 9.0.1 不能以 root 启动，还要求对 /usr/share/logstash/data 有权限；
chmod 777 /usr/share/logstash/data
chown logstash:logstash /etc/logstash/conf.d/kafka-to-es.conf
chown -R logstash: /usr/share/logstash/data
su - logstash -s /bin/bash
/usr/share/logstash/bin/logstash --path.settings /etc/logstash -t
/usr/share/logstash/bin/logstash -f /etc/logstash/conf.d/kafka-to-es.conf

systemctl status logstash.service
```

验证结果

```powershell
# Logstash 先启动订阅 kafka，再生成新数据才能采集；利用 Kafka tool 工具查看
```

##### ES 集群 

> 参考之前的配置



##### Kibana

###### 安装

```powershell
dpkg -i kibana-9.2.2-amd64.deb

grep -Ev "^[a-Z]" /etc/kibana/kibana.yml
# 监听端口,此为默认值,可不做修改
server.port: 5601 
# 修改此行的监听地址,默认为localhost，即：127.0.0.1:5601
server.host: "0.0.0.0" 
# 修改此行,指向ES任意服务器地址或多个节点地址实现容错,默认为localhost
elasticsearch.hosts: ["http://10.0.0.201:9200","http://10.0.0.202:9200","http://10.0.0.203:9200"]
# 修改此行,使用"zh-CN"显示中文界面,默认英文
i18n.locale: "zh-CN"  
# 8.X版本新添加配置,默认被注释,会显示下面提示
server.publicBaseUrl: "http://kibana.duan.org"
```

启动 Kibana 服务并验证

```powershell
# 默认没有开机自动启动，需要自行设置
systemctl start kibana ; systemctl status kibana
ss -ntlp |grep node && ps aux |grep node
# 默认以kibana用户启动服务
id kibana
```

在 ES 节点上生成token

> **Kibana 8.X 开启 xpack.security 功能连接ES**
>
> **从 8.x 开始 enrollment token 必须依赖 `xpack.security`；如果配置中这个参数是 false 那么 enrollment token 直接不可用**
>
> 集群节点都需要做 `xpack.security.enabled: true` 配置；

```powershell
# 在ES节点上生成token
#/usr/share/elasticsearch/bin/elasticsearch-create-enrollment-token --scope kibana
eyJ2ZXIiOiI4LjE0LjAiLCJhZHIiOlsiMTAuMC4wLjEwMDo5MjAwIl0sImZnciI6IjdhMzIyMWRhNmFm
OWI1YzUzYzJiMjM3YjJiMjg3MzcwZTBlOGNiOTZkNmJlYjI4MzdkZDFkYzJlNTE4ZDU3OWUiLCJrZXki
OiJRVl90TUpFQkk4OFloVFdtVHFKTDptdmsxNXUtYVI1T3g4bzZ3ZTNYVGdBIn0=
# 修改kibana配置文件
grep -Ev "#|^$" /etc/kibana/kibana.yml
server.host: 0.0.0.0 #修改此行
elasticsearch.hosts: ['https://10.0.0.201:9200'] # 修改此行,指向 elasticsearch 地址
logging.appenders.file.type: file
logging.appenders.file.fileName: /var/log/kibana/kibana.log
logging.appenders.file.layout.type: json
logging.root.appenders: [default, file]
pid.file: /run/kibana/kibana.pid
i18n.locale: zh-CN # 修改此行

# 浏览器访问,填写上面的token		http://10.0.0.201:5601/

# 利用 elasticsearch 的用户密码登录
```

> **Kibana 8.X 禁用 xpack.security 功能连接ES**

```powershell
# 浏览器访问下面链接 
http://10.0.0.200:5601
# 在左侧的任务栏中招到 堆栈监测 —— 使用内部收集设置 —— 打开 Monitoring 
# 查看状态
http://10.0.0.200:5601/status
```

###### 管理索引

```powershell
# 进入浏览器 http://10.0.0.200:5601 —— 左侧任务栏 —— 开发工具 —— 控制台下的 Shell 输入：GET _search  —— 执行；
# 创建索引并执行
POST /index_wang/_doc/1
{
"username": "wang",
"age": 18,
"title": "cto"
}
# 查看索引
GET /index_wang/_doc/1
```

###### 创建索引模式

```powershell
# 进入浏览器 http://10.0.0.200:5601 —— 左侧任务栏 —— Stack Management —— 左侧任务栏的 数据视图 —— 创建数据视图 ——自定义名称和模式 —— 保存
```

**查看索引**

```powershell
# 进入浏览器 http://10.0.0.200:5601 —— 左侧任务栏 —— Discover 
```



#### 案例二

- 收集应用特定格式的日志输出至 Elasticsearch 并利用 Kibana 展示

##### Filebeat

> - **Filebeat 配置文件中的 type** 
>   - **在 8.X 以前版本是：- type: log**
>   - **在 8.X 以后版本是：- type: filestream**

```powershell
ls /var/log/mall_app.log
cp  /etc/filebeat/filebeat.yml /root/filebeat.yaml-nginx-logstash && rm -f /etc/filebeat/filebeat.yml
# 修改 filebeat 配置文件
cat > /etc/filebeat/filebeat.yml <<'eof'
filebeat.inputs:
  - type: filestream
    id: my-filestream-id-1
    enabled: true
    tags: ["mall"]
    paths:
      - /var/log/mall_app.log
    parsers:
      - ndjson:
          target: ""   # 解析结果存放在指定字段下，如果为空则保存在根下
          # message_key: message  # 对哪个字段做 json 解析，可选

output.logstash:
  hosts: ["10.0.0.100:5044"]
  indes: filebeat
  loadbalance: true
  worker: 1
  compression_level: 3
eof

systemctl  restart filebeat
```

##### Logstash

```powershell
mv   /etc/logstash/conf.d/  /root/
# 创建配置文件
cat /etc/logstash/conf.d/app_filebeat_filter_es.conf
input {
  beats {
    port => 5044
  }
}

filter {
  # mutate 切割操作
  mutate {
    # 字段分隔符
    split => { "message" => "|" }

    # 添加字段
    add_field => {
      "user_id" => "%{[message][1]}"
      "action"  => "%{[message][2]}"
      "time"    => "%{[message][3]}"
      # "[@metadata][target_index]" => "mall-app-%{+YYYY.MM.dd}"
    }

    # 删除无用字段
    remove_field => ["message"]

    # 对新添加字段进行格式转换
    convert => {
      "user_id" => "integer"
      "action"  => "string"
      "time"    => "string"
    }
  }

  date {
    # 覆盖原来的 @timestamp 时间字段
    match   => ["time", "yyyy-MM-dd HH:mm:ss"]
    target  => "@timestamp"
    timezone => "Asia/Shanghai"
  }
}

output {
  stdout {
    codec => rubydebug
  }

  elasticsearch {
    hosts => [
      "10.0.0.201:9200",
      "10.0.0.202:9200",
      "10.0.0.203:9200"
    ]
    index => "mall-app-%{+YYYY.MM.dd}"
    # index => "%{[@metadata][target_index]}"
    template_overwrite => true
  }
}


# 停止服务，以 logstash 用户在前台启动配置文件
systemctl  stop logstash.service
sudo -u logstash /usr/share/logstash/bin/logstash -f /etc/logstash/conf.d/app_filebeat_filter_es.conf -r
# 在 filebeat 服务所在的设备进行模拟日志数据变更，然后在 logstash 服务器进行观察
mv mall_app.log  /var/log/mall_app.log 
# logstash 服务器收到 filebeat 收集的数据，整理并发送到 ES 中，在 ES 可视化图形界面中可以看到这个索引
mall-app-2025.12.09
```

##### Kibana 创建索引模式

```powershell
# 创建数据视图 —— discover —— 就可以看到刚刚创建的数据视图
# 对数据中的标签进行过滤重组，使其可视化，进入 Visualize 库 —— 新建可视化 —— （旧版）-聚合 —— 垂直视图 （可选）—— 分桶 —— X —— 词 —— 选择字段
```

![image-20251209163240962](https://cdn.jsdelivr.net/gh/duanxueli08-cell/Obsidian-Images@main/img/image-20251209163240962.png)

![image-20251209164316010](https://cdn.jsdelivr.net/gh/duanxueli08-cell/Obsidian-Images@main/img/image-20251209164316010.png)

![image-20251209164500979](https://cdn.jsdelivr.net/gh/duanxueli08-cell/Obsidian-Images@main/img/image-20251209164500979.png)

![image-20251209172502099](https://cdn.jsdelivr.net/gh/duanxueli08-cell/Obsidian-Images@main/img/image-20251209172502099.png)

##### Nginx

```powershell
# Kibana 可视化图表做好后，复制上面嵌入式链接；
# 在 Nginx 中新建文件，将链接复制进入，并做一点尺寸展示的调整；
echo "<iframe src="http://10.0.0.200:5601/app/r/s/0et65" height="1600" width="1800"></iframe>" >> /var/www/html/index.html
# 访问 Nginx 网页，就可以看到 Kibana 做好的可视化图表
```



