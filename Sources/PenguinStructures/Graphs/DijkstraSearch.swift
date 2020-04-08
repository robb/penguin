// Copyright 2020 Penguin Authors
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

/// Represents a distance measure on a graph.
public protocol GraphDistanceMeasure: AdditiveArithmetic, Comparable {
	/// A value that is effectively always higher than any reasonable possible distance within the
	/// graph.
	static var effectiveInfinity: Self { get }
}

extension Int: GraphDistanceMeasure {
	public static var effectiveInfinity: Self { Self.max }
}

extension Int32: GraphDistanceMeasure {
	public static var effectiveInfinity: Self { Self.max }
}

extension Float: GraphDistanceMeasure {
	public static var effectiveInfinity: Self { Self.infinity }
}

extension Double: GraphDistanceMeasure {
	public static var effectiveInfinity: Self { Self.infinity }
}

/// Implements the majority of Dijkstra's algorithm in terms of BreadthFirstSearch.
private struct DijkstraBFSVisitor<
	Graph: IncidenceGraph & VertexListGraph,
	Distance: GraphDistanceMeasure,
	EdgeWeightMap: GraphEdgePropertyMap,
	VertexDistanceMap: MutableGraphVertexPropertyMap,
	Visitor: DijkstraVisitor
>: BFSVisitor
where
	Graph.VertexId: IdIndexable,
	EdgeWeightMap.Graph == Graph,
	EdgeWeightMap.Value == Distance,
	VertexDistanceMap.Graph == Graph,
	VertexDistanceMap.Value == Distance,
	Visitor.Graph == Graph
{
	/// The queue of verticies to visit.
	var queue = ConfigurableHeap<
		Graph.VertexId,
		Distance,
		Int32,  // TODO: make configurable!
		_IdIndexibleDictionaryHeapIndexer<Graph.VertexId, _ConfigurableHeapCursor<Int32>>>()
	/// The weights of the edges.
	let edgeWeightMap: EdgeWeightMap
	/// The distances from the start vertex to the final verticies.
	var vertexDistanceMap: VertexDistanceMap
	/// The visitor to be called throughout execution.
	var visitor: Visitor

	init(visitor: Visitor, edgeWeightMap: EdgeWeightMap, vertexDistanceMap: VertexDistanceMap, startVertex: Graph.VertexId) {
		self.visitor = visitor
		self.edgeWeightMap = edgeWeightMap
		self.vertexDistanceMap = vertexDistanceMap
	}

	public mutating func popVertex() -> Graph.VertexId? {
		let tmp = queue.popFront()
		return tmp
	}

	public mutating func discover(vertex: Graph.VertexId, _ graph: inout Graph) throws {
		queue.add(vertex, with: Distance.effectiveInfinity)  // Add to the back of the queue.
		try visitor.discover(vertex: vertex, &graph)
	}

	public mutating func examine(vertex: Graph.VertexId, _ graph: inout Graph) throws {
		try visitor.examine(vertex: vertex, &graph)
	}

	public mutating func examine(edge: Graph.EdgeId, _ graph: inout Graph) throws {
		try visitor.examine(edge: edge, &graph)
	}

	public mutating func treeEdge(_ edge: Graph.EdgeId, _ graph: inout Graph) throws {
		let decreased = relaxTarget(edge, &graph)
		if decreased {
			try visitor.edgeRelaxed(edge, &graph)
		} else {
			try visitor.edgeNotRelaxed(edge, &graph)
		}
	}

	public mutating func grayDestination(_ edge: Graph.EdgeId, _ graph: inout Graph) throws {
		let decreased = relaxTarget(edge, &graph)
		if decreased {
			try visitor.edgeRelaxed(edge, &graph)
		} else {
			try visitor.edgeNotRelaxed(edge, &graph)
		}
	}

	public mutating func blackDestination(_ edge: Graph.EdgeId, _ graph: inout Graph) throws {
		try visitor.edgeNotRelaxed(edge, &graph)
	}

	public mutating func finish(vertex: Graph.VertexId, _ graph: inout Graph) throws {
		try visitor.finish(vertex: vertex, &graph)
	}

	/// Returns `true` if `edge` relaxes the distance to `graph.target(of: edge)`, false otherwise.
	private mutating func relaxTarget(_ edge: Graph.EdgeId, _ graph: inout Graph) -> Bool {
		let destination = graph.destination(of: edge)
		let sourceDistance = vertexDistanceMap.get(graph, graph.source(of: edge))
		let destinationDistance = vertexDistanceMap.get(graph, destination)
		let edgeDistance = edgeWeightMap.get(graph, edge)
		let pathDistance = sourceDistance + edgeDistance

		if pathDistance < destinationDistance {
			vertexDistanceMap.set(vertex: destination, in: &graph, to: pathDistance)
			queue.update(destination, withNewPriority: pathDistance)
			return true
		} else {
			return false
		}
	}
}

public extension Graphs {
	/// Executes Dijkstra's graph search algorithm, without initializing any data structures.
	///
	/// This function is designed to be used as a zero-overhead abstraction to be called from other
	/// graph algorithms. Use this overload if you are interested in manually controlling every
	/// aspect. If you would like a higher-level abstraction, consider `dijkstraSearch`.
	static func dijkstraSearchNoInit<
		Graph: IncidenceGraph & VertexListGraph,
		Distance: GraphDistanceMeasure,
		EdgeWeightMap: GraphEdgePropertyMap,
		VertexDistanceMap: MutableGraphVertexPropertyMap,
		ColorMap: MutableGraphVertexPropertyMap,
		Visitor: DijkstraVisitor
	>(
		_ graph: inout Graph,
		visitor: inout Visitor,
		colorMap: inout ColorMap,
		vertexDistanceMap: inout VertexDistanceMap,
		edgeWeightMap: EdgeWeightMap,
		startAt startVertex: Graph.VertexId
	) throws
	where
		Graph.VertexId: IdIndexable,
		EdgeWeightMap.Graph == Graph,
		EdgeWeightMap.Value == Distance,
		VertexDistanceMap.Graph == Graph,
		VertexDistanceMap.Value == Distance,
		ColorMap.Graph == Graph,
		ColorMap.Value == VertexColor,
		Visitor.Graph == Graph
	{
		vertexDistanceMap.set(vertex: startVertex, in: &graph, to: Distance.zero)
		var dijkstraVisitor = DijkstraBFSVisitor(
			visitor: visitor,
			edgeWeightMap: edgeWeightMap,
			vertexDistanceMap: vertexDistanceMap,
			startVertex: startVertex)
		try breadthFirstSearchNoInit(
			&graph,
			visitor: &dijkstraVisitor,
			colorMap: &colorMap,
			startAt: [startVertex]
		)
		visitor = dijkstraVisitor.visitor
		vertexDistanceMap = dijkstraVisitor.vertexDistanceMap
	}

	/// Executes Dijkstra's search algorithm over `graph` from `startVertex` using edge weights from
	/// `edgeWeightMap`, calling `visitor` along the way.
	static func dijkstraSearch<
		Graph: IncidenceGraph & VertexListGraph,
		Distance: GraphDistanceMeasure,
		EdgeWeightMap: GraphEdgePropertyMap,
		Visitor: DijkstraVisitor
	>(
		_ graph: inout Graph,
		visitor: inout Visitor,
		edgeWeightMap: EdgeWeightMap,
		startAt startVertex: Graph.VertexId
	) throws -> TableVertexPropertyMap<Graph, Distance>
	where
		Graph.VertexId: IdIndexable,
		EdgeWeightMap.Graph == Graph,
		EdgeWeightMap.Value == Distance,
		Visitor.Graph == Graph
	{
		var colorMap = TableVertexPropertyMap(repeating: VertexColor.white, for: graph)
		var vertexDistanceMap = TableVertexPropertyMap(
			repeating: Distance.effectiveInfinity,
			for: graph)

		try dijkstraSearchNoInit(
			&graph,
			visitor: &visitor,
			colorMap: &colorMap,
			vertexDistanceMap: &vertexDistanceMap,
			edgeWeightMap: edgeWeightMap,
			startAt: startVertex)

		return vertexDistanceMap
	}
}