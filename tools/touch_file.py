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

# This script writes an empty file to disk at the specified path. The main use
# of this is to allow noop targets to be written in GN which simply propogate
# information to the GN description files without actually generating any data.

import argparse
import sys
import os


def touch(fname, times=None):
  with open(fname, 'a'):
    os.utime(fname, times)


def main():
  parser = argparse.ArgumentParser()
  parser.add_argument('--output')
  args = parser.parse_args()

  touch(args.output)
  return 0


if __name__ == '__main__':
  sys.exit(main())
