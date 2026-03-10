#include "yin_detector.h"
// Phase 2: Full YIN algorithm implementation goes here.

YinDetector::YinDetector(int sample_rate, int frame_size)
    : sample_rate_(sample_rate), frame_size_(frame_size),
      diff_buffer_(frame_size / 2, 0.0f) {}

float YinDetector::process(const int16_t* /*samples*/, int /*num_samples*/) {
    // Stub — returns 0 (no pitch) until Phase 2 implementation
    confidence_ = 0.0f;
    return 0.0f;
}

void YinDetector::reset() {
    confidence_ = 0.0f;
    std::fill(diff_buffer_.begin(), diff_buffer_.end(), 0.0f);
}
