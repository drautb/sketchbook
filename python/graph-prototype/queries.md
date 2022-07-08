Neo4J Queries
=============

Load nodes into graph:

```cypher
load csv with headers from 'file:///2x2-ids.csv' as row 
merge (b:Board {state: row.state}) 
return count(b)
```
