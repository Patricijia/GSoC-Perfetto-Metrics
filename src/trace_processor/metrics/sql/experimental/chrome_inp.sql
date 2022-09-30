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
SELECT
--  *,
  (ts) AS event_start_ts,
  (ts + slice.dur) AS event_end_ts,
  (dur) AS event_dur,

  EXTRACT_ARG(arg_set_id, 'debug.data.timeStamp') * 1000000 AS time_stamp,
  EXTRACT_ARG(arg_set_id, 'debug.data.processingStart') * 1000000 AS processing_start,
  EXTRACT_ARG(arg_set_id, 'debug.data.processingEnd') * 1000000 AS processing_end,

  EXTRACT_ARG(arg_set_id, 'debug.data.interactionId') AS interaction_id,
  EXTRACT_ARG(arg_set_id, 'debug.data.type') AS event_type,

  process_track.upid
FROM
  slice
INNER JOIN
  process_track
ON
  slice.track_id = process_track.id
WHERE
  slice.name = "EventTiming"
ORDER BY
  ts;



-- Find inp metric based on using ANY event with first processing time and first timestamp.
DROP VIEW IF EXISTS interaction_frames;
CREATE VIEW interaction_frames AS
  SELECT
    COUNT(CASE WHEN interaction_id > 0 THEN 1 END) AS interaction_count,
    GROUP_CONCAT(interaction_id) AS interaction_ids,
    GROUP_CONCAT(event_type) AS event_types,
    (CASE WHEN event_dur > 200000000 THEN 'needs improvement' ELSE 'good' END) AS inp_group,
      
    (MIN(processing_start) - MIN(time_stamp)) AS input_delay,
    (MAX(processing_end) - MIN(processing_start)) AS processing_time,
    (event_end_ts - (MIN(event_start_ts)- MIN(time_stamp) + MAX(processing_end))) AS presentation_delay,
    MIN(event_start_ts) AS event_start_ts,
    event_end_ts,
    event_dur

  FROM
    event_timings
  GROUP BY
    event_end_ts
  HAVING
    interaction_count > 0;


-- Create the derived event track for inp metric.
-- All tracks generated from chrome_inp_event are
-- placed under a track group named 'Inp'from any process.

DROP VIEW IF EXISTS chrome_inp_event;
CREATE VIEW chrome_inp_event AS
SELECT 'slice' as track_type, inp_group AS track_name, event_start_ts as ts, CASE WHEN event_dur = (SELECT MAX(event_dur) FROM interaction_frames) THEN input_delay ELSE 0 END as dur, 'Input_delay' AS slice_name,
  'Inp' AS group_name FROM interaction_frames
UNION ALL
SELECT 'slice' as track_type, inp_group AS track_name, event_start_ts+input_delay+1 as ts, CASE WHEN event_dur = (SELECT MAX(event_dur) FROM interaction_frames) THEN processing_time ELSE 0 END as dur, 'Processing_time' AS slice_name,
  'Inp' AS group_name FROM interaction_frames
UNION ALL
SELECT 'slice' as track_type, inp_group AS track_name, event_start_ts+processing_time+input_delay+2 as ts, CASE WHEN event_dur = (SELECT MAX(event_dur) FROM interaction_frames) THEN presentation_delay ELSE 0 END as dur, 'Presentation_delay' AS slice_name,
  'Inp' AS group_name FROM interaction_frames;

-- Create the inp metric output.
DROP VIEW IF EXISTS chrome_inp_output;
CREATE VIEW chrome_inp_output AS
SELECT ChromeInp(
  'inp', (
    SELECT RepeatedField(
      ChromeInp_Inp(
        'start_ts', event_start_ts,
        'dur', event_dur,
        'input_delay', input_delay,
        'processing_time', processing_time,
        'presentation_delay', presentation_delay,
        'nr_of_interactions', interaction_count,
        'all_events', event_types,
        'input_delay_pct', input_delay * 1.0 / event_dur * 100,
  	'processing_time_pct', processing_time * 1.0 / event_dur * 100,
  	'presentation_delay_pct', presentation_delay * 1.0 / event_dur * 100
      )
    )
    FROM interaction_frames
    ORDER BY event_dur DESC
  )
);
