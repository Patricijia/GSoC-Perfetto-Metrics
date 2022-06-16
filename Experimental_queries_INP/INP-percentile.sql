-- Find interactions that have id

DROP VIEW IF EXISTS event_timings_id;
CREATE VIEW event_timings_id AS
SELECT slice.* , args.int_value as "interaction_id" FROM slice
INNER JOIN args
ON slice.arg_set_id = args.arg_set_id
WHERE
  slice.name = "EventTiming" AND
  args.key = "debug.data.interactionId" AND
  args.int_value > 0;

-- Find all types of interactions

DROP VIEW IF EXISTS event_timings_type;
CREATE VIEW event_timings_type AS
SELECT slice.*, args.string_value as "interaction_type" FROM slice
INNER JOIN args
ON slice.arg_set_id = args.arg_set_id
WHERE
  slice.name = "EventTiming" AND 
  args.key = "debug.data.type" AND
  args.string_value IS NOT NULL;

-- Find interactions that have id and type 
-- Taking the interaction id with the longest duration: "MAX(event_timings_id.dur)"

DROP VIEW IF EXISTS event_timings;
CREATE VIEW event_timings AS
SELECT event_timings_id.id, event_timings_id.track_id,event_timings_id.ts, MAX(event_timings_id.dur) as dur, event_timings_id.interaction_id, event_timings_type.interaction_type FROM event_timings_id
INNER JOIN event_timings_type
ON event_timings_id.id = event_timings_type.id
GROUP BY interaction_id;

-- Find specific process id for each interaction (upid)

DROP VIEW IF EXISTS event_timings_with_upid;
CREATE VIEW event_timings_with_upid AS
SELECT
  event_timings.*, process_track.upid
FROM event_timings
INNER JOIN process_track
ON event_timings.track_id = process_track.id;

-- Find the name and pid of the processes. (eg. Renderer: 8556)
-- If the process name represents a file's pathname, the path part will be
-- removed from the display name of the process.

DROP VIEW IF EXISTS event_timings_with_process_info;
CREATE VIEW event_timings_with_process_info AS
SELECT
  event_timings_with_upid.*, process.arg_set_id as "arg_set_id_process",
  REPLACE(
    process.name,
    RTRIM(
      process.name,
      REPLACE(process.name, '/', '')
    ),
    '') AS process_name,
  process.pid AS process_id
FROM event_timings_with_upid
INNER JOIN process
ON event_timings_with_upid.upid = process.upid;

-- Find longest interaction of each process(website)

DROP VIEW IF EXISTS interaction_to_next_paint;
CREATE VIEW interaction_to_next_paint AS
SELECT
 event_timings_with_process_info.*, percentile_cont(0.98) WITHIN GROUP (ORDER BY event_timings_with_process_info.dur) OVER(PARTITION BY     
 event_timings_with_process_info.upid) as "dur"
FROM event_timings_with_process_info
GROUP BY upid;

SELECT * FROM interaction_to_next_paint;