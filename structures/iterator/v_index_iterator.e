note
	description: "Iterators over indexable containers that access elements directly through an integer index."
	author: ""
	date: "$Date$"
	revision: "$Revision$"
	model: target, index

class
	V_INDEX_ITERATOR [G]

inherit
	V_ITERATOR [G]
		redefine
			go_to,
			copy
		end

create {V_CONTAINER}
	make

feature {NONE} -- Initialization
	make (t: V_INDEXABLE [G]; i: INTEGER)
			-- Create an iterator at position `i' in `t'
		require
			t_exists: t /= Void
			i_valid: 0 <= i and i <= t.count + 1
		do
			target := t
			index := i
		ensure
			target_effect: target = t
			index_effect: index = i
		end

feature -- Initialization
	copy (other: like Current)
			-- Initialize with the same `target' and `index' as in `other'
		do
			target := other.target
			index := other.index
		ensure then
			target_effect: target = other.target
			index_effect: index = other.index
			other_target_effect: other.target = old other.target
			other_index_effect: other.index = old other.index
		end

feature -- Access
	target: V_INDEXABLE [G]
			-- Target container

	item: G
			-- Item at current position
		do
			Result := target [target.lower + index - 1]
		end

feature -- Measurement
	index: INTEGER
			-- Index of current position


feature -- Status report
	before: BOOLEAN
			-- Is current position before any position in `target'?
		do
			Result := index = 0
		end

	after: BOOLEAN
			-- Is current position after any position in `target'?
		do
			Result := index = target.count + 1
		end

	is_first: BOOLEAN
			-- Is cursor at the first position?
		do
			Result := not target.is_empty and index = 1
		end

	is_last: BOOLEAN
			-- Is cursor at the last position?
		do
			Result := not target.is_empty and index = target.count
		end

feature -- Cursor movement
	start
			-- Go to the first position
		do
			index := 1
		end

	finish
			-- Go to the last position
		do
			index := target.count
		end

	forth
			-- Move one position forward
		do
			index := index + 1
		end

	back
			-- Go one position backwards
		do
			index := index - 1
		end

	go_to (i: INTEGER)
			-- Go to position `i'
		do
			index := i
		end

	go_before
			-- Go before any position of `target'
		do
			index := 0
		end

	go_after
			-- Go after any position of `target'
		do
			index := target.count + 1
		end

feature -- Replacement
	put (v: G)
			-- Replace item at current position with `v'
		do
			target.put (target.lower + index - 1, v)
		end

feature -- Specification
	sequence: MML_FINITE_SEQUENCE [G]
			-- Sequence of elements
		note
			status: specification
		local
			i: INTEGER
		do
			create Result.empty
			from
				i := target.lower
			until
				i > target.upper
			loop
				Result := Result.extended (target [i])
				i := i + 1
			end
		end

invariant
	sequence_domain_definition: sequence.count = target.map.count
	sequence_definition: sequence.domain.for_all (agent (i: INTEGER): BOOLEAN
		do
			Result := sequence [i] = target.map [target.map.domain.lower + i - 1]
		end)
end
