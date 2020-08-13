--
-- Copyright 2020 The Android Open Source Project
--
-- Licensed under the Apache License, Version 2.0 (the 'License');
-- you may not use this file except in compliance with the License.
-- You may obtain a copy of the License at
--
--     https://www.apache.org/licenses/LICENSE-2.0
--
-- Unless required by applicable law or agreed to in writing, software
-- distributed under the License is distributed on an 'AS IS' BASIS,
-- WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
-- See the License for the specific language governing permissions and
-- limitations under the License.
--
-- This metric takes each flow event in a InputLatency::GestureScrollUpdate and
-- and computes the time from the ancestor_end of the current flow to the
-- ancestor_ts of the next flow event. This is a reasonable approximation of the
-- time we waited for the next step in the critical flow to start.

-- Provides the scroll_flow_event table which gives us all the flow events with
-- associated GestureScrollUpdate events we care about and labels them janky or
-- not.
SELECT RUN_METRIC('chrome/scroll_flow_event.sql');

-- Take each flow and next flow (from scroll_flow_event table) and generate the
-- metric name as well as compute the time between.
DROP VIEW IF EXISTS scroll_flow_event_queuing_delay;

CREATE VIEW scroll_flow_event_queuing_delay AS
  SELECT
    trace_id,
    id,
    ts,
    dur,
    track_id,
    gesture_scroll_id,
    scroll_slice_id,
    scroll_ts,
    scroll_dur,
    scroll_track_id,
    jank,
    step,
    ancestor_id,
    ancestor_ts,
    ancestor_end,
    next_id,
    next_step,
    maybe_next_ancestor_ts,
    next_track_id,
      CASE WHEN trace_id = next_trace_id THEN
      'InputLatency.LatencyInfo.Flow.QueuingDelay.' ||
      CASE WHEN
        jank IS NOT NULL AND
        jank = 1
      THEN
          'Jank.'
      ELSE
          'NoJank.'
      END
      || step || '-to-' || next_step
    ELSE
      step
    END AS description,
    CASE WHEN maybe_next_ancestor_ts IS NULL THEN
      NULL
    ELSE
      CASE WHEN maybe_next_ancestor_ts > ancestor_end THEN
        (maybe_next_ancestor_ts - ancestor_end)
      ELSE
        0
      END
    END AS queuing_time_ns
  FROM scroll_flow_event
  ORDER BY gesture_scroll_id, trace_id, ts;
