#pragma once
#include <cstdint>
#include <vector>

/// YIN pitch detection algorithm (de Cheveigné & Kawahara, 2002).
/// Full implementation in Phase 2.
class YinDetector {
public:
    YinDetector(int sample_rate, int frame_size);
    float process(const int16_t* samples, int num_samples);
    float confidence() const { return confidence_; }
    void  reset();

private:
    int   sample_rate_;
    int   frame_size_;
    float confidence_ = 0.0f;
    std::vector<float> diff_buffer_;
};
