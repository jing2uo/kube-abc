
## **部署过程**

```shell
/workflow
    ├── 1-function.sh    # 定义了大部分通用函数
    ├── 2-registry.sh    # 部署 registry
    ├── 3-gpu.sh         # 腾讯开源 gpu 方案
    ├── cleanup.sh       # 清理节点
    └── origin-file      # 执行 prepare.sh 会替换 CHANGEM 为当前节点 ip
        ├── index.html        # 浏览器打开 localhost:8989 可以看到帮助信息
        ├── cmd               # 命令行 curl localhost:8989/cmd 可以看到帮助信息
        ├── join.sh           # 添加节点
        └── onenode.sh        # 单点部署

```
