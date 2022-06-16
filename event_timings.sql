DROP VIEW IF EXISTS event_timings_id;
CREATE VIEW event_timings_id AS
SELECT slice.* , args.int_value as "interaction_id" FROM slice
INNER JOIN args
ON slice.arg_set_id = args.arg_set_id
WHERE
  slice.name = "EventTiming" AND
  args.key = "debug.data.interactionId" AND
  args.int_value > 0;

DROP VIEW IF EXISTS event_timings_type;
CREATE VIEW event_timings_type AS
SELECT slice.*, args.string_value as "interaction_type" FROM slice
INNER JOIN args
ON slice.arg_set_id = args.arg_set_id
WHERE
  slice.name = "EventTiming" AND 
  args.key = "debug.data.type" AND
  args.string_value IS NOT NULL;

DROP VIEW IF EXISTS event_timings_frame;
CREATE VIEW event_timings_frame AS
SELECT slice.* , args.string_value as "interaction_frame" FROM slice
INNER JOIN args
ON slice.arg_set_id = args.arg_set_id
WHERE
  slice.name = "EventTiming" AND
  args.key = "debug.data.frame";

DROP VIEW IF EXISTS event_timings;
CREATE VIEW event_timings AS
SELECT event_timings_id.id, event_timings_id.track_id,event_timings_id.ts, event_timings_id.dur, event_timings_id.interaction_id, event_timings_type.interaction_type, event_timings_frame.interaction_frame FROM event_timings_id
INNER JOIN event_timings_type
ON event_timings_id.id = event_timings_type.id
INNER JOIN event_timings_frame
ON event_timings_type.id = event_timings_frame.id;

DROP VIEW IF EXISTS event_timings_with_upid;
CREATE VIEW event_timings_with_upid AS
SELECT
  event_timings.*, process_track.upid
FROM event_timings
INNER JOIN process_track
ON event_timings.track_id = process_track.id;

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

-- Create the derived event track.
DROP VIEW IF EXISTS chrome_event_timings_event;
CREATE VIEW chrome_event_timings_event AS
SELECT
  interaction_id,
  MAX(dur) AS dur,
  interaction_type,
  ts,
  interaction_frame,
  process_name,
  process_id
FROM event_timings_with_process_info
GROUP BY interaction_id;

DROP VIEW IF EXISTS chrome_event_timings_output;
CREATE VIEW chrome_event_timings_output AS
SELECT ChromeDroppedFrames(
  'event_timings', (
    SELECT RepeatedField(
      ChromeDroppedFrames_DroppedFrame(
        'interaction_id', interaction_id,
        'interaction_type', interaction_type,
        'ts', ts,
        'dur', dur,
        'process_name', process_name,
        'pid', process_id
      )
    )
    FROM event_timings_with_process_info
    ORDER BY dur
  )
);
