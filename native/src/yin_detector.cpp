#include "yin_detector.h"

#include <cmath>
#include <cassert>
#include <algorithm>
#include <limits>

static constexpr float kInt16Max   = 32768.0f;
static constexpr float kThreshold  = 0.15f;   // per YIN paper §3.3

YinDetector::YinDetector(int sample_rate, int frame_size)
    : sample_rate_(sample_rate),
      frame_size_(frame_size),
      tau_max_(frame_size / 2),
      threshold_(kThreshold),
      confidence_(0.0f),
      diff_(frame_size / 2 + 1, 0.0f),
      cmndf_(frame_size / 2 + 1, 0.0f),
      frame_f32_(frame_size, 0.0f)
{
    assert(frame_size > 0 && "frame_size must be > 0");
}

void YinDetector::reset() {
    confidence_ = 0.0f;
    std::fill(diff_.begin(),    diff_.end(),    0.0f);
    std::fill(cmndf_.begin(),   cmndf_.end(),   0.0f);
    std::fill(frame_f32_.begin(), frame_f32_.end(), 0.0f);
}

float YinDetector::process(const int16_t* samples, int num_samples) {
    const int n = std::min(num_samples, frame_size_);

    // Convert int16 → float [-1, 1]
    for (int i = 0; i < n; ++i)
        frame_f32_[i] = samples[i] / kInt16Max;
    for (int i = n; i < frame_size_; ++i)
        frame_f32_[i] = 0.0f;

    compute_difference();
    compute_cmndf();

    int tau = absolute_threshold();

    if (tau < 0) {
        // No minimum found below threshold — return 0 (no pitch)
        confidence_ = 0.0f;
        return 0.0f;
    }

    // Parabolic interpolation for sub-sample tau
    const float tau_f = parabolic_interpolation(tau);

    // confidence = 1 - d'(tau); clamped to [0, 1]
    confidence_ = std::max(0.0f, std::min(1.0f, 1.0f - cmndf_[tau]));

    return sample_rate_ / tau_f;
}

// ── Step 1: Difference function ─────────────────────────────────────────────
// d(tau) = Σ_{j=0}^{N-tau-1} (x[j] - x[j+tau])²
// O(N·tau_max) — fast enough for frame_size ≤ 4096 on mobile hardware.
void YinDetector::compute_difference() {
    const float* x = frame_f32_.data();
    diff_[0] = 0.0f;
    for (int tau = 1; tau <= tau_max_; ++tau) {
        float sum = 0.0f;
        const int limit = frame_size_ - tau;
        for (int j = 0; j < limit; ++j) {
            const float delta = x[j] - x[j + tau];
            sum += delta * delta;
        }
        diff_[tau] = sum;
    }
}

// ── Step 2: Cumulative Mean Normalized Difference (CMNDF) ───────────────────
// d'(0) = 1
// d'(tau) = d(tau) · tau / Σ_{j=1}^{tau} d(j)   for tau > 0
void YinDetector::compute_cmndf() {
    cmndf_[0] = 1.0f;
    float running_sum = 0.0f;
    for (int tau = 1; tau <= tau_max_; ++tau) {
        running_sum += diff_[tau];
        cmndf_[tau] = (running_sum > 1e-10f)
                      ? diff_[tau] * tau / running_sum
                      : 0.0f;
    }
}

// ── Step 3: Absolute threshold ───────────────────────────────────────────────
// Returns the first tau ≥ 2 where d'(tau) < threshold, choosing the local
// minimum in that vicinity. If nothing found below threshold, returns the
// global minimum (which gives low confidence).
int YinDetector::absolute_threshold() const {
    // Search from tau=2 (period ≥ 2 samples → f ≤ Nyquist/2)
    for (int tau = 2; tau < tau_max_; ++tau) {
        if (cmndf_[tau] < threshold_) {
            // Walk forward to local minimum (while still below threshold)
            while (tau + 1 < tau_max_ && cmndf_[tau + 1] < cmndf_[tau])
                ++tau;
            return tau;
        }
    }

    // Fallback: global minimum (signal may be pitched but noisy or harmonic-rich)
    int best = 2;
    for (int tau = 3; tau < tau_max_; ++tau)
        if (cmndf_[tau] < cmndf_[best]) best = tau;

    // Only report as "found" if the global min is reasonably low
    return (cmndf_[best] < 0.5f) ? best : -1;
}

// ── Step 4: Parabolic interpolation ─────────────────────────────────────────
// Refines integer tau to a sub-sample estimate by fitting a parabola to
// d'(tau-1), d'(tau), d'(tau+1) and finding its vertex.
float YinDetector::parabolic_interpolation(int tau) const {
    if (tau <= 1 || tau >= tau_max_) return static_cast<float>(tau);

    const float s0 = cmndf_[tau - 1];
    const float s1 = cmndf_[tau];
    const float s2 = cmndf_[tau + 1];

    const float denom = s0 - 2.0f * s1 + s2;
    if (std::abs(denom) < 1e-10f) return static_cast<float>(tau);

    const float delta = 0.5f * (s0 - s2) / denom;
    // Clamp delta to [-1, 1] to prevent wild extrapolation
    return tau + std::max(-1.0f, std::min(1.0f, delta));
}
