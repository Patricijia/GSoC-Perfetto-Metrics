#!/usr/bin/env python3
# Copyright (C) 2020 The Android Open Source Project
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

from os import sys, path

import synth_common

trace = synth_common.create_trace()
trace.add_packet()

# Global gpu_mem_total initial counter event
trace.add_gpu_mem_total_event(pid=0, ts=0, size=123)

# Global gpu_mem_total ftrace event
trace.add_ftrace_packet(cpu=0)
trace.add_gpu_mem_total_ftrace_event(pid=0, ts=5, size=256)
trace.add_gpu_mem_total_ftrace_event(pid=0, ts=10, size=123)

# gpu_mem_total initial counter event for pid = 1
trace.add_gpu_mem_total_event(pid=1, ts=0, size=100)

# gpu_mem_total ftrace event for pid = 1
trace.add_ftrace_packet(cpu=1)
trace.add_gpu_mem_total_ftrace_event(pid=1, ts=5, size=233)
trace.add_gpu_mem_total_ftrace_event(pid=1, ts=10, size=0)

sys.stdout.buffer.write(trace.trace.SerializeToString())
