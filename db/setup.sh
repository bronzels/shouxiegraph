pip install py2neo pyahocorasick neo4j-driver
mkdir neo4j-data
docker run -d --restart=always --name neo4j -p 7474:7474 -p 7687:7687 -v $PWD/neo4j-data:/data neo4j:4.4.0
docker exec -it neo4j neo4j --version
#5.23.0,没有all只有extended jar下载设置后return apoc.version()报错, 4.4.0.31的apoc和4.4.0的neo4j也不兼容，启动报错
wget -c https://github.com/neo4j-contrib/neo4j-apoc-procedures/releases/download/4.4.0.1/apoc-4.4.0.1-all.jar
docker cp neo4j:/var/lib/neo4j/conf neo4j-conf
cp neo4j-conf/neo4j.conf neo4j-conf/neo4j.conf.bk
echo "dbms.security.procedures.unrestricted=apoc.*" >> neo4j-conf/neo4j.conf
docker cp neo4j:/var/lib/neo4j/plugins neo4j-plugins
#mv apoc-5.23.0-extended.jar neo4j-plugins
mv ../../apoc-4.4.0.1-all.jar neo4j-plugins/
docker stop neo4j && docker rm neo4j
docker run -d --restart=always --name neo4j -p 7474:7474 -p 7687:7687 -v $PWD/neo4j-data:/data -v $PWD/neo4j-conf:/var/lib/neo4j/conf -v $PWD/neo4j-plugins:/var/lib/neo4j/plugins neo4j:4.4.0
    #RETURN apoc.version()
    #"4.4.0.1"
    -v $PWD/neo4j-conf:/var/lib/neo4j/conf \
docker run -d --restart=always \
    -p 7474:7474 -p 7687:7687 \
    -v $PWD/neo4j-data:/data \
    -v $PWD/neo4j-plugins:/plugins \
    -v $PWD/neo4j-import:/var/lib/neo4j/import \
    --name neo4j \
    -e NEO4J_apoc_export_file_enabled=true \
    -e NEO4J_apoc_import_file_enabled=true \
    -e NEO4J_apoc_import_file_use__neo4j__config=true \
    -e NEO4J_dbms_security_procedures_unrestricted=apoc.\* \
    neo4j:4.4.0
docker cp neo4j:/var/lib/neo4j/conf neo4j-conf
cp neo4j-conf/neo4j.conf neo4j-conf/neo4j.conf.bk
docker stop neo4j && docker rm neo4j
docker run -d --restart=always \
    -p 7474:7474 -p 7687:7687 \
    -v $PWD/neo4j-data:/data \
    -v $PWD/neo4j-plugins:/plugins \
    -v $PWD/neo4j-import:/var/lib/neo4j/import \
    -v $PWD/neo4j-conf:/var/lib/neo4j/conf \
    --name neo4j \
    -e NEO4J_apoc_export_file_enabled=true \
    -e NEO4J_apoc_import_file_enabled=true \
    -e NEO4J_apoc_import_file_use__neo4j__config=true \
    -e NEO4J_dbms_security_procedures_unrestricted=apoc.\* \
    neo4j:4.4.0
#Graph Data Science最低只能和Neo4j 4.4.9配套，目前最新release GDS 2.8.0最高只能和Neo4j 5.22.0配合
wget -c https://github.com/neo4j/graph-data-science/releases/download/2.8.0/neo4j-graph-data-science-2.8.0.jar
mv neo4j-graph-data-science-2.8.0.jar neo4j-plugins/
    -v $PWD/neo4j-conf:/var/lib/neo4j/conf \
docker run -d --restart=always \
    -p 7474:7474 -p 7687:7687 \
    -v $PWD/neo4j-data:/data \
    -v $PWD/neo4j-plugins:/plugins \
    -v $PWD/neo4j-import:/var/lib/neo4j/import \
    --name neo4j \
    -e NEO4J_apoc_export_file_enabled=true \
    -e NEO4J_apoc_import_file_enabled=true \
    -e NEO4J_apoc_import_file_use__neo4j__config=true \
    -e NEO4J_dbms_security_procedures_unrestricted=apoc.\*,gds.\* \
    neo4j:5.22.0

git clone git@github.com:usstzcx/KGData.git
docker exec -it neo4j neo4j-admin import --database baike.db \
                                         --id-type=STRING --multiline-fields=true \
                                         --nodes "import/KGData/百科10w条/entity10.csv" \
                                         --relationships "import/KGData/百科10w条/relationship10.csv"
echo "dbms.active_database=baike.db" >> neo4j-conf/neo4j.conf
echo "dbms.allow_upgrade=true" >> neo4j-conf/neo4j.conf

wget -c https://raw.githubusercontent.com/neo4j-graph-examples/graph-data-science2/main/data/airport-node-list.csv
wget -c https://raw.githubusercontent.com/neo4j-graph-examples/graph-data-science2/main/data/iroutes-edges.csv

git clone git@github.com:vesoft-inc/nebula-docker-compose
cd nebula-docker-compose
docker compose up -d
docker run --rm -ti --network nebula-docker-compose_nebula-net --entrypoint=/bin/sh vesoft/nebula-console
    nebula-console -u root -p root --address=graphd --port=9669
mkdir nebula-graph-studio
tar xzvf nebula-graph-studio-3.10.0.tar.gz -C nebula-graph-studio
cd nebula-graph-studio
docker compose up -d

