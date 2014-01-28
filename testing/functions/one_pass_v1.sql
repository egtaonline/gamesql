CREATE OR REPLACE FUNCTION profile_space(r_assignment_id integer, strategy_ids integer []) RETURNS TABLE (profile_id int) AS $$
  SELECT profile_id 
  FROM symmetry_groups LEFT JOIN profiles USING (profile_id)
  WHERE strategy_id = ANY(strategy_ids)
  AND role_assignment_id = r_assignment_id
  GROUP BY profile_id, num_strategies_in_profile
  HAVING COUNT(*) = num_strategies_in_profile
$$ LANGUAGE SQL STABLE RETURNS NULL ON NULL INPUT;

CREATE OR REPLACE FUNCTION find_psnes(r_assignment_id integer, strategy_ids integer []) RETURNS TABLE (pid int) AS $$
 SELECT profile_id
 FROM(
   SELECT profile_id, num_strategies_in_profile, rank() OVER (PARTITION BY partial_profile_id ORDER BY payoff DESC)
   FROM symmetry_groups JOIN profile_space(r_assignment_id, strategy_ids) p USING (profile_id)) u
 WHERE rank = 1
 GROUP BY profile_id, num_strategies_in_profile
 HAVING COUNT(*) = num_strategies_in_profile;
$$ LANGUAGE SQL STABLE RETURNS NULL ON NULL INPUT;

CREATE OR REPLACE FUNCTION find_strict_psnes(r_assignment_id integer, strategy_ids integer []) RETURNS TABLE (pid int) AS $$
 SELECT profile_id
 FROM(
   SELECT profile_id, num_strategies_in_profile, rank() OVER (PARTITION BY partial_profile_id ORDER BY payoff DESC), 
     count(*) OVER (PARTITION BY partial_profile_id, payoff) as dup
   FROM symmetry_groups JOIN profile_space(r_assignment_id, strategy_ids) p USING (profile_id)) t
 WHERE rank = 1
 AND dup = 1
 GROUP BY profile_id, num_strategies_in_profile
 HAVING COUNT(*) = num_strategies_in_profile;
$$ LANGUAGE SQL STABLE RETURNS NULL ON NULL INPUT;