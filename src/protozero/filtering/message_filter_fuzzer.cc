/*
 * Copyright (C) 2021 The Android Open Source Project
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

#include <stddef.h>
#include <stdint.h>
#include <string.h>

#include "perfetto/base/logging.h"
#include "src/protozero/filtering/message_filter.h"

namespace protozero {
namespace {

// A valid filter bytecode obtained from a perfetto.protos.Trace message.
uint8_t kValidFilter[] = {
    0x0b, 0x01, 0x12, 0x04, 0x00, 0x0b, 0x02, 0x13, 0x0f, 0x19, 0x23, 0x13,
    0x33, 0x14, 0x3b, 0x15, 0x41, 0x4b, 0x11, 0x51, 0x5b, 0x16, 0x63, 0x3b,
    0x69, 0x8b, 0x02, 0x21, 0x93, 0x02, 0x2a, 0x9b, 0x02, 0x2c, 0xab, 0x02,
    0x2e, 0xb3, 0x02, 0x09, 0xc3, 0x02, 0x30, 0xca, 0x02, 0x02, 0xdb, 0x02,
    0x31, 0xe3, 0x02, 0x26, 0xeb, 0x02, 0x32, 0xf3, 0x02, 0x07, 0xfb, 0x02,
    0x33, 0x8b, 0x03, 0x0a, 0x9b, 0x03, 0x34, 0xb3, 0x03, 0x06, 0xc3, 0x03,
    0x37, 0xd1, 0x03, 0xdb, 0x03, 0x3c, 0xe3, 0x03, 0x39, 0x93, 0x04, 0x38,
    0x9b, 0x04, 0x3a, 0x00, 0x09, 0x13, 0x03, 0x19, 0x00, 0x0a, 0x02, 0x1b,
    0x04, 0x23, 0x05, 0x5b, 0x06, 0x6b, 0x06, 0x83, 0x01, 0x07, 0x8b, 0x01,
    0x08, 0x93, 0x01, 0x07, 0x9b, 0x01, 0x07, 0xa3, 0x01, 0x08, 0x9b, 0x02,
    0x08, 0xcb, 0x02, 0x08, 0xd3, 0x02, 0x08, 0xdb, 0x02, 0x09, 0xe3, 0x02,
    0x07, 0xeb, 0x02, 0x0a, 0xf3, 0x02, 0x07, 0xfb, 0x02, 0x0b, 0x83, 0x03,
    0x06, 0x8b, 0x03, 0x0b, 0x93, 0x03, 0x05, 0x9b, 0x03, 0x0b, 0xab, 0x03,
    0x0c, 0xb3, 0x03, 0x0c, 0xbb, 0x03, 0x0c, 0x9b, 0x04, 0x0d, 0xa3, 0x04,
    0x07, 0xab, 0x04, 0x06, 0xb3, 0x04, 0x07, 0xc3, 0x04, 0x06, 0xcb, 0x04,
    0x07, 0xd3, 0x04, 0x07, 0xdb, 0x04, 0x06, 0x93, 0x07, 0x08, 0xeb, 0x07,
    0x08, 0xcb, 0x09, 0x07, 0xd3, 0x09, 0x05, 0xf3, 0x0b, 0x06, 0xdb, 0x0e,
    0x09, 0xe3, 0x0e, 0x09, 0xeb, 0x0e, 0x07, 0xf3, 0x0e, 0x09, 0xfb, 0x0e,
    0x09, 0x83, 0x0f, 0x07, 0x8b, 0x0f, 0x06, 0x93, 0x0f, 0x07, 0xb3, 0x0f,
    0x0a, 0xc3, 0x0f, 0x0e, 0xfb, 0x0f, 0x0e, 0x83, 0x10, 0x08, 0xfb, 0x10,
    0x08, 0x8b, 0x11, 0x08, 0xcb, 0x13, 0x06, 0xd3, 0x13, 0x07, 0xdb, 0x13,
    0x07, 0xb3, 0x14, 0x07, 0x00, 0x11, 0x00, 0x0a, 0x07, 0x00, 0x0a, 0x02,
    0x00, 0x0a, 0x03, 0x00, 0x0a, 0x05, 0x00, 0x0a, 0x04, 0x00, 0x0a, 0x06,
    0x00, 0x09, 0x00, 0x00, 0x0a, 0x03, 0x29, 0x00, 0x0a, 0x08, 0x00, 0x0b,
    0x10, 0x13, 0x07, 0x19, 0x00, 0x0a, 0x03, 0x23, 0x07, 0x29, 0x00, 0x0b,
    0x12, 0x11, 0x00, 0x0a, 0x0a, 0x5b, 0x07, 0x00, 0x0a, 0x02, 0x1b, 0x07,
    0x00, 0x0b, 0x09, 0x11, 0x00, 0x0b, 0x06, 0x13, 0x06, 0x1b, 0x0e, 0x22,
    0x02, 0x33, 0x06, 0x39, 0x43, 0x06, 0x49, 0x00, 0x0a, 0x03, 0x2b, 0x0b,
    0x33, 0x20, 0x42, 0x05, 0x82, 0x01, 0x02, 0xa1, 0x01, 0xc3, 0x01, 0x17,
    0xcb, 0x01, 0x04, 0xd3, 0x01, 0x0b, 0xdb, 0x01, 0x06, 0xe3, 0x01, 0x1e,
    0xeb, 0x01, 0x1f, 0xf2, 0x01, 0x02, 0x00, 0x0b, 0x18, 0x12, 0x0c, 0x73,
    0x1a, 0x7b, 0x1c, 0x83, 0x01, 0x1d, 0x8b, 0x01, 0x05, 0x00, 0x0b, 0x08,
    0x13, 0x19, 0x00, 0x0a, 0x2e, 0x00, 0x0a, 0x03, 0x23, 0x1b, 0x2b, 0x1b,
    0x33, 0x05, 0x00, 0x0a, 0x09, 0x53, 0x09, 0x00, 0x09, 0x13, 0x1b, 0x00,
    0x0a, 0x03, 0x23, 0x1b, 0x00, 0x09, 0x19, 0x00, 0x0a, 0x03, 0x23, 0x06,
    0x2a, 0x02, 0x00, 0x0a, 0x04, 0x31, 0x42, 0x08, 0x92, 0x01, 0x02, 0x00,
    0x0b, 0x22, 0x13, 0x23, 0x1a, 0x03, 0x33, 0x07, 0x3b, 0x09, 0x42, 0x03,
    0x5b, 0x0b, 0x62, 0x03, 0x81, 0x01, 0x8b, 0x01, 0x29, 0x92, 0x01, 0x02,
    0xa3, 0x01, 0x07, 0xab, 0x01, 0x0b, 0xb2, 0x01, 0x03, 0xcb, 0x01, 0x09,
    0xda, 0x01, 0x02, 0x00, 0x09, 0x21, 0x00, 0x0b, 0x24, 0x11, 0x00, 0x0a,
    0x04, 0x31, 0xa3, 0x06, 0x25, 0xbb, 0x06, 0x26, 0xc3, 0x06, 0x0a, 0xcb,
    0x06, 0x27, 0xd3, 0x06, 0x06, 0xeb, 0x06, 0x0b, 0x00, 0x0a, 0x03, 0x52,
    0x02, 0x00, 0x0a, 0x04, 0x32, 0x03, 0x00, 0x0a, 0x02, 0x22, 0x02, 0x33,
    0x28, 0x3a, 0x02, 0x00, 0x2a, 0x02, 0x00, 0x09, 0x13, 0x07, 0x19, 0x00,
    0x09, 0x13, 0x2b, 0x00, 0x0a, 0x09, 0x00, 0x0b, 0x2d, 0x12, 0x08, 0x00,
    0x0a, 0x12, 0x00, 0x0b, 0x06, 0x13, 0x09, 0x1b, 0x06, 0x23, 0x05, 0x2b,
    0x2f, 0x32, 0x02, 0x00, 0x09, 0x13, 0x0a, 0x00, 0x0b, 0x09, 0x13, 0x07,
    0x00, 0x09, 0x1a, 0x03, 0x00, 0x0b, 0x09, 0x12, 0x02, 0x00, 0x0b, 0x08,
    0x12, 0x02, 0x00, 0x0b, 0x35, 0x11, 0x00, 0x0b, 0x36, 0x13, 0x36, 0x00,
    0x09, 0x13, 0x07, 0x1b, 0x0b, 0x00, 0x09, 0x13, 0x08, 0x1b, 0x06, 0x23,
    0x06, 0x2a, 0x02, 0x3b, 0x06, 0x00, 0x0a, 0x05, 0x82, 0x01, 0x03, 0x00,
    0x09, 0x1b, 0x31, 0x23, 0x26, 0x29, 0x33, 0x09, 0x3b, 0x06, 0x43, 0x31,
    0x00, 0x0b, 0x06, 0x00, 0x0b, 0x06, 0x13, 0x06, 0x23, 0x09, 0x2b, 0x06,
    0x33, 0x09, 0x3b, 0x06, 0x83, 0x01, 0x06, 0x8b, 0x01, 0x06, 0x93, 0x01,
    0x06, 0x9b, 0x01, 0x05, 0x00, 0x5b, 0x3d, 0xd1, 0x03, 0x00, 0x59, 0xf9,
    0x01, 0x00, 0x8f, 0xf8, 0xf5, 0xcb, 0x06};

int FuzzMessageFilter(const uint8_t* data, size_t size) {
  MessageFilter filter;
  PERFETTO_CHECK(filter.LoadFilterBytecode(kValidFilter, sizeof(kValidFilter)));

  auto res = filter.FilterMessage(data, size);

  // Either parsing fails or if it succeeds, the output data must be <= input.
  PERFETTO_CHECK(res.error || res.size <= size);
  return 0;
}

}  // namespace
}  // namespace protozero

extern "C" int LLVMFuzzerTestOneInput(const uint8_t* data, size_t size);

extern "C" int LLVMFuzzerTestOneInput(const uint8_t* data, size_t size) {
  return protozero::FuzzMessageFilter(data, size);
}
