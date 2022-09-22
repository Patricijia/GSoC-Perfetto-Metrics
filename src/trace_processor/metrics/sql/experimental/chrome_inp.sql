-- Copyright 2021 The Android Open Source Project
--
-- Licensed under the Apache License, Version 2.0 (the "License");
-- you may not use this file except in compliance with the License.
-- You may obtain a copy of the License at
--
--     https://www.apache.org/licenses/LICENSE-2.0
--
-- Unless required by applicable law or agreed to in writing, software
-- distributed under the License is distributed on an "AS IS" BASIS,
-- WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
-- See the License for the specific language governing permissions and
-- limitations under the License.

-- Find all events per frame, i.e. input delay, processing time and presentation delay for each frame.


-- Find all interactions and their types, frames, etc.
DROP VIEW IF EXISTS event_timings;
CREATE VIEW event_timings AS
    SELECT slice.*,
         EXTRACT_ARG(arg_set_id, 'debug.data.interactionId') as "interaction_id",
         EXTRACT_ARG(arg_set_id, 'debug.data.type') as "event_type",
         EXTRACT_ARG(arg_set_id, 'debug.data.timeStamp')*1000000 as "time_stamp",
         EXTRACT_ARG(arg_set_id, 'debug.data.processingStart')*1000000 as "processing_start",
         EXTRACT_ARG(arg_set_id, 'debug.data.processingEnd')*1000000 as "processing_end"
    FROM slice
    WHERE
        name = "EventTiming"
    ORDER BY ts;

-- Find process id of each interaction (upid)
DROP VIEW IF EXISTS event_timings_with_upid;
CREATE VIEW event_timings_with_upid AS
    SELECT
    event_timings.interaction_id, 
    event_timings.ts as event_ts,
    event_timings.ts + event_timings.dur AS event_end_ts,
    event_timings.dur as event_dur, 
    event_timings.time_stamp, 
    event_timings.processing_start, 
    event_timings.processing_end,
    event_type, 
    process_track.upid
    FROM event_timings
        INNER JOIN process_track
            ON event_timings.track_id = process_track.id;

-- Find inp metric based on using ANY event with first processing time and first timestamp.
DROP VIEW IF EXISTS inp_1;
CREATE VIEW inp_1 AS
  SELECT 
    COUNT(CASE WHEN interaction_id > 0 THEN 1 END) as interaction_num,
    GROUP_CONCAT(interaction_id) as events,
    MIN(processing_start) - MIN(time_stamp) as input_delay,
    MAX(processing_end) - MIN(processing_start) as processing_time,
    event_end_ts - (MIN(event_ts)- MIN(time_stamp) + MAX(processing_end)) as presentation_delay,
    event_end_ts,
    event_dur,
    MIN(event_ts) as event_ts
  FROM
    event_timings_with_upid
  GROUP BY
    event_end_ts;


--Taking frames that have at least one interaction
DROP VIEW IF EXISTS inp;
CREATE VIEW inp AS
SELECT *,   CASE WHEN event_dur > 200000000 THEN 'needs improvement'
            ELSE 'good' END AS inp_group
FROM inp_1 WHERE interaction_num >0;


-- Create the derived event track for inp metric.
-- All tracks generated from chrome_inp_event are
-- placed under a track group named 'Inp'from any process.

DROP VIEW IF EXISTS chrome_inp_event;
CREATE VIEW chrome_inp_event AS
SELECT 'slice' as track_type, inp_group AS track_name, event_ts as ts, CASE WHEN event_dur = (SELECT MAX(event_dur) FROM inp) THEN input_delay ELSE 0 END as dur, 'Input_delay' AS slice_name,
  'Inp' AS group_name FROM inp
UNION ALL
SELECT 'slice' as track_type, inp_group AS track_name, event_ts+input_delay+1 as ts, CASE WHEN event_dur = (SELECT MAX(event_dur) FROM inp) THEN processing_time ELSE 0 END as dur, 'Processing_time' AS slice_name,
  'Inp' AS group_name FROM inp
UNION ALL
SELECT 'slice' as track_type, inp_group AS track_name, event_ts+processing_time+input_delay+2 as ts, CASE WHEN event_dur = (SELECT MAX(event_dur) FROM inp) THEN presentation_delay ELSE 0 END as dur, 'Presentation_delay' AS slice_name,
  'Inp' AS group_name FROM inp;

-- Create the inp metric output.
DROP VIEW IF EXISTS chrome_inp_output;
CREATE VIEW chrome_inp_output AS
SELECT ChromeInp(
  'inp', (
    SELECT RepeatedField(
      ChromeInp_Inp(
        'start_ts', event_ts,
        'dur', event_dur,
        'input_delay', input_delay,
        'processing_time', processing_time,
        'presentation_delay', presentation_delay,
        'nr_of_interactions', interaction_num,
        'all_events', events,
        'input_delay_pct', input_delay * 1.0 / event_dur * 100,
  	'processing_time_pct', processing_time * 1.0 / event_dur * 100,
  	'presentation_delay_pct', presentation_delay * 1.0 / event_dur * 100
      )
    )
    FROM inp
    ORDER BY event_dur DESC
  )
);
