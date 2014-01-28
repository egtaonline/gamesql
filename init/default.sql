DROP TABLE IF EXISTS symmetry_groups;
DROP TABLE IF EXISTS partial_profiles;
DROP TABLE IF EXISTS profiles;
DROP TABLE IF EXISTS strategies;
DROP TABLE IF EXISTS roles;
DROP TABLE IF EXISTS role_assignments;

CREATE TABLE roles (
    role_id serial PRIMARY KEY,
    name text
--  UNIQUE
    );

CREATE TABLE strategies (
    strategy_id serial PRIMARY KEY,
    role_id integer 
--  REFERENCES roles(role_id)
    , name text
--  UNIQUE
    );

CREATE TABLE role_assignments (
    role_assignment_id serial PRIMARY KEY,
    role_assignment text
--  UNIQUE
    );

CREATE TABLE profiles (
    profile_id serial PRIMARY KEY,
    role_assignment_id integer 
--  REFERENCES role_assignments(role_assignment_id)
    , num_strategies_in_profile integer
--  , CHECK (num_strategies_in_profile > 0)
    );

CREATE TABLE partial_profiles (
    partial_profile_id serial PRIMARY KEY,
    partial_profile text
--  UNIQUE
    );

CREATE TABLE symmetry_groups (
    profile_id integer 
--  REFERENCES profiles(profile_id)
    , role_id integer
--  REFERENCES roles(role_id)
    , strategy_id integer
--  REFERENCES strategies(strategy_id)
    , partial_profile_id integer
--  REFERENCES partial_profiles(partial_profile_id)
    , num_players integer,
    payoff float
--  , CHECK (num_players > 0),
--  CONSTRAINT group_uniqueness UNIQUE(profile_id, strategy_id)
    );