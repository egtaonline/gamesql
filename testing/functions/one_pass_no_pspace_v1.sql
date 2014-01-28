CREATE OR REPLACE FUNCTION find_psnes(r_assignment_id integer, strategy_ids integer []) RETURNS TABLE (pid int) AS $$
 SELECT profile_id
 FROM(
   SELECT profile_id, num_strategies_in_profile, rank() OVER (PARTITION BY partial_profile_id ORDER BY payoff DESC)
   FROM symmetry_groups
 WHERE rank = 1
 GROUP BY profile_id, num_strategies_in_profile
 HAVING COUNT(*) = num_strategies_in_profile;
$$ LANGUAGE SQL STABLE RETURNS NULL ON NULL INPUT;

CREATE OR REPLACE FUNCTION find_strict_psnes(r_assignment_id integer, strategy_ids integer []) RETURNS TABLE (pid int) AS $$
 SELECT profile_id
 FROM(
   SELECT profile_id, num_strategies_in_profile, rank() OVER (PARTITION BY partial_profile_id ORDER BY payoff DESC), 
     count(*) OVER (PARTITION BY partial_profile_id, payoff) as dup
   FROM symmetry_groups
 WHERE rank = 1
 AND dup = 1
 GROUP BY profile_id, num_strategies_in_profile
 HAVING COUNT(*) = num_strategies_in_profile;
$$ LANGUAGE SQL STABLE RETURNS NULL ON NULL INPUT;