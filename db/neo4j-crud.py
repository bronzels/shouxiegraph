from py2neo import Graph, NodeMatcher, RelationshipMatcher, Node, Relationship, Path, Subgraph

url = 'bolt://localhost:7687'
user = 'neo4j'
pwd = '1234abcd'
g = Graph(url, auth=(user, pwd))
#g = Graph(url, auth=(user, pwd), name='baike.db')
#neo4j-admin导入数据以后，切换数据库，要用name连接新数据库
end = NodeMatcher(g).match("Person", name="Steve").first()

#rels = RelationshipMatcher(g).match([None, end], r_type="FRIENDS")
#print(rels.exists())
#rel = RelationshipMatcher(g).match([None, end], r_type="FRIENDS").where("_.since<2015").first()
rels = list(RelationshipMatcher(g).match([None, end], r_type="FRIENDS").where("_.since>2015"))
print(rels)
rels[0]["since"]
type(rels[0]).__name__
rels[0].keys()
rels[0].values()
rels[0].get('since')
rels[0].start_node['name']
rels[0].start_node.__name__
rels[0].end_node['name']
rels[0].end_node.__name__

rel = RelationshipMatcher(g).match([None, end], r_type="FRIENDS").where("_.since>2015").first()
print(rel)
rel = RelationshipMatcher(g).match([None, end], r_type="FRIENDS", since=2021).first()
#relation的属性匹配只有=能卸载match/where里不用双引号
print(rel)
#g.delete(rels)
#不加first是个list无法删除
g.separate(rel)
#报错
'''
for rel in rels.all():
    print(rel)
    #g.delete(rel)
    #会把start/end node也删掉
    g.seperate(rel)
'''

g.schema.node_labels
g.schema.relationship_types

node_matcher = NodeMatcher(g)
node = node_matcher.match("Person").where(name="Mike").first()
node
nodes = list(node_matcher.match("Person"))
nodes

nodes = list(node_matcher.match("Person").where(age>22))
#NameError: name 'age' is not defined
#不能用于模糊匹配
nodes = list(node_matcher.match("Person").where("_.age>22"))
nodes = list(node_matcher.match("Person").where("_.work=~'月亮.*'"))
nodes = list(node_matcher.match("Person").where("_.work=~'.*之家'"))
nodes[0]['name']
nodes = list(node_matcher.match("Person").where("_.work=~'.*光小.*'"))

node_1 = Node('hero', name="张无忌")
node_2 = Node('hero', name="杨逍", strength=100)
node_3 = Node('gangster', name="明教")
g.create(node_1)
g.create(node_2)
g.create(node_3)

test_node1 = Node("Person", name="大明")
test_node2 = Node("Person", name="小王")
g.merge(test_node1, "Person", "name")
g.merge(test_node2, "Person", "name")
g.merge(test_node1, "Person", "name")
g.merge(test_node2, "Person", "name")
'''
但py2neo和cypher中的merge方法有所不同。

在cypher中，MERGE方式是当你创建一个实体时，程序会检测是否已有这个实体存在，检测的方法是进行label和property的匹配。如果已存在则不创建。 py2neo方法中的merge则是，同样进行匹配，如果匹配上则用当前实体覆盖数据库中的已有实体。 这里的主要区别在于，匹配时一般只会用到关键的少数property，根据某个property去决定是否覆盖时，其他property可能是不相等的。

因此cypher是用数据库实体覆盖新创建的，py2neo是用新的覆盖旧的。 考虑到创建时属性可能比较少，因此在py2neo中慎用merge,可以先做存在判断，然后再用create语句.
'''

node_1_to_node_2 = Relationship(node_1, 'lead', node_2)
node_1_to_node_3 = Relationship(node_1, 'run', node_3)
node_2_to_node_3 = Relationship(node_2, 'from', node_3)
g.create(node_1_to_node_2)
g.create(node_1_to_node_3)
g.create(node_2_to_node_3)


node_4,node_5,node_6 = Node(name='阿大'),Node(name='阿二'),Node(name='阿三')
path_1 = Path(node_4, 'little_brother', node_5, Relationship(node_6, 'little_brother', node_5), node_6)
g.create(path_1)
path_1


node_7 = Node('hero', name='张翠山')
node_8 = Node('hero', name='殷素素')
node_9 = Node('hero', name='谢逊')
relationship7 = Relationship(node_1, 'father', node_7)
relationship8 = Relationship(node_1, 'mother', node_8)
relationship9 = Relationship(node_1, 'father_in_law', node_9)
sub_graph_1 = Subgraph(nodes=[node_7, node_8, node_9], relationships=[relationship7, relationship8, relationship9])
g.create(sub_graph_1)

rel = RelationshipMatcher(g).match([None, end], r_type="FRIENDS").where("_.since>2015").first()
rel['interaction_monthly'] = 5
print(rel)
g.push(rel)
rel = RelationshipMatcher(g).match([None, end], r_type="FRIENDS").where("_.since>2015").first()
print(rel)

node_matcher = NodeMatcher(g)
node = node_matcher.match("Person").where(name="Mike").first()
node
node['gender'] = 'male'
node.setdefault('marriage', default='未婚')
g.push(node)
node = node_matcher.match("Person").where(name="Mike").first()
node


transaction_1 = g.begin()

node_10 = Node('hero',name='张三丰')
transaction_1.create(node_10)
#relationship_10 = Relationship(node_1, 'teacher', node_10)
#relationship_11 = Relationship(node_1, 'wife', node_8)
relationship_10 = Relationship(node_7, 'teacher', node_10)
relationship_11 = Relationship(node_7, 'wife', node_8)
transaction_1.create(relationship_10)
transaction_1.create(relationship_11)

transaction_1.commit()

rel = RelationshipMatcher(g).match([node_1, node_8]).first()
g.separate(rel)
rel = RelationshipMatcher(g).match([node_1, node_10]).first()
g.separate(rel)

nodes=NodeMatcher(g).match("hero")
for node in list(nodes):
    g.delete(node)

cypher_ = """MATCH (n: Person) \
    WHERE n.work =~ '.*之家'
    RETURN n.name AS name, n.age AS age
"""
df = g.run(cypher_).to_data_frame()
df

cypher_ = """MATCH (n: Person)-[r]->(m: Person) \
    WHERE n.name = 'Mike'
    RETURN type(r) as type, m.name AS name
"""
df = g.run(cypher_).to_data_frame()
df

cypher_ = """MATCH path=(n: hero)-[:father|mother|wife*1..4]->(m: hero) \
    WHERE n.name = '张无忌' and m.name = '殷素素'
    RETURN path
"""
s = g.run(cypher_).to_series()
s


from neo4j import GraphDatabase

def create_person_node(tx, name):
    cmd = "CREATE (a:Person {name: $name}) RETURN id(a)"
    tx.run(cmd, name=name)

def load_bike_csv(tx, file_name):
    cmd="""LOAD CSV WITH HEADERS FROM 'file:///%s' AS line
CALL {
    WITH line
    MATCH (u:User {id: line.userid}), (b:Bike {id:line.bikeid, type:line.biketype})
    MERGE (u)-[relU2O:Buy]->(o:Order {id:line.orderid, time:line.starttime, start_loc:line.geohashed_start_loc, end_loc:line.geohashed_end_loc})-[relO2B:Use]->(b)
} IN TRANSACTIONS OF 100 ROWS""" % file_name
    print(cmd)
    tx.run(cmd)

def load_bike_csv_py2neo(py2neo_tx, file_name):
    cmd="""LOAD CSV WITH HEADERS FROM 'file:///%s' AS line
CALL {
    WITH line
    MATCH (u:User {id: line.userid}), (b:Bike {id:line.bikeid, type:line.biketype})
    MERGE (u)-[relU2O:Buy]->(o:Order {id:line.orderid, time:line.starttime, start_loc:line.geohashed_start_loc, end_loc:line.geohashed_end_loc})-[relO2B:Use]->(b)
    RETURN u.id,b.id,b.type,o.id,o.time,o.start_loc,o.end_loc
} IN TRANSACTIONS OF 100 ROWS""" % file_name
    print(cmd)
    py2neo_tx.run(cmd)
#(No data)
 
def load_bike_csv_py2neo(py2neo_tx, file_name):
    cmd="""LOAD CSV WITH HEADERS FROM 'file:///%s' AS line
CALL {
    WITH line
    MERGE (u:User {id: line.userid})
    MERGE (b:Bike {id:line.bikeid, type:line.biketype})
    MERGE (u)-[relU2O:Buy]->(o:Order {id:line.orderid, time:line.starttime, start_loc:line.geohashed_start_loc, end_loc:line.geohashed_end_loc})-[relO2B:Use]->(b)
} IN TRANSACTIONS OF 100 ROWS""" % file_name
    print(cmd)
    py2neo_tx.run(cmd)
    

def load_bike_csv_py2neo_counter(py2neo_tx, file_name):
    cmd="""LOAD CSV WITH HEADERS FROM 'file:///%s' AS line
CALL {
    WITH line
    MERGE (u:UserWC {id: line.userid})
    ON CREATE
        SET u.counter = 1
    ON MATCH
        SET u.counter = u.counter + 1
    WITH line
    MERGE (b:BikeWC {id:line.bikeid, type:line.biketype})
    ON CREATE
        SET b.counter = 1
    ON MATCH
        SET b.counter = b.counter + 1
    WITH line
    MATCH (u:UserWC {id: line.userid}), (b:BikeWC {id:line.bikeid})
    MERGE (u)-[rel:RideWC]->(b)
    ON CREATE
        SET rel.counter = 1, rel.first_time = line.starttime, rel.last_time = line.starttime
    ON MATCH
        SET rel.counter = rel.counter + 1, rel.first_time = CASE WHEN line.starttime < rel.first_time THEN line.starttime ELSE rel.first_time END, rel.last_time = CASE WHEN line.starttime > rel.last_time THEN line.starttime ELSE rel.last_time END
} IN TRANSACTIONS OF 100 ROWS""" % file_name
    print(cmd)
    py2neo_tx.run(cmd)

    
neo4j_client = GraphDatabase.driver(url, auth=(user, pwd))
_session = neo4j_client.session()
_session.write_transaction(create_person_node, "王小二")
_session.execute_write(load_bike_csv, "bike_test.csv")
load_bike_csv_py2neo(g, "bike_test.csv")
load_bike_csv_py2neo_counter(g, "bike_test.csv")
neo4j_client.close()

