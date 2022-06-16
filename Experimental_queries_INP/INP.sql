DROP VIEW IF EXISTS interaction_durations;
CREATE VIEW interaction_durations AS
SELECT slice.slice_id, slice.ts, slice.dur, slice.track_id, slice.name, slice.arg_set_id, args.int_value as "interaction_id" FROM slice
INNER JOIN args
ON slice.arg_set_id = args.arg_set_id
WHERE
  slice.name = "EventTiming" AND
  args.key = "debug.data.interactionId" AND
  args.int_value > 0;


DROP VIEW IF EXISTS interaction_durations_with_upid;
CREATE VIEW interaction_durations_with_upid AS
SELECT
  interaction_durations.*, process_track.upid
FROM interaction_durations
INNER JOIN process_track
ON interaction_durations.track_id = process_track.id;

DROP VIEW IF EXISTS interaction_durations_with_process_info;
CREATE VIEW interaction_durations_with_process_info AS
SELECT
  interaction_durations_with_upid.*, process.arg_set_id as "arg_set_id_process",
  REPLACE(
    process.name,
    RTRIM(
      process.name,
      REPLACE(process.name, '/', '')
    ),
    '') AS process_name,
  process.pid AS process_id
FROM interaction_durations_with_upid
INNER JOIN process
ON interaction_durations_with_upid.upid = process.upid;

SELECT * FROM interaction_durations_with_process_info;