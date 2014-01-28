CREATE OR REPLACE FUNCTION store_role_assignment (new_role_ids integer[], new_role_counts integer[]) RETURNS integer AS $$
  WITH existing AS (SELECT role_assignment_id
    FROM role_assignments
    WHERE role_ids = new_role_ids
    AND role_counts = new_role_counts),
  inserting AS (INSERT INTO role_assignments (role_ids, role_counts) 
    SELECT new_role_ids, new_role_counts
    WHERE NOT EXISTS(
      SELECT role_ids, role_counts
      FROM role_assignments
      WHERE role_ids = new_role_ids
      AND role_counts = new_role_counts
    ) RETURNING role_assignment_id)
  SELECT role_assignment_id
  FROM existing
  UNION ALL
  SELECT role_assignment_id
  FROM inserting;
$$ LANGUAGE SQL;

CREATE OR REPLACE FUNCTION store_partial_profile(new_partial_profile hstore) RETURNS integer AS $$
  WITH existing AS (SELECT partial_profile_id
    FROM partial_profiles
    WHERE partial_profile = new_partial_profile),
  inserting AS (INSERT INTO partial_profiles (partial_profile) 
    SELECT new_partial_profile
    WHERE NOT EXISTS(
      SELECT partial_profile
      FROM partial_profiles
      WHERE partial_profile = new_partial_profile
    ) RETURNING partial_profile_id)
  SELECT partial_profile_id
  FROM existing
  UNION ALL
  SELECT partial_profile_id
  FROM inserting;
$$ LANGUAGE SQL;

CREATE OR REPLACE FUNCTION build_assignments (role_ids integer[], role_counts integer[], strategy_ids integer[]) RETURNS TABLE (role_assignment_id integer, assignment hstore) AS $$
  WITH RECURSIVE role_table AS (SELECT unnest(role_ids) AS role_id, unnest(role_counts) AS count),
  combinations AS (
    WITH RECURSIVE append(role_id, sids, k, j) AS (
      SELECT strategies.role_id, ARRAY[strategy_id], count, 1
      FROM strategies, role_table 
      WHERE strategy_id = ANY (strategy_ids)
      AND role_table.role_id = strategies.role_id
    UNION ALL
      SELECT strategies.role_id, t.sids || strategies.strategy_id, k - 1, j + 1
      FROM strategies, append t
      WHERE strategies.role_id = t.role_id
      AND strategies.strategy_id >= t.sids[j]
      AND  k > 1)
    SELECT role_id, sids, k
    FROM append 
    WHERE k = 1),
  product(assignment, rids) AS (
    SELECT hstore(to_char(role_id, '9999'), array_to_string(sids, ',')) as assignment, array_remove(role_ids, role_ids[1]) as rids
    FROM combinations
    WHERE role_id = role_ids[1]
  UNION ALL
    SELECT t.assignment || hstore(to_char(role_id, '9999'), array_to_string(combinations.sids, ',')) as assignment, array_remove(rids, rids[1]) as rids
    FROM product t CROSS JOIN combinations
    WHERE combinations.role_id = rids[1]
    AND array_upper(rids, 1) > 0)
  SELECT store_role_assignment(role_ids, role_counts), assignment 
  FROM product 
  WHERE rids = '{}';
$$ LANGUAGE SQL;

CREATE OR REPLACE FUNCTION build_symmetry_groups(profile_id integer, assignment hstore) RETURNS VOID AS $$
  WITH sgroups AS(
    SELECT key AS role_id, unnest(string_to_array(value, ',')) AS strategy_id, COUNT(*), COUNT(*) OVER () as num_strategies_in_profile 
    FROM (SELECT (each(assignment)).key, (each(assignment)).value) t
    GROUP BY role_id, strategy_id)
  INSERT INTO symmetry_groups (profile_id, role_id, strategy_id, num_players, num_strategies_in_profile, partial_profile_id, payoff)
    SELECT profile_id, CAST(sgroups.role_id AS int), CAST(sgroups.strategy_id AS int), CAST(count AS int), CAST(num_strategies_in_profile AS int), 
         store_partial_profile((assignment || hstore(role_id, array_to_string(sort(CAST((array_remove(string_to_array(assignment->role_id, ','), strategy_id) ||
         array_fill(strategy_id, ARRAY[CAST(count AS int)-1])) AS integer[])), ',')))), random()
    FROM sgroups;
$$ LANGUAGE SQL;

CREATE OR REPLACE FUNCTION build_profiles(role_ids integer[], role_counts integer[], strategy_ids integer[]) RETURNS VOID AS $$
  WITH assignments AS (SELECT *, row_number() OVER () FROM build_assignments(role_ids, role_counts, strategy_ids)),
  profile_ids AS (INSERT INTO profiles (role_assignment_id) SELECT role_assignment_id FROM assignments RETURNING profile_id),
  pids AS (SELECT profile_id, row_number() OVER () FROM profile_ids)
  SELECT build_symmetry_groups(profile_id, assignment)
  FROM pids JOIN assignments USING (row_number);
$$ LANGUAGE SQL;