#include "fft_util.h"

#include <cmath>
#include <cassert>
#include <algorithm>

static constexpr double kPi = 3.14159265358979323846;
static constexpr float  kInt16Max = 32768.0f;

FftUtil::FftUtil(int frame_size, int sample_rate)
    : frame_size_(frame_size),
      sample_rate_(sample_rate),
      cfg_(nullptr),
      window_(frame_size),
      time_buf_(frame_size),
      freq_buf_(frame_size / 2 + 1)
{
    assert((frame_size & (frame_size - 1)) == 0 && "frame_size must be a power of 2");

    cfg_ = kiss_fftr_alloc(frame_size, /*inverse=*/0, nullptr, nullptr);
    assert(cfg_ && "kiss_fftr_alloc failed");

    // Pre-compute Hann window: w[n] = 0.5 * (1 - cos(2π·n / (N-1)))
    const double denom = frame_size - 1;
    for (int n = 0; n < frame_size; ++n)
        window_[n] = static_cast<float>(0.5 * (1.0 - std::cos(2.0 * kPi * n / denom)));
}

FftUtil::~FftUtil() {
    if (cfg_) kiss_fftr_free(cfg_);
}

void FftUtil::process(const int16_t* samples, int num_samples) {
    const int n = std::min(num_samples, frame_size_);
    for (int i = 0; i < n; ++i)
        time_buf_[i] = (samples[i] / kInt16Max) * window_[i];
    // Zero-pad if caller passed fewer samples than frame_size
    for (int i = n; i < frame_size_; ++i)
        time_buf_[i] = 0.0f;

    kiss_fftr(cfg_, time_buf_.data(), freq_buf_.data());
}

float FftUtil::magnitude(int k) const {
    assert(k >= 0 && k < num_bins());
    const auto& c = freq_buf_[k];
    return std::sqrt(c.r * c.r + c.i * c.i);
}

float FftUtil::hfc() const {
    double sum = 0.0;
    const int bins = num_bins();
    for (int k = 1; k < bins; ++k) {
        const auto& c = freq_buf_[k];
        const double mag2 = c.r * c.r + c.i * c.i;
        sum += k * mag2;
    }
    // Normalise by frame_size^2 to keep values comparable across different sizes
    const double norm = static_cast<double>(frame_size_) * frame_size_;
    return static_cast<float>(sum / norm);
}

void FftUtil::chromagram(float chroma[12], float min_hz, float max_hz) const {
    for (int p = 0; p < 12; ++p) chroma[p] = 0.0f;

    const int bins   = num_bins();
    const float freq_res = static_cast<float>(sample_rate_) / frame_size_;

    for (int k = 1; k < bins; ++k) {
        const float freq = k * freq_res;
        if (freq < min_hz || freq > max_hz) continue;

        // Pitch class: pc = round(12 * log2(freq / A4)) + 9,  A4 = 440 Hz
        // Offset by 9 because A is pitch class 9 (if C=0)
        const float midi_float = 69.0f + 12.0f * std::log2(freq / 440.0f);
        const int pc = (static_cast<int>(std::round(midi_float)) % 12 + 12) % 12;
        chroma[pc] += magnitude(k);
    }

    // Normalise to [0, 1]
    float max_val = *std::max_element(chroma, chroma + 12);
    if (max_val > 1e-6f)
        for (int p = 0; p < 12; ++p) chroma[p] /= max_val;
}
