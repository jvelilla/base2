note
	description: "[
		Indexable containers with arbitrary bounds, whose elements are stored in a continuous memory area.
		Random access is constant time, but resizing requires memory reallocation and copying elements, and takes linear time.
		The logical size of array is the same as the physical size of the underlying memory area.
		]"
	author: "Nadia Polikarpova"
	date: "$Date$"
	revision: "$Revision$"
	model: map

class
	V_ARRAY [G]

inherit
	V_SEQUENCE [G]
		redefine
			copy,
			is_equal,
			fill,
			clear,
			subcopy
		end

create
	make,
	make_filled

feature {NONE} -- Initialization
	make (l, u: INTEGER)
			-- Create array with indexes in [`l', `u']; set all values to default.
		require
			valid_indexes: l <= u + 1
		do
			if l <= u then
				lower := l
				upper := u
			else
				lower := 1
				upper := 0
			end
			create area.make (u - l + 1)
		ensure
			map_domain_effect: map.domain |=| {MML_INTEGER_SET}[[l, u]]
			map_effect: map.is_constant (default_item)
		end

	make_filled (l, u: INTEGER; v: G)
			-- Create array with indexes in [`l', `u']; set all values to `v'.
		require
			valid_indexes: l <= u + 1
		do
			if l <= u then
				lower := l
				upper := u
			else
				lower := 1
				upper := 0
			end
			create area.make_filled (v, u - l + 1)
		ensure
			map_domain_effect: map.domain |=| {MML_INTEGER_SET}[[l, u]]
			map_effect: map.is_constant (v)
		end

feature -- Initialization
	copy (other: like Current)
			-- Initialize by copying all the items of `other'.
			-- Reallocate memory unless count stays the same.
		do
			if other /= Current then
				if area /= Void and other.count = count then
					lower := other.lower
					upper := other.upper
				else
					make (other.lower, other.upper)
				end
				area.copy_data (other.area, 0, 0, count)
			end
		ensure then
			map_effect: map |=| other.map
			other_map_effect: other.map |=| old other.map
		end

feature -- Access
	item alias "[]" (i: INTEGER): G assign put
			-- Value associated with `i'.
		do
			Result := area [i - lower]
		end

	subarray (l, u: INTEGER): V_ARRAY [G]
			-- Array consisting of elements of Current in index range [`l', `u'].
		require
			l_not_too_small: l >= lower
			u_not_too_large: u <= upper
			l_not_too_large: l <= u + 1
		do
			create Result.make (l, u)
			Result.subcopy (Current, l, u, Result.lower)
		ensure
			map_domain_definition: Result.map.domain |=| {MML_INTEGER_SET}[[l, u]]
			map_definition: Result.map.domain.for_all (agent (i: INTEGER; r: V_ARRAY [G]): BOOLEAN
				do
					Result := r.map [i] = map [i]
				end (?, Result))
		end

feature -- Measurement
	lower: INTEGER
			-- Lower bound of index interval.

	upper: INTEGER
			-- Upper bound of index interval.		

feature -- Iteration
	at (i: INTEGER): V_SEQUENCE_ITERATOR [G]
			-- New iterator pointing at position `i'.
		do
			create Result.make (Current, i - lower + 1)
		end

feature -- Comparison
	is_equal (other: like Current): BOOLEAN
			-- Is array made of the same items as `other'?
			-- (Use reference comparison.)
		do
			if other = Current then
				Result := True
			else
				Result := (lower = other.lower and upper = other.upper) and then
					area.same_items (other.area, 0, 0, count)
			end
		ensure then
			definition: Result = (map |=| other.map)
		end

feature -- Replacement
	put (v: G; i: INTEGER)
			-- Put `v' at position `i'.
		do
			area.put (v, i - lower)
		end

	fill (v: G; l, u: INTEGER)
			-- Put `v' at positions [`l', `u'].
		do
			area.fill_with (v, l - lower, u - lower)
		end

	clear (l, u: INTEGER)
			-- Put default value at positions [`l', `u'].		
		do
			area.fill_with_default (l - lower, u - lower)
		end

	subcopy (other: V_SEQUENCE [G]; other_first, other_last, index: INTEGER)
			-- Copy items of `other' within bounds [`other_first', `other_last'] to current array starting at index `i'.
		do
			if attached {V_ARRAY [G]} other as a then
				area.copy_data (a.area, other_first - other.lower, index - lower, other_last - other_first + 1)
			else
				Precursor (other, other_first, other_last, index)
			end
		end

feature -- Resizing
	resize (l, u: INTEGER)
			-- Set index interval to [`l', `u']; keep values at old indexes; set to default at new indexes.
			-- Reallocate memory unless count stays the same.
		require
			valid_indexes: l <= u + 1
		local
			new_count, x, y: INTEGER
		do
			new_count := u - l + 1
			if new_count = 0 then
				create area.make (0)
				lower := 1
				upper := 0
			else
				if new_count > area.count then
					area := area.aliased_resized_area (new_count)
				end
				x := lower.max (l)
				y := upper.min (u)
				if x > y then
					-- No intersection
					area.fill_with_default (0, area.count - 1)
				else
					-- Intersection
					area.move_data (x - lower, x - l, y - x + 1)
					area.fill_with_default (0, x - l - 1)
					area.fill_with_default (y - l + 1, area.count - 1)
				end
				if new_count < area.count then
					area := area.resized_area (new_count)
				end
				lower := l
				upper := u
			end
		ensure
			map_domain_effect: map.domain |=| {MML_INTEGER_SET} [[l, u]]
			map_old_effect: (map | (map.domain * old map.domain)) |=| (old map | (map.domain * old map.domain))
			map_new_effect: (map | (map.domain - old map.domain)).is_constant (default_item)
		end

	include (i: INTEGER)
			-- Resize in a minimal way to include index `i'; keep values at old indexes; set to default at new indexes.
			-- Reallocate memory unless count stays the same.
		do
			if is_empty then
				resize (i, i)
			elseif i < lower then
				resize (i, upper)
			elseif i > upper then
				resize (lower, i)
			end
		ensure
			map_domain_effect: map.domain |=| {MML_INTEGER_SET} [[i.min (old map.domain.lower), i.max (old map.domain.upper)]]
			map_old_effect: (map | (map.domain * old map.domain)) |=| (old map | (map.domain * old map.domain))
			map_new_effect: (map | (map.domain - old map.domain)).is_constant (default_item)
		end

	force (v: G; i: INTEGER)
			-- Put `v' at position `i'; if position is not defined, include it.
			-- Reallocate memory unless count stays the same.
		do
			include (i)
			put (v, i)
		ensure
			map_domain_effect: map.domain |=| {MML_INTEGER_SET} [[i.min (old map.domain.lower), i.max (old map.domain.upper)]]
			map_i_effect: map [i] = v
			map_old_effect: (map | (map.domain * old map.domain - {MML_INTEGER_SET}[i])) |=| (old map | (map.domain * old map.domain - {MML_INTEGER_SET}[i]))
			map_new_effect: (map | (map.domain - old map.domain - {MML_INTEGER_SET}[i])).is_constant (default_item)
		end

	wipe_out
			-- Remove all elements.
		do
			resize (1, 0)
		end

feature {V_ARRAY} -- Implementation
	area: SPECIAL [G]
			-- Memory area where elements are stored.

invariant
	area_exists: area /= Void
end
