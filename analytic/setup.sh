#GeaFlow
#Download Code：
git clone git@github.com:TuGraph-family/tugraph-analytics
#Build Project：
mvn clean install -DskipTests
#Test Job：
./bin/gql_submit.sh --gql geaflow/geaflow-examples/gql/loop_detection.sql
./bin/socket.sh
:<<EOF
. 1,jim
. 2,kate
. 3,lily
. 4,lucy
. 5,brown
. 6,jack
. 7,jackson
- 1,2,0.2
- 2,3,0.3
- 3,4,0.2
- 4,1,0.1
>> 1,2,3,4,1
>> 2,3,4,1,2
>> 3,4,1,2,3
>> 4,1,2,3,4
- 4,5,0.1
>> 1,2,3,4,1
>> 2,3,4,1,2
>> 3,4,1,2,3
>> 4,1,2,3,4
- 5,1,0.2
>> 1,2,3,4,1
>> 2,3,4,1,2
>> 3,4,1,2,3
>> 4,1,2,3,4
- 5,6,0.1
>> 1,2,3,4,1
>> 2,3,4,1,2
>> 3,4,1,2,3
>> 4,1,2,3,4
- 6,7,0.1
>> 1,2,3,4,1
>> 2,3,4,1,2
>> 3,4,1,2,3
>> 4,1,2,3,4
EOF
file=build.sh
cp ${file} ${file}.bk
#sed -i "s/docker/nerdctl/g" ${file}
#解决文件句柄限制问题
#设置镜像
file=geaflow/geaflow-deploy/docker/Dockerfile
cp ${file} ${file}.bk
\cp ${file} ./
\cp Dockerfile ${file}
cp etc-security-limits.conf geaflow/geaflow-deploy/docker/
bash ./build.sh --all
wget -c https://github.com/async-profiler/async-profiler/releases/download/v3.0/async-profiler-3.0-linux-x64.tar.gz
wget -c https://github.com/async-profiler/async-profiler/releases/download/v3.0/converter.jar
./bin/gql_submit.sh --gql geaflow/geaflow-examples/gql/loop_detection.sql --profiler /data0/async-profiler/bin/asprof
nerdctl pull tugraph/geaflow-console:0.1
nerdctl run -d --name geaflow-console -p 8888:8888 tugraph/geaflow-console:0.1
nerdctl ps
nerdctl exec -it geaflow-console tail -f /tmp/logs/geaflow/app-default.log
#创建用户，登录，提交sql作业都会死住不动，容器也没有提示
nerdctl stop geaflow-console && nerdctl rm geaflow-console

#Build Image：
nerdctl pull tugraph/geaflow:0.4 --namespace k8s.io
#如果拉不下来
./build.sh --all --module=geaflow
cp tugraph-analytics/geaflow/geaflow-deploy/docker/supervisord.conf ./
:<<EOF
#修改supervisord配置
minfds=102400                  ; (min. avail startup file descriptors;default 1024)
minprocs=20000                 ; (min. avail process descriptors;default 200)
改成
minfds=1024                  ; (min. avail startup file descriptors;default 1024)
minprocs=200                 ; (min. avail process descriptors;default 200)
EOF
cat << EOF > Dockerfile-fileno
FROM tugraph/geaflow:0.4
COPY etc-security-limits.conf /etc/security/limits.conf
COPY supervisord.conf /etc/supervisor/supervisord.conf
EOF
#nerdctl --namespace k8s.io build -t tugraph/geaflow-fileno:0.4 -f ./Dockerfile-fileno . 
docker build -t harbor.my.org:1080/geaflow/geaflow-fileno:0.4 -f ./Dockerfile-fileno . 
docker push harbor.my.org:1080/geaflow/geaflow-fileno:0.4
#如果拉不下来
cd geaflow-kubernetes-operator/
bash ./build-operator.sh
kubectl create ns geaflow
kubectl create serviceaccount geaflow --namespace=geaflow
kubectl create clusterrolebinding geaflow-role-binding --clusterrole=edit --serviceaccount=geaflow:geaflow --namespace=geaflow
cd helm/geaflow-kubernetes-operator
file=values.yaml
cp ${file} ${file}.bk
sed -i 's/  tag: ""/  tag: "0.4"/g' ${file}
repository: geaflow-kubernetes-operator改成repository: tugraph/geaflow-kubernetes-operator

helm install geaflow-kubernetes-operator ./ -n geaflow
:<<EOF

NAME: geaflow-kubernetes-operator
LAST DEPLOYED: Fri Oct 25 16:29:40 2024
NAMESPACE: geaflow
STATUS: deployed
REVISION: 1
NOTES:
1. Get the application URL by running these commands:
  export POD_NAME=$(kubectl get pods --namespace geaflow -l "app.kubernetes.io/name=geaflow-kubernetes-operator,app.kubernetes.io/instance=geaflow-kubernetes-operator" -o jsonpath="{.items[0].metadata.name}")
  export CONTAINER_PORT=$(kubectl get pod --namespace geaflow $POD_NAME -o jsonpath="{.spec.containers[0].ports[0].containerPort}")
  echo "Visit http://127.0.0.1:8080 to use your application"
  kubectl --namespace geaflow port-forward $POD_NAME 8080:$CONTAINER_PORT
EOF
helm uninstall geaflow-kubernetes-operator -n geaflow
kubectl port-forward -n geaflow svc/geaflow-kubernetes-operator 8080:80 &
#运行nginx，把/workspace文件web服务出来
#http://192.168.3.14:9004
#cat << \EOF > /workspace/shouxiegraph/analytic/geaflow_dsl_example.sql
cat << EOF > /workspace/shouxiegraph/analytic/geaflow_dsl_example.gql
set geaflow.dsl.window.size = 1;
set geaflow.dsl.ignore.exception = true;

CREATE GRAPH IF NOT EXISTS dy_modern (
  Vertex person (
    id bigint ID,
    name varchar
  ),
  Edge knows (
    srcId bigint SOURCE ID,
    targetId bigint DESTINATION ID,
    weight double
  )
) WITH (
  storeType='rocksdb',
  shardCount = 1
);

CREATE TABLE IF NOT EXISTS tbl_source (
  text varchar
) WITH (
  type='socket',
  `geaflow.dsl.column.separator` = '#',
  `geaflow.dsl.socket.host` = '192.168.3.14',
  `geaflow.dsl.socket.port` = 9003
);

CREATE TABLE IF NOT EXISTS tbl_result (
  a_id bigint,
  b_id bigint,
  c_id bigint,
  d_id bigint,
  a1_id bigint
) WITH (
  type='socket',
    `geaflow.dsl.column.separator` = ',',
    `geaflow.dsl.socket.host` = '192.168.3.14',
    `geaflow.dsl.socket.port` = 9003
);

USE GRAPH dy_modern;

INSERT INTO dy_modern.person(id, name)
SELECT
cast(trim(split_ex(t1, ',', 0)) as bigint),
split_ex(t1, ',', 1)
FROM (
  Select trim(substr(text, 2)) as t1
  FROM tbl_source
  WHERE substr(text, 1, 1) = '.'
);

INSERT INTO dy_modern.knows
SELECT
 cast(split_ex(t1, ',', 0) as bigint),
 cast(split_ex(t1, ',', 1) as bigint),
 cast(split_ex(t1, ',', 2) as double)
FROM (
  Select trim(substr(text, 2)) as t1
  FROM tbl_source
  WHERE substr(text, 1, 1) = '-'
);

INSERT INTO tbl_result
SELECT DISTINCT
  a_id,
  b_id,
  c_id,
  d_id,
  a1_id
FROM (
  MATCH (a:person) -[:knows]->(b:person) -[:knows]-> (c:person)
   -[:knows]-> (d:person) -> (a:person)
  RETURN a.id as a_id, b.id as b_id, c.id as c_id, d.id as d_id, a.id as a1_id
);
EOF
curl http://192.168.3.14:9004/shouxiegraph/analytic/geaflow_dsl_example.gql
kubectl create configmap -n geaflow limits-conf --from-file=etc-security-limits.conf
cat << EOF > geaflow_dsl_example.yaml
apiVersion: geaflow.antgroup.com/v1
kind: GeaflowJob
metadata:
  # 作业名称
  name: dsl-example
spec:
  # 作业使用的GeaFlow镜像
  image: harbor.my.org:1080/geaflow/geaflow-fileno:0.4
  # image: tugraph/geaflow:0.4
  # image: tugraph/geaflow:0.1
  # 作业拉取镜像的策略
  imagePullPolicy: IfNotPresent
  # 作业使用的k8s service account
  serviceAccount: geaflow
  # 作业java进程的主类
  # entryClass: com.antgroup.geaflow.example.graph.statical.compute.khop.KHop
  gqlFile:
    # name必须填写正确，否则无法找到对应文件
    name: geaflow_dsl_example.gql
    url: http://192.168.3.14:9004/shouxiegraph/analytic/geaflow_dsl_example.gql
  clientSpec:
    # client pod相关的资源设置
    resource:
      cpuCores: 1
      memoryMb: 1000
      jvmOptions: -Xmx800m,-Xms800m,-Xmn300m
  masterSpec:
    # master pod相关的资源设置
    resource:
      cpuCores: 1
      memoryMb: 1000
      jvmOptions: -Xmx800m,-Xms800m,-Xmn300m
  driverSpec:
    # driver pod相关的资源设置
    resource:
      cpuCores: 1
      memoryMb: 1000
      jvmOptions: -Xmx800m,-Xms800m,-Xmn300m
    # driver个数
    driverNum: 1
  containerSpec:
    # container pod相关的资源设置
    resource:
      cpuCores: 1
      memoryMb: 1000
      jvmOptions: -Xmx800m,-Xms800m,-Xmn300m
    # container个数
    containerNum: 1
    # 每个container内部的worker个数(线程数)
    workerNumPerContainer: 4
  userSpec:
    # 作业指标相关配置
    metricConfig:
      geaflow.metric.reporters: slf4j
      geaflow.metric.stats.type: memory
    # 作业存储相关配置
    stateConfig:
      geaflow.file.persistent.type: LOCAL
      geaflow.store.redis.host: my-redis-master.redis.svc.cluster.local
      geaflow.store.redis.port: "6379"
    # 用户自定义参数配置
    additionalArgs:
      kubernetes.resource.storage.limit.size: 12Gi
      geaflow.system.state.backend.type: MEMORY
EOF
kubectl apply -n geaflow -f geaflow_dsl_example.yaml
kubectl delete -n geaflow -f geaflow_dsl_example.yaml
nerdctl rmi --namespace k8s.io harbor.my.org:1080/geaflow/geaflow-fileno:0.4
kubectl logs -n geaflow dsl-example-client
#0.4/0.1 tag都提示
#Error: The minimum number of file descriptors required to run this process is 102400 as per the "minfds" command-line argument or config file setting. The current environment will only allow you to open 102400 file descriptors.  Either raise the number of usable file descriptors in your environment (see README.rst) or lower the minfds setting in the config file to allow the process to start.
#For help, use /usr/bin/supervisord -h