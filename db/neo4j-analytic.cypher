MATCH (n:NodeLabel) WITH collect(n) AS ns
CALL apoc.algo.pageRank(ns) YIELD node,score
RETURN node,score
ORDER by score DESC LIMIT 10
#4.4以上版本很多算法被apoc删除了，都在gds里了

:play https://guides.neo4j.com/airport-routes/index.html

CREATE CONSTRAINT airports IF NOT EXISTS FOR (a:Airport) REQUIRE a.iata IS UNIQUE;
CREATE CONSTRAINT cities IF NOT EXISTS FOR (c:City) REQUIRE c.name IS UNIQUE;
CREATE CONSTRAINT regions IF NOT EXISTS FOR (r:Region) REQUIRE r.name IS UNIQUE;
CREATE CONSTRAINT countries IF NOT EXISTS FOR (c:Country) REQUIRE c.code IS UNIQUE;
CREATE CONSTRAINT continents IF NOT EXISTS FOR (c:Continent) REQUIRE c.code IS UNIQUE;
CREATE INDEX locations IF NOT EXISTS FOR (air:Airport) ON (air.location);

#'file:///var/lib/neo4j/import/airport-node-list.csv'
WITH
'file:///airport-node-list.csv'
 AS url
LOAD CSV WITH HEADERS FROM url AS row
MERGE (a:Airport {iata: row.iata})
MERGE (ci:City {name: row.city})
MERGE (r:Region {name: row.region})
MERGE (co:Country {code: row.country})
MERGE (con:Continent {name: row.continent})
MERGE (a)-[:IN_CITY]->(ci)
MERGE (a)-[:IN_COUNTRY]->(co)
MERGE (ci)-[:IN_COUNTRY]->(co)
MERGE (r)-[:IN_COUNTRY]->(co)
MERGE (a)-[:IN_REGION]->(r)
MERGE (ci)-[:IN_REGION]->(r)
MERGE (a)-[:ON_CONTINENT]->(con)
MERGE (ci)-[:ON_CONTINENT]->(con)
MERGE (co)-[:ON_CONTINENT]->(con)
MERGE (r)-[:ON_CONTINENT]->(con)
SET a.id = row.id,
 a.icao = row.icao,
 a.city = row.city,
 a.descr = row.descr,
 a.runways = toInteger(row.runways),
 a.longest = toInteger(row.longest),
 a.altitude = toInteger(row.altitude),
 a.location = point({latitude: toFloat(row.lat), longitude: toFloat(row.lon)});

LOAD CSV WITH HEADERS FROM 'file:///iroutes-edges.csv' AS row
MATCH (source:Airport {iata: row.src})
MATCH (target:Airport {iata: row.dest})
MERGE (source)-[r:HAS_ROUTE]->(target)
ON CREATE SET r.distance = toInteger(row.dist)

CALL db.schema.visualization()

CALL gds.graph.project(
'routes',
'Airport',
'HAS_ROUTE'
)
YIELD graphName, nodeProjection, nodeCount, relationshipProjection, relationshipCount

CALL gds.graph.list('routes')

CALL gds.pageRank.stream('routes')
YIELD nodeId, score
WITH gds.util.asNode(nodeId) AS n, score AS pageRank
RETURN n.iata AS iata, n.descr AS description, pageRank
ORDER BY pageRank DESC, iata ASC

CALL gds.louvain.stream('routes')
YIELD nodeId, communityId
WITH gds.util.asNode(nodeId) AS n, communityId
RETURN
communityId,
SIZE(COLLECT(n)) AS numberOfAirports,
COLLECT(DISTINCT n.city) AS cities
ORDER BY numberOfAirports DESC, communityId;

CALL gds.nodeSimilarity.stream('routes')
YIELD node1, node2, similarity
WITH gds.util.asNode(node1) AS n1, gds.util.asNode(node2) AS n2, similarity
RETURN
n1.iata AS iata,
n1.city AS city,
COLLECT({iata:n2.iata, city:n2.city, similarityScore: similarity}) AS similarAirports
ORDER BY city LIMIT 20

CALL gds.nodeSimilarity.stream(
'routes',
{
topK: 1,
topN: 10
}
)
YIELD node1, node2, similarity
WITH gds.util.asNode(node1) AS n1, gds.util.asNode(node2) AS n2, similarity AS similarityScore
RETURN
n1.iata AS iata,
n1.city AS city,
{iata:n2.iata, city:n2.city} AS similarAirport,
similarityScore
ORDER BY city

CALL gds.nodeSimilarity.stream(
'routes',
{
degreeCutoff: 100
}
)
YIELD node1, node2, similarity
WITH gds.util.asNode(node1) AS n1, gds.util.asNode(node2) AS n2, similarity
RETURN
n1.iata AS iata,
n1.city AS city,
COLLECT({iata:n2.iata, city:n2.city, similarityScore: similarity}) AS similarAirports
ORDER BY city LIMIT 20

CALL gds.graph.project(
'routes-weighted',
'Airport',
'HAS_ROUTE',
{
relationshipProperties: 'distance'
}
) YIELD
graphName, nodeProjection, nodeCount, relationshipProjection, relationshipCount

MATCH (source:Airport {iata: 'DEN'}), (target:Airport {iata: 'MLE'})
CALL gds.shortestPath.dijkstra.stream('routes-weighted', {
    sourceNode: source,
    targetNode: target,
    relationshipWeightProperty: 'distance'
})
YIELD index, sourceNode, targetNode, totalCost, nodeIds, costs, path
RETURN 
index,
gds.util.asNode(sourceNode).iata AS souceNodeName,
gds.util.asNode(targetNode).iata AS targetNodeName,
totalCost,
[nodeid in nodeIds|gds.util.asNode(nodeid).iata] AS nodeNames,
costs,
nodes(path) AS path
ORDER BY index

MERGE (home:Page {name:"Home"})
MERGE (about:Page {name:"About"})
MERGE (product:Page {name:"Product"})
MERGE (links:Page {name:"Links"})
MERGE (a:Page {name:"Site A"})
MERGE (b:Page {name:"Site B"})
MERGE (c:Page {name:"Site C"})
MERGE (d:Page {name:"Site D"})
MERGE (home)-[:LINKS]->(about)
MERGE (about)-[:LINKS]->(home)
MERGE (product)-[:LINKS]->(home)
MERGE (home)-[:LINKS]->(product)
MERGE (links)-[:LINKS]->(home)
MERGE (home)-[:LINKS]->(links)
MERGE (links)-[:LINKS]->(a)
MERGE (a)-[:LINKS]->(home)
MERGE (links)-[:LINKS]->(b)
MERGE (b)-[:LINKS]->(home)
MERGE (links)-[:LINKS]->(c)
MERGE (c)-[:LINKS]->(home)
MERGE (links)-[:LINKS]->(d)
MERGE (d)-[:LINKS]->(home)


CALL gds.graph.project(
  'myGraph',
  'Page',
  'LINKS'
)

CALL gds.pageRank.write.estimate(
    'myGraph',
    {
        writeProperty: "pageRank",
        maxIterations: 20,
        dampingFactor: 0.85
    }
)
YIELD nodeCount, relationshipCount, bytesMin, bytesMax, requiredMemory

MATCH (sizeA: Page {name: "Site A"})
CALL gds.pageRank.stream('myGraph')
YIELD nodeId, score
RETURN gds.util.asNode(nodeId).name, score
ORDER by score DESC

CALL gds.graph.project(
    'myGraphUndirected',
    'Page', 
    { LINKS: 
        { orientation: 'UNDIRECTED' } 
    }
)

CALL gds.randomWalk.stream(
    'myGraph',
    {
        walkLength: 3,
        walksPerNode: 1,
        randomSeed: 42,
        concurrency: 1
    }
)
YIELD nodeIds, path
RETURN nodeIds, [node in nodes(path) | node.name] AS pages
#每个节点都会返回一条游走记录，一共8条记录
#增加一个节点
MATCH (links:Page {name:"Links"}), (home:Page {name:"Home"})
MERGE (e:Page {name:"Site E"})
MERGE (links)-[:LINKS]->(e)
MERGE (e)-[:LINKS]->(home)
#再次执行游走，还是8条记录，Site E并没有出现在游走记录里，证明project不会实时生效
CALL gds.graph.drop('myGraph')
#删除再重新创建，再次指向相同游走，有9条记录了
MATCH (links:Page {name:"Links"}), (home:Page {name:"Home"})
MERGE (f:Page {name:"Site F"})
MERGE (links)-[:LINKS]->(f)
MERGE (f)-[:LINKS]->(home)
#在增加一个节点还是一样

MATCH (links:Page {name:"Links"})-[:LINKS]->(e:Page {name:"Site E"})
DETACH DELETE links


MATCH (page:Page)
WHERE page.name in ['Home', 'About']
WITH COLLECT(page) AS sourceNodes
CALL gds.randomWalk.stream(
    'myGraph',
    {
        sourceNodes: sourceNodes,
        walkLength: 3,
        walksPerNode: 1,
        randomSeed: 42,
        concurrency: 1
    }
)
YIELD nodeIds, path
RETURN nodeIds, [node in nodes(path) | node.name] AS pages

CALL gds.randomWalk.stats(
    'myGraph',
    {
        walkLength: 3,
        walksPerNode: 1,
        randomSeed: 42,
        concurrency: 1
    }
)

#CALL gds.graph.create.cypher(
CALL gds.graph.project.cypher(
    'myGraphCypher',
    'MATCH(n:Page) RETURN id(n) AS id,labels(n) AS labels', 
    'MATCH(u:Page)-[:LINKS]->(v:Page) RETURN id(u) AS source, id(v) AS target'
)
#project是native投影，cyper投影只选一部分数据
SHOW PROCEDURES YIELD name, description WHERE name STARTS WITH 'gds.'
#5.0函数名不一样了
#执行相同的随机游走算法，结果相同

CREATE (a:Location {name:'A'}),
       (b:Location {name: 'B'}),
       (c:Location {name: 'C'}),
       (d:Location {name: 'D'}),
       (e:Location {name: 'E'}),
       (f:Location {name: 'F'}),
       (a)-[:ROAD {cost: 50}]->(b),
       (a)-[:ROAD {cost: 50}]->(c),
       (a)-[:ROAD {cost: 100}]->(d),
       (b)-[:ROAD {cost: 40}]->(d),
       (c)-[:ROAD {cost: 40}]->(d),
       (c)-[:ROAD {cost: 80}]->(e),
       (d)-[:ROAD {cost: 30}]->(e),
       (d)-[:ROAD {cost: 80}]->(f),
       (e)-[:ROAD {cost: 40}]->(f);

CALL gds.graph.project(
    'myGraphLocation',
    'Location',
    'ROAD',
    {
        relationshipProperties: 'cost'
    }
)

MATCH (source:Location {name: 'A'}), (target:Location {name: 'F'})
CALL gds.shortestPath.dijkstra.write.estimate('myGraphLocation', {
    sourceNode: source,
    targetNode: target,
    relationshipWeightProperty: 'cost',
    writeRelationshipType: 'PATH'
})
YIELD nodeCount, relationshipCount, bytesMin, bytesMax, requiredMemory
RETURN nodeCount, relationshipCount, bytesMin, bytesMax, requiredMemory

MATCH (source:Location {name: 'A'}), (target:Location {name: 'F'})
CALL gds.shortestPath.dijkstra.stream('myGraphLocation', {
    sourceNode: source,
    targetNode: target,
    relationshipWeightProperty: 'cost'
})
YIELD index, sourceNode, targetNode, totalCost, nodeIds, costs, path
RETURN
    index,
    gds.util.asNode(sourceNode).name AS sourceNodeName,
    gds.util.asNode(targetNode).name AS targetNodeName,
    totalCost,
    [nodeId IN nodeIds | gds.util.asNode(nodeId).name] AS nodeNames,
    costs,
    nodes(path) as path
ORDER BY index

CREATE (alice:People {name:'Alice'})
CREATE (bob:People{name: 'Bob'})
CREATE (carol:People{name: 'Carol'})
CREATE (dave:People{name: 'Dave'})
CREATE (eve:People{name: 'Eve'})
CREATE (guitar:Instrument {name: 'Guitar'})
CREATE (synth:Instrument {name: 'Synthesizer'})
CREATE (bongos:Instrument {name: 'Bongos'})
CREATE (trumpet:Instrument {name: 'Trumpet'})
CREATE (alice)-[:LIKES]->[guitar]
CREATE (alice)-[:LIKES]->(synth)
CREATE (alice)-[:LIKES]->(bongos)
CREATE (bob)-[:LIKES]->(guitar)
CREATE (bob)-[:LIKES]->(synth)
CREATE (carol)-[:LIKES]->(bongos)
CREATE (dave)-[:LIKES]->(guitar)
CREATE (dave)-[:LIKES]->(synth)
CREATE (dave)-[:LIKES]->(bongos);

CALL gds.graph.project(
    'myGraphLike',
    ['People', 'Instrument'],
    'LIKES'
)

CALL gds.beta.node2vec.stream(
    'myGraph', 
    {embeddingDimension: 4}
)
YIELD nodeId, embedding
RETURN gds.util.asNode(nodeId).name, embedding
