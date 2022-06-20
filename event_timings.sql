-- Find all interactions that have id (id>0) and their types,frames.
DROP VIEW IF EXISTS event_timings;
CREATE VIEW event_timings AS
    SELECT slice.*,
         EXTRACT_ARG(arg_set_id, 'debug.data.interactionId') as "interaction_id",
         EXTRACT_ARG(arg_set_id, 'debug.data.type') as "interaction_type",
         EXTRACT_ARG(arg_set_id, 'debug.data.frame') as "interaction_frame"
    FROM slice
    WHERE
        name = "EventTiming" AND
        interaction_id > 0;

-- Find process id of each interaction (upid)
DROP VIEW IF EXISTS event_timings_with_upid;
CREATE VIEW event_timings_with_upid AS
    SELECT event_timings.*, process_track.upid
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

-- Create the derived event track based on the longest duration of interaction per frame
DROP VIEW IF EXISTS chrome_event_timings_event;
CREATE VIEW chrome_event_timings_event AS
    SELECT interaction_id,
           MAX(dur) AS dur,
           interaction_type,
           ts,
           interaction_frame,
           process_name,
           process_id
    FROM event_timings_with_process_info
    GROUP BY interaction_id;

-- Display the derived event track on the timeline as a debug_slice
INSERT INTO debug_slices
    SELECT interaction_id, interaction_type, ts, dur, 0 FROM chrome_event_timings_event;
------------------------------
/*
DROP VIEW IF EXISTS chrome_event_timings_output;
CREATE VIEW chrome_event_timings_output AS
SELECT ChromeDroppedFrames( :TODO
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
*/