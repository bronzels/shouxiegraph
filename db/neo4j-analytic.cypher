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
