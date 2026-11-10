// SPDX-License-Identifier: GPL-3.0-or-later
#include <jni.h>
#include "audio_engine.h"

namespace {
hams::AudioEngine engine;
}

extern "C" JNIEXPORT jstring JNICALL
Java_org_hams_app_MainActivity_nativeHello(JNIEnv* env, jobject) {
    return env->NewStringUTF("hello");
}

extern "C" JNIEXPORT jboolean JNICALL
Java_org_hams_app_MainActivity_nativeStartCapture(JNIEnv*, jobject, jint device_id) {
    return engine.startCapture(device_id) ? JNI_TRUE : JNI_FALSE;
}

extern "C" JNIEXPORT jint JNICALL
Java_org_hams_app_MainActivity_nativeAudioSessionId(JNIEnv*, jobject) {
    return engine.audioSessionId();
}

extern "C" JNIEXPORT void JNICALL
Java_org_hams_app_MainActivity_nativeStopAudio(JNIEnv*, jobject) { engine.stop(); }

extern "C" JNIEXPORT void JNICALL
Java_org_hams_app_MainActivity_nativeSetMuted(JNIEnv*, jobject, jboolean muted) {
    engine.setMuted(muted == JNI_TRUE);
}

extern "C" JNIEXPORT void JNICALL
Java_org_hams_app_MainActivity_nativeSetBoost(JNIEnv*, jobject, jfloat boost) {
    engine.setBoost(boost);
}

extern "C" JNIEXPORT void JNICALL
Java_org_hams_app_MainActivity_nativeSetNoiseReduction(JNIEnv*, jobject, jboolean enabled) {
    engine.setNoiseReduction(enabled == JNI_TRUE);
}
