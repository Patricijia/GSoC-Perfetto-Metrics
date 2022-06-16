DROP VIEW IF EXISTS interaction_durations_id;
CREATE VIEW interaction_durations_id AS
SELECT slice.* , args.int_value as "interaction_id" FROM slice
INNER JOIN args
ON slice.arg_set_id = args.arg_set_id
WHERE
  slice.name = "EventTiming" AND
  args.key = "debug.data.interactionId" AND
  args.int_value > 0;

DROP VIEW IF EXISTS interaction_durations_type;
CREATE VIEW interaction_durations_type AS
SELECT slice.*, args.string_value as "interaction_type" FROM slice
INNER JOIN args
ON slice.arg_set_id = args.arg_set_id
WHERE
  slice.name = "EventTiming" AND 
  args.key = "debug.data.type" AND
  args.string_value IS NOT NULL;

DROP VIEW IF EXISTS interactions;
CREATE VIEW interactions AS
SELECT interaction_durations_id.id, interaction_durations_id.track_id,interaction_durations_id.ts, interaction_durations_id.dur, interaction_durations_id.interaction_id, interaction_durations_type.interaction_type FROM interaction_durations_id
INNER JOIN interaction_durations_type
ON interaction_durations_id.id = interaction_durations_type.id;

DROP VIEW IF EXISTS interactions_with_upid;
CREATE VIEW interactions_with_upid AS
SELECT
  interactions.*, process_track.upid
FROM interactions
INNER JOIN process_track
ON interactions.track_id = process_track.id;

DROP VIEW IF EXISTS interactions_with_process_info;
CREATE VIEW interactions_with_process_info AS
SELECT
  interactions_with_upid.*, process.arg_set_id as "arg_set_id_process",
  REPLACE(
    process.name,
    RTRIM(
      process.name,
      REPLACE(process.name, '/', '')
    ),
    '') AS process_name,
  process.pid AS process_id
FROM interactions_with_upid
INNER JOIN process
ON interactions_with_upid.upid = process.upid;

SELECT * FROM interactions_with_process_info;