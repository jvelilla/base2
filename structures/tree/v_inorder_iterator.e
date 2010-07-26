note
	description: "Iterators to traverse binary trees in order left subtree - root - right subtree."
	author: "Nadia Polikarpova"
	date: "$Date$"
	revision: "$Revision$"
	model: target, path, after

class
	V_INORDER_ITERATOR [G]

inherit
	V_ITERATOR [G]
		undefine
			off
		redefine
			copy
		end

	V_BINARY_TREE_CURSOR [G]
		undefine
			is_equal
		redefine
			copy,
			go_root
		end

create {V_CONTAINER}
	make

feature -- Initialization
	copy (other: like Current)
			-- Initialize with the same `target' and position as in `other'.
		do
			after := other.after
			Precursor {V_BINARY_TREE_CURSOR} (other)
		ensure then
			sequence_effect: sequence |=| other.sequence
			path_effect: path |=| other.path
			after_effect: after = other.after
			other_sequence_effect: other.sequence |=| old other.sequence
			other_path_effect: other.path |=| old other.path
			other_after_effect: other.after = old other.after
		end

feature -- Measurement
	index: INTEGER
			-- Index of current position.
		local
			old_active: V_BINARY_TREE_CELL [G]
			old_after: BOOLEAN
		do
			if after then
				Result := target.count + 1
			elseif not off then
				old_active := active
				old_after := after
				from
					start
					Result := 1
				until
					active = old_active
				loop
					forth
					Result := Result + 1
				end
				active := old_active
				after := old_after
			end
		end

feature -- Status report		
	is_first: BOOLEAN
			-- Is cursor at the first position?
		local
			old_active: V_BINARY_TREE_CELL [G]
			old_after: BOOLEAN
		do
			if not off then
				old_active := active
				old_after := after
				start
				Result := active = old_active
				active := old_active
				after := old_after
			end
		end

	is_last: BOOLEAN
			-- Is cursor at the last position?
		local
			old_active: V_BINARY_TREE_CELL [G]
			old_after: BOOLEAN
		do
			if not off then
				old_active := active
				old_after := after
				finish
				Result := active = old_active
				active := old_active
				after := old_after
			end
		end

	after: BOOLEAN
			-- Is current position after the last container position?

	before: BOOLEAN
			-- Is current position before the first container position?
		do
			Result := off and not after
		end

feature -- Cursor movement
	go_root is
			-- Move cursor to the root.
		do
			Precursor
			if not target.is_empty then
				after := False
			else
				after := True
			end
		ensure then
			after_effect_nonempty: not target.map.is_empty implies not after
			after_effect_empty: target.map.is_empty implies after
		end

	start is
			-- Move cursor to the leftmost node.
		do
			if not target.is_empty then
				from
					go_root
				until
					active.left = Void
				loop
					left
				end
				after := False
			else
				after := True
			end
		end

	finish
			-- Move cursor to the rightmost node.
		do
			if not target.is_empty then
				from
					go_root
				until
					active.right = Void
				loop
					right
				end
			end
			after := False
		end

	forth
			-- Move cursor to the next element in inorder.
		do
			if active.right /= Void then
				right
				from
				until
					active.left = Void
				loop
					left
				end
			else
				from
				until
					active.is_root or active.is_left
				loop
					up
				end
				up
			end
			if active = Void then
				after := True
			end
		end

	back
			-- Move cursor to the previous element in inorder.
		do
			if active.left /= Void then
				left
				from
				until
					active.right = Void
				loop
					right
				end
			else
				from
				until
					active.is_root or active.is_right
				loop
					up
				end
				up
			end
		end

	go_before
			-- Move cursor before any position of `target'.
		do
			active := Void
			after := False
		end

	go_after
			-- Move cursor after any position of `target'.
		do
			active := Void
			after := True
		end

feature -- Specification
	sequence: MML_FINITE_SEQUENCE [G]
			-- Sequence of elements.
		note
			status: specification
		local
			old_active: V_BINARY_TREE_CELL [G]
			old_after: BOOLEAN
		do
			old_active := active
			old_after := after
			create Result.empty
			from
				start
			until
				off
			loop
				Result := Result.extended (item)
				forth
			end
			active := old_active
			after := old_after
		end

	subtree_sequence (root: MML_BIT_VECTOR): MML_FINITE_SEQUENCE [G]
			-- Inorder sequence of values in a subtree of `target.map' starting from `root'.
		note
			status: specification
		require
			root_exists: root /= Void
		do
			if not target.map.domain [root] then
				create Result.empty
			else
				Result := subtree_sequence (root.extended (False)).extended (target.map [root]) + subtree_sequence (root.extended (True))
			end
		ensure
			definition_base: not target.map.domain [root] implies Result.is_empty
			definition_step: target.map.domain [root] implies
				Result |=| (subtree_sequence (root.extended (False)).extended (target.map [root]) + subtree_sequence (root.extended (True)))
		end

	predecessor (node: MML_BIT_VECTOR): MML_BIT_VECTOR
			-- Predecessor of `node' in inorder in `target.map'.
		note
			status: specification
		require
			node_exists: node /= Void
			node_in_tree: target.map.domain [node]
		do
			if not target.map.domain [node.extended (False)] then
				if node [node.count] then
					Result := node.but_last
				else
					Result := node.front (node.last_index_of (True) - 1)
				end
			else
				from
					Result := node.extended (False)
				until
					not target.map.domain [Result]
				loop
					Result := Result.extended (True)
				end
				Result := Result.but_last
			end
		ensure
			definition_has_left: target.map.domain [node.extended (False)] implies
				node.extended (False).is_prefix_of (Result) and
				not target.map.domain [Result.extended (True)] and
				Result.tail (node.count + 2).is_constant (True)
			definition_not_has_left_is_right: not target.map.domain [node.extended (False)] and node [node.count] implies
				Result |=| node.but_last
			definition_not_has_left_is_left: not target.map.domain [node.extended (False)] and not node [node.count] implies
				Result |=| node.front (node.last_index_of (True) - 1)
		end

	node_index (node: MML_BIT_VECTOR): INTEGER
			-- Index of `node' in inorder in `target.map'.
		note
			status: specification
		require
			node_exists: node /= Void
		do
			if target.map.domain [node] then
				 Result := node_index (predecessor (node)) + 1
			end
		ensure
			definition_base: not target.map.domain [node] implies Result = 0
			definition_step: target.map.domain [node] implies Result = node_index (predecessor (node)) + 1
		end

invariant
	sequence_definition: sequence |=| subtree_sequence ({MML_BIT_VECTOR} [1])
	index_definition_not_after: not after implies index = node_index (path)
	index_definition_after: after implies index = target.map.count + 1
end