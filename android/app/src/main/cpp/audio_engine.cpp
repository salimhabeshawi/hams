// SPDX-License-Identifier: GPL-3.0-or-later
#include "audio_engine.h"

#include <algorithm>
#include <array>
#include <cmath>
#include <thread>
#include <utility>

namespace hams {

bool FloatRing::push(const float* input, uint32_t count) noexcept {
  const auto write = write_.load(std::memory_order_relaxed);
  const auto read = read_.load(std::memory_order_acquire);
  if (count > kFrames - (write - read)) return false;
  for (uint32_t i = 0; i < count; ++i) data_[(write + i) % kFrames] = input[i];
  write_.store(write + count, std::memory_order_release);
  return true;
}

uint32_t FloatRing::pop(float* output, uint32_t count) noexcept {
  const auto read = read_.load(std::memory_order_relaxed);
  const auto write = write_.load(std::memory_order_acquire);
  const auto available = std::min(count, write - read);
  for (uint32_t i = 0; i < available; ++i) output[i] = data_[(read + i) % kFrames];
  read_.store(read + available, std::memory_order_release);
  return available;
}

AudioEngine::~AudioEngine() { stop(); }

bool AudioEngine::startCapture(int32_t deviceId) {
  stop();
  int error = OPUS_OK;
  encoder_.reset(opus_encoder_create(48000, 1, OPUS_APPLICATION_VOIP, &error));
  if (!encoder_ || error != OPUS_OK) return false;
  opus_encoder_ctl(encoder_.get(), OPUS_SET_BITRATE(32000));
  opus_encoder_ctl(encoder_.get(), OPUS_SET_VBR(1));
  opus_encoder_ctl(encoder_.get(), OPUS_SET_VBR_CONSTRAINT(1));
  opus_encoder_ctl(encoder_.get(), OPUS_SET_COMPLEXITY(6));
  opus_encoder_ctl(encoder_.get(), OPUS_SET_INBAND_FEC(1));
  opus_encoder_ctl(encoder_.get(), OPUS_SET_PACKET_LOSS_PERC(10));
  opus_encoder_ctl(encoder_.get(), OPUS_SET_DTX(0));
  oboe::AudioStreamBuilder builder;
  builder.setDirection(oboe::Direction::Input)
      ->setFormat(oboe::AudioFormat::Float)
      ->setChannelCount(1)
      ->setSampleRate(48000)
      ->setPerformanceMode(oboe::PerformanceMode::LowLatency)
      ->setSharingMode(oboe::SharingMode::Shared)
      ->setInputPreset(oboe::InputPreset::VoiceRecognition)
      ->setDeviceId(deviceId)
      ->setDataCallback(this)
      ->setErrorCallback(this);
  if (builder.openStream(input_) != oboe::Result::OK) {
    // Some devices do not expose a low-latency path; use the normal shared path.
    builder.setPerformanceMode(oboe::PerformanceMode::None)
        ->setBufferCapacityInFrames(480 * 8);
    if (builder.openStream(input_) != oboe::Result::OK) {
      encoder_.reset();
      return false;
    }
  }
  running_.store(true, std::memory_order_release);
  encoderThread_ = std::make_unique<std::thread>(&AudioEngine::encodeLoop, this);
  if (input_->requestStart() != oboe::Result::OK) {
    stop();
    return false;
  }
  return true;
}

void AudioEngine::stop() noexcept {
  running_.store(false, std::memory_order_release);
  if (input_) input_->requestStop();
  if (encoderThread_ && encoderThread_->joinable()) encoderThread_->join();
  encoderThread_.reset();
  if (input_) input_->close();
  input_.reset();
  encoder_.reset();
}

oboe::DataCallbackResult AudioEngine::onAudioReady(oboe::AudioStream*, void* audioData,
                                                    int32_t numFrames) noexcept {
  if (!muted_.load(std::memory_order_acquire) && ptt_.load(std::memory_order_acquire)) {
    ring_.push(static_cast<const float*>(audioData), static_cast<uint32_t>(numFrames));
  }
  return oboe::DataCallbackResult::Continue;
}

void AudioEngine::encodeLoop() {
  std::array<float, 960> frame{};
  std::array<unsigned char, 4000> encoded{};
  float previousInput = 0.0f;
  float previousOutput = 0.0f;
  float noiseFloor = 0.0025f;
  while (running_.load(std::memory_order_acquire)) {
    if (ring_.pop(frame.data(), frame.size()) != frame.size()) {
      std::this_thread::yield();
      continue;
    }
    for (float& sample : frame) {
      const float filtered = sample - previousInput + 0.995f * previousOutput;
      previousInput = sample;
      previousOutput = filtered;
      if (noiseReduction_.load(std::memory_order_acquire)) {
        const float magnitude = std::fabs(filtered);
        noiseFloor += (magnitude - noiseFloor) * (magnitude < noiseFloor ? 0.02f : 0.0005f);
        const float reduction = std::max(0.0f, magnitude - noiseFloor * 1.5f);
        const float denoised = magnitude > 1e-6f
            ? filtered * (reduction / magnitude)
            : 0.0f;
        // Keep 20% of the dry signal to avoid a processed or gated voice.
        sample = 0.8f * denoised + 0.2f * filtered;
      } else {
        sample = filtered;
      }
    }
    opus_encode_float(encoder_.get(), frame.data(), 960, encoded.data(),
                      static_cast<opus_int32>(encoded.size()));
    // Transport consumes encoded frames in the session sender thread.
  }
}

}  // namespace hams
