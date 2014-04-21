
{-# LANGUAGE BangPatterns, TemplateHaskell, NoMonomorphismRestriction #-}
module Graphene.Graph(
  Graph(..),
  emptyGraph,
  insertVertex,
  removeVertex,
  removeEdge,
  insertEdge,
  insertVertices,
  insertEdges,
  connections,
  neighbors,
  adjacentVertices,
  fromLists,
  degree
) where

import Data.Hashable
import Data.List
import Data.Function
import Control.Lens

data Graph e v = Graph
  { _vertices :: [v]
  , _edges    :: [(e, (v, v))]
  } deriving (Show, Eq)

makeLenses ''Graph

emptyGraph :: Graph e v
emptyGraph = Graph [] []

insertVertex :: v -> Graph e v -> Graph e v
insertVertex !v (Graph vs es) = Graph (v:vs) es

removeVertex :: Eq v => v -> Graph e v -> Graph e v
removeVertex v g = vertices %~ (delete v) 
  $ edges %~ (filter (\(_, (v1, v2)) -> not $ any (==v) [v1, v2])) $ g

removeEdge :: Eq e => e -> Graph e v -> Graph e v
removeEdge e = edges %~ (deleteBy ((==) `on` fst) (e, undefined))

insertEdge :: e -> (v, v) -> Graph e v -> Graph e v 
insertEdge !e !(v, v') (Graph vs es) = 
  foldr insertVertex (Graph vs ((e, (v, v')):es)) [v, v']
  
insertVertices :: (Eq b) => [b] -> Graph e b -> Graph e b
insertVertices vs g = foldl' (flip insertVertex) g vs

insertEdges :: [(e, v, v)] -> Graph e v -> Graph e v
insertEdges es g = foldl' (\g (e, v1, v2) -> insertEdge e (v1, v2) g) g es 

connections :: (Eq v) => v -> Graph e v -> [(e, (v, v))]
connections !v (Graph _ es) = 
  filter (\(_, (v1, v2)) -> any (==v) [v1, v2]) es

neighbors :: Eq v => v -> Graph e v -> [v]
neighbors !v (Graph _ es) = 
  foldl'
  (\acc (e, (v1, v2)) -> if v == v2 then (v1:acc) else if v == v1 then (v2:acc) else acc)
  []
  es

adjacentVertices :: (Eq e) => e -> Graph e v -> Maybe (v, v)
adjacentVertices !e (Graph _ es) = lookup e es

fromLists :: (Eq v) => [v] -> [(e, v, v)] -> Graph e v
fromLists vs es = insertEdges es $ insertVertices vs emptyGraph

degree :: Eq v => v -> Graph e v -> Int
degree v = length . connections v