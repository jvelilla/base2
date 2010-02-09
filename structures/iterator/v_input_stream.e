note
	description: "Streams that provide values one by one."
	author: "Nadia Polikarpova"
	date: "$Date$"
	revision: "$Revision$"
	model: sequence, index

deferred class
	V_INPUT_STREAM [G]

feature -- Access
	item: G
			-- Item at current position
		require
			not_off: not off
		deferred
		end

feature -- Status report
	off: BOOLEAN
			-- Is current position off scope?
		deferred
		end

feature -- Cursor movement
	forth
			-- Move one position forward
		require
			not_off: not off
		deferred
		ensure
			index_effect: index = old index + 1
		end

	search (v: G)
			-- Move to the first occurrence of `v' starting from current position
			-- If `v' does not occur, move `off'
		do
			from
			until
				off or else item = v
			loop
				forth
			end
		ensure
			index_effect_found: sequence.domain [index] implies (sequence [index] = v and not sequence.interval (old index, index - 1).has (v))
			sequence_effect: sequence |=| old sequence
		end

	search_that (pred: PREDICATE [ANY, TUPLE [G]])
			-- Move to the first position starting from current where `p' holds
			-- If `pred' never holds, move `off'
		do
			from
			until
				off or else pred.item ([item])
			loop
				forth
			end
		ensure
			index_effect_found: sequence.domain [index] implies
				(pred.item ([sequence [index]]) and not sequence.interval (old index, index - 1).range.exists (pred))
		end

feature -- Model
	sequence: MML_SEQUENCE [G]
			-- Sequence of elements
		note
			status: model
		deferred
		end

	index: INTEGER
			-- Current position
		note
			status: model
		deferred
		end

invariant
	item_definition: sequence.domain [index] implies item = sequence [index]
	off_definition: off = not sequence.domain [index]
end
