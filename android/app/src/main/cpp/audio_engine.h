// SPDX-License-Identifier: GPL-3.0-or-later
#pragma once

#include <atomic>
#include <cstdint>
#include <memory>
#include <thread>
#include <oboe/Oboe.h>
#include "vendor/include/opus.h"

namespace hams {

class FloatRing final {
 public:
  static constexpr uint32_t kFrames = 480 * 32;
  bool push(const float* input, uint32_t count) noexcept;
  uint32_t pop(float* output, uint32_t count) noexcept;
 private:
  float data_[kFrames]{};
  std::atomic<uint32_t> read_{0};
  std::atomic<uint32_t> write_{0};
};

class AudioEngine final : public oboe::AudioStreamDataCallback,
                          public oboe::AudioStreamErrorCallback {
 public:
  AudioEngine() = default;
  ~AudioEngine() override;
  bool startCapture(int32_t deviceId);
  int32_t audioSessionId() const noexcept {
    return input_ ? input_->getSessionId() : oboe::kUnspecified;
  }
  void stop() noexcept;
  void setMuted(bool muted) noexcept { muted_.store(muted, std::memory_order_release); }
  void setPushToTalk(bool enabled, bool pressed) noexcept {
    ptt_.store(!enabled || pressed, std::memory_order_release);
  }
  void setBoost(float boost) noexcept { boost_.store(boost, std::memory_order_release); }
  void setNoiseReduction(bool enabled) noexcept {
    noiseReduction_.store(enabled, std::memory_order_release);
  }
  oboe::DataCallbackResult onAudioReady(oboe::AudioStream* stream, void* audioData,
                                        int32_t numFrames) noexcept override;
  void onErrorBeforeClose(oboe::AudioStream*, oboe::Result) override {}
  void onErrorAfterClose(oboe::AudioStream*, oboe::Result) override {}

 private:
  void encodeLoop();
  std::shared_ptr<oboe::AudioStream> input_;
  std::unique_ptr<OpusEncoder, void (*)(OpusEncoder*)> encoder_{nullptr, opus_encoder_destroy};
  FloatRing ring_;
  std::atomic<bool> running_{false};
  std::atomic<bool> muted_{false};
  std::atomic<bool> ptt_{true};
  std::atomic<float> boost_{1.0f};
  std::atomic<bool> noiseReduction_{true};
  std::unique_ptr<std::thread> encoderThread_;
};

}  // namespace hams
