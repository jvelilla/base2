note
	description: "Cells that can be linked to two neighbour cells."
	author: "Nadia Polikarpova"
	date: "$Date$"
	revision: "$Revision$"
	model: item, left, right

class
	V_DOUBLY_LINKABLE [G]

inherit
	V_CELL [G]

create
	put

feature -- Access
	right: V_DOUBLY_LINKABLE [G]
			-- Next cell.

	left: V_DOUBLY_LINKABLE [G]
			-- Previous cell.

feature -- Replacement
	put_right (cell: V_DOUBLY_LINKABLE [G])
			-- Replace `right' with `cell'.
		do
			right := cell
		ensure
			right_effect: right = cell
		end

	put_left (cell: V_DOUBLY_LINKABLE [G])
			-- Replace `left' with `cell'.
		do
			left := cell
		ensure
			left_effect: left = cell
		end

	connect (cell: V_DOUBLY_LINKABLE [G])
			-- Establish two-way connection with `cell' on the right.
			-- Do not modify `right' and `cell.left'.
		require
			cell_exists: cell /= Void
		do
			put_right (cell)
			cell.put_left (Current)
		ensure
			right_effect: right = cell
			cell_left_effect: cell.left = Current
		end

end