// SPDX-License-Identifier: GPL-3.0-or-later
#include <jni.h>

extern "C" JNIEXPORT jstring JNICALL
Java_org_hams_app_MainActivity_nativeHello(JNIEnv* env, jobject) {
    return env->NewStringUTF("hello");
}
