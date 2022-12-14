#!/usr/bin/env bash
# Copyright 2019 The TensorFlow Authors. All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
# ==============================================================================
#
# Tests the microcontroller code using native x86 execution.

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR=${SCRIPT_DIR}/../../../../..
cd "${ROOT_DIR}"

source tensorflow/lite/micro/tools/ci_build/helper_functions.sh

readable_run make -f tensorflow/lite/micro/tools/make/Makefile clean

# TODO(b/143715361): downloading first to allow for parallel builds.
readable_run make -f tensorflow/lite/micro/tools/make/Makefile third_party_downloads

# Next, build w/o TF_LITE_STATIC_MEMORY to catch additional errors.
# TODO(b/160955687): We run the tests w/o TF_LITE_STATIC_MEMORY to make the
# internal and open source CI consistent. See b/160955687#comment7 for more
# details.
readable_run make -f tensorflow/lite/micro/tools/make/Makefile clean
readable_run make -j8 -f tensorflow/lite/micro/tools/make/Makefile BUILD_TYPE=no_tf_lite_static_memory test

# Next, make sure that the release build succeeds.
readable_run make -f tensorflow/lite/micro/tools/make/Makefile clean
readable_run make -j8 -f tensorflow/lite/micro/tools/make/Makefile BUILD_TYPE=release build

# Next, build wit release and logs so that we can run the tests and get
# additional debugging info on failures.
readable_run make -f tensorflow/lite/micro/tools/make/Makefile clean
readable_run make -s -j8 -f tensorflow/lite/micro/tools/make/Makefile BUILD_TYPE=release_with_logs build
readable_run make -s -j8 -f tensorflow/lite/micro/tools/make/Makefile BUILD_TYPE=release_with_logs test
readable_run make -s -j8 -f tensorflow/lite/micro/tools/make/Makefile BUILD_TYPE=release_with_logs integration_tests

# Next, build w/o release so that we can run the tests and get additional
# debugging info on failures.
readable_run make -f tensorflow/lite/micro/tools/make/Makefile clean
readable_run make -s -j8 -f tensorflow/lite/micro/tools/make/Makefile build
readable_run make -s -j8 -f tensorflow/lite/micro/tools/make/Makefile test
readable_run make -s -j8 -f tensorflow/lite/micro/tools/make/Makefile integration_tests

# At last test the hello_world as an example outside of the github repo.
readable_run make -f tensorflow/lite/micro/tools/make/Makefile clean
pushd "../"
cp -r tflite-micro/tensorflow/lite/micro/examples/hello_world ./
sed -i 's/tensorflow\/lite\/micro\/examples\///g' hello_world/Makefile.inc
sed -i 's/$(TENSORFLOW_ROOT)//g' hello_world/Makefile.inc
mv hello_world/Makefile.inc hello_world/Makefile_internal.inc
sed -i 's/tensorflow\/lite\/micro\/examples\///g' hello_world/hello_world_test.cc
readable_run make -s -j8 -f tflite-micro/tensorflow/lite/micro/tools/make/Makefile test_hello_world_test TENSORFLOW_ROOT=tflite-micro/ EXTERNAL_DIR=hello_world/
readable_run make -f tflite-micro/tensorflow/lite/micro/tools/make/Makefile clean TENSORFLOW_ROOT=tflite-micro/ EXTERNAL_DIR=hello_world/
rm -rf hello_world
popd
