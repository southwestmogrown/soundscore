#pragma once
#include <cstdint>
#include <vector>

/// High Frequency Content onset detector with BPM estimation.
/// Full implementation in Phase 2.
class OnsetDetector {
public:
    OnsetDetector(int sample_rate, int frame_size);
    bool  detect(const int16_t* samples, int num_samples);
    float estimated_bpm() const { return bpm_; }
    void  reset();

private:
    int   sample_rate_;
    int   frame_size_;
    float bpm_ = 0.0f;
    float prev_hfc_ = 0.0f;
    std::vector<float> onset_times_;
};
