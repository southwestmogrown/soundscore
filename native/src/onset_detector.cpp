#include "onset_detector.h"
// Phase 2: Full HFC onset detection + BPM estimation goes here.

OnsetDetector::OnsetDetector(int sample_rate, int frame_size)
    : sample_rate_(sample_rate), frame_size_(frame_size) {}

bool OnsetDetector::detect(const int16_t* /*samples*/, int /*num_samples*/) {
    return false; // Stub
}

void OnsetDetector::reset() {
    bpm_ = 0.0f;
    prev_hfc_ = 0.0f;
    onset_times_.clear();
}
