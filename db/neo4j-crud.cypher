MATCH(n) RETURN n

CREATE (n:Person {name:'John'}) RETURN n

`CREATE (n:Person {name:'Sally'}) RETURN n;`
CREATE (n:Person {name:'Steve'}) RETURN n;
CREATE (n:Person {name:'Mike'}) RETURN n;
CREATE (n:Person {name:'Liz'}) RETURN n;
CREATE (n:Person {name:'Shawn'}) RETURN n;

CREATE (n:Location {city:'Miami', state:'FL'});
CREATE (n:Location {city:'Boston', state:'MA'});
CREATE (n:Location {city:'Lynn', state:'MA'});
CREATE (n:Location {city:'Portland', state:'ME'});
CREATE (n:Location {city:'San Francisco', state:'CA'});

MATCH (a:Person {name:'Liz'}), 
      (b:Person {name:'Mike'})
MERGE (a)-[:FRIENDS]->(b)
MATCH (a:Person {name:'Liz'}),
      (b:Person {name:'Mike'})
MERGE (a)-[:FRIENDS {since:2001}]->(b)
#这个写法会导致2条重复关系

MATCH (a:Person {name:'Liz'})-[r:FRIENDS]->(b:Person {name:'Mike'})
    DELETE r

MATCH (a:Person {name:'Liz'}), 
      (b:Person {name:'Mike'})
MERGE (a)-[:FRIENDS]->(b)

MATCH (a:Person {name:'Liz'}),
      (b:Person {name:'Mike'})
MERGE (a)-[rel:FRIENDS]->(b)
SET rel.since=2001


MATCH (a:Person {name:'Sally'}),
      (b:Person {name:'John'})
MERGE (a)-[:FRIENDS {since:2021}]->(b);

MATCH (a:Person {name:'Mike'}),
      (b:Person {name:'Steve'})
MERGE (a)-[:FRIENDS {since:2021}]->(b);

MATCH ()-[r:FRIENDS]->()
WHERE r.since>2015 AND r.end.name='Steve'
    DELETE r
#r.end不起作用
MATCH p=(a)-[r:FRIENDS]->(b)
WHERE b.name='Steve'
    RETURN p
MATCH (a)-[r:FRIENDS]->(b)
WHERE b.name='Steve'
    DELETE r
MATCH (a)-[r:FRIENDS]->(b)
WHERE r.since<2015 AND b.name='Steve'
    DELETE r
MATCH (a)-[r:FRIENDS]->(b)
WHERE r.since>2015 AND b.name='Steve'
    DELETE r

MATCH (a:Person {name:'Steve'})
DELETE a

MATCH (a:Person {name:'John'})
SET a.age=21;
MATCH (a:Person {name:'Sally'})
SET a.age=22;
MATCH (a:Person {name:'Steve'})
SET a.age=23;
MATCH (a:Person {name:'Mike'})
SET a.age=24;
MATCH (a:Person {name:'Liz'})
SET a.age=25;
MATCH (a:Person {name:'Shawn'})
SET a.age=26;


MATCH (a:Person {name:'John'})
SET a.work='月亮中学';
MATCH (a:Person {name:'Sally'})
SET a.work='月亮小学';
MATCH (a:Person {name:'Steve'})
SET a.work='月亮乡政府';
MATCH (a:Person {name:'Mike'})
SET a.work='脚本之家';
MATCH (a:Person {name:'Liz'})
SET a.work='站长之家';
MATCH (a:Person {name:'Shawn'})
SET a.work='月光小家';



MATCH (a:Person {name:'Shawn'}),
      (b:Person {name:'Liz'})
MERGE (a)-[:FRIENDS {since:2011}]->(b);
MATCH (a:Person {name:'Steve'}),
      (b:Person {name:'Sally'})
MERGE (a)-[:FRIENDS {since:2012}]->(b);

MATCH (n:Person {name:'Steve'})-[r1:FRIENDS]-()-[r2:FRIENDS]-(friend_of_a_friend) RETURN friend_of_a_friend.name
#无方向，返回2条记录
MATCH (n:Person {name:'Steve'})-[r1:FRIENDS]->()-[r2:FRIENDS]->(friend_of_a_friend) RETURN friend_of_a_friend.name
#有防线，返回1条记录

{batch:[{id:"alice@example.com",properties:{name:"Alice",age:32}},{id:"bob@example.com",properties:{name:"Bob",age:42}}]};
UNWIND {batch} as row
MERGE (n:Label {id:row.id,name:row.properties.name,age:row.properties.age})
ON CREATE
    SET n.created = timestamp()
RETURN n.name,n.age,n.created
#总是报错

UNWIND [{id:"alice@example.com",properties:{name:"Alice",age:32}},{id:"bob@example.com",properties:{name:"Bob",age:42}}] as row
MERGE (n:Label {id:row.id,name:row.properties.name,age:row.properties.age})
ON CREATE
    SET n.created = timestamp()
RETURN n.name,n.age,n.created

UNWIND [{id:"alice@example.com",properties:{name:"Alice",age:32}},{id:"bob@example.com",properties:{name:"Bob",age:42}}] as row
MERGE (n:Label {id:row.id,name:row.properties.name,age:row.properties.age})
ON CREATE
    SET n.created = timestamp()
ON MATCH
    SET n.found = true
RETURN n.name,n.age,n.created,n.found

CREATE INDEX FOR (n:Person) ON n.name
:SCHEMA
DROP INDEX index_4b2e9408
CREATE CONSTRAINT FOR (n:Person) REQUIRE n.name IS UNIQUE

CREATE INDEX FOR ()-[r:FRIENDS]->() ON r.since

MERGE (robert:Critic)
RETURN labels(robert)

MERGE (robert:Critic:Viewer)
RETURN labels(robert)
MERGE (robert:Critic&Viewer)
RETURN labels(robert)
#会创建重复节点

MATCH (n:Critic:Viewer)
DELETE n

MATCH (n:Critic)
set n:Viewer
RETURN labels(n)


MERGE (charlie:hero {name: 'Charlie Sheen', age: 10})
RETURN charlie
MERGE (charlie:hero {name: 'Charlie Sheen', age: 10})
RETURN charlie
#不会创建重复节点
MERGE (charlie:hero {name: 'Charlie Sheen', age: 10, height: 180})
RETURN charlie
#创建重复节点

MATCH (n:hero {name: 'Charlie Sheen', age: 10, height: 180})
DELETE n

MERGE (n:Person {name: 'Zac'})
ON CREATE
    SET n.counter = 1
ON MATCH
    SET n.counter = n.counter + 1
RETURN n.name, n.counter

LOAD CSV WITH HEADERS FROM 'file:///data/bike_test.csv' AS line
CALL {
    WITH line
    MERGE (u:User {id: line[1]})
    ON CREATE
        SET u.counter = 1
    ON MATCH
        SET u.counter = u.counter + 1;
    WITH line
    MERGE (b:Bike {id:line[2], type:line[3]})
    ON CREATE
        SET b.counter = 1
    ON MATCH
        SET b.counter = b.counter + 1;
    WITH line
    MATCH (u:User {id: line[1]}), (b:Bike {id:line[2]})
    MERGE (u)-[rel:Ride]->(b)
    ON CREATE
        SET rel.counter = 1, rel.first_time = line[4], rel.last_time = line[4]
    ON MATCH
        SET rel.counter = rel.counter + 1, rel.first_time = CASE WHEN line[4] < rel.first_time THEN line[4] ELSE rel.first_time, rel.last_time = CASE WHEN line[4] > rel.last_time THEN line[4] ELSE rel.last_time;
} IN TRANSACTIONS OF 100 ROWS
#CALL {}不能多条语句用分号隔开

LOAD CSV WITH HEADERS FROM 'file:///data/bike_test.csv' AS line
CALL {
    WITH line
    MATCH (u:User {id: line[1]}), (b:Bike {id:line[2], type:line[3]})
    MERGE (u)-[relU2O:Buy]->(o:Order {id:line[0], time:line[4], start_loc:line[5], end_loc:line[6]})-[relO2B:Use]->(b)
} IN TRANSACTIONS OF 100 ROWS
#不能[0]访问line的字段，没有with headers 才使用  property[0]

#docker exec -it neo4j ln -s /data/bike_test.csv /var/lib/neo4j/import/bike_test.csv
LOAD CSV WITH HEADERS FROM 'file:///bike_test.csv' AS line
CALL {
    WITH line
    MATCH (u:User {id: line.userid}), (b:Bike {id:line.bikeid, type:line.biketype})
    MERGE (u)-[relU2O:Buy]->(o:Order {id:line.orderid, time:line.starttime, start_loc:line.geohashed_start_loc, end_loc:line.geohashed_end_loc})-[relO2B:Use]->(b)
} IN TRANSACTIONS OF 100 ROWS
#在neo4j的web客户端执行报错
#A query with 'CALL { ... } IN TRANSACTIONS' can only be executed in an implicit transaction, but tried to execute in an explicit transaction.
#python执行成功


MERGE (u:User {id: '285225'})
MERGE (b:Bike {id:'402119', type:'1'})
MERGE (u)-[relU2O:Buy]->(o:Order {id:'111113924462', time:'2009-09-9 22:17:14', start_loc:'11111wx4eyv8', end_loc:'11111wx4eytj'})-[relO2B:Use]->(b)

MATCH(m:User {id:'285225'}) RETURN m
#1条记录没有重复
MATCH(n:Bike {id:'402119'}) RETURN n
#1条记录没有重复
MATCH(m:User {id:'285225'})-[:Buy]->(o:Order)-[:Use]->(n:Bike {id:'402119'}) RETURN o
#2个关系，2条记录


MATCH(n:BikeWC)<-[rel:RideWC]-(m:UserWC) WHERE m.counter > 1 OR n.counter > 1 OR rel.counter > 1 RETURN m,n,rel
#有3个子图

RETURN apoc.version()

CALL apoc.load.json("file:///apoc-test.json") YIELD value
UNWIND value.hobbies AS hobby
MERGE (p:Person {name:value.name, age:value.age})
MERGE (h:Hobby {name:hobby.name, level:hobby.level})
MERGE (p)-[:HAS_HOBBY]->(h)

CALL apoc.help('apoc')

CALL dbms.functions() YIELD name WHERE name STARTS WITH 'apoc.' RETURN COUNT(name)
UNION
CALL dbms.procedures() YIELD name WHERE name STARTS WITH 'apoc.' RETURN COUNT(name)
#5.22没有这2个函数

MATCH(n) DETACH DELETE n

CALL apoc.generate.ba(10,2,'Person','朋友')

MATCH p=(n)-[r]->(m) RETURN p

MATCH (n) DETACH DELETE n

FOREACH(id in range(1,1000) | CREATE (n:NodeLabel{id:id}))

MATCH (n1:NodeLabel),(n2:NodeLabel) WITH n1, n2 LIMIT 1000000 WHERE rand()<0.1
CREATE (n1)-[:REL_TYPE]->(n2)
