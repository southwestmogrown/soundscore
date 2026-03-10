/*
 *  Copyright (c) 2003-2010, Mark Borgerding. All rights reserved.
 *  SPDX-License-Identifier: BSD-3-Clause
 */
#ifndef _kiss_fft_guts_h
#define _kiss_fft_guts_h

#include "kiss_fft.h"
#include "kiss_fft_log.h"
#include <limits.h>

#define MAXFACTORS 32

struct kiss_fft_state {
    int nfft;
    int inverse;
    int factors[2 * MAXFACTORS];
    kiss_fft_cpx twiddles[1];
};

#define S_MUL(a,b)  ((a)*(b))
#define C_MUL(m,a,b) \
    do { (m).r = (a).r*(b).r - (a).i*(b).i; \
         (m).i = (a).r*(b).i + (a).i*(b).r; } while(0)
#define C_FIXDIV(c,div)  /* NOOP for float */
#define C_MULBYSCALAR(c,s) \
    do { (c).r *= (s); (c).i *= (s); } while(0)
#define C_ADD(res,a,b) \
    do { (res).r = (a).r+(b).r; (res).i = (a).i+(b).i; } while(0)
#define C_SUB(res,a,b) \
    do { (res).r = (a).r-(b).r; (res).i = (a).i-(b).i; } while(0)
#define C_ADDTO(res,a) \
    do { (res).r += (a).r; (res).i += (a).i; } while(0)
#define C_SUBFROM(res,a) \
    do { (res).r -= (a).r; (res).i -= (a).i; } while(0)
#define KISS_FFT_COS(phase) (kiss_fft_scalar)cos(phase)
#define KISS_FFT_SIN(phase) (kiss_fft_scalar)sin(phase)
#define HALF_OF(x) ((x)*((kiss_fft_scalar).5))
#define kf_cexp(x,phase) \
    do { (x)->r = KISS_FFT_COS(phase); (x)->i = KISS_FFT_SIN(phase); } while(0)
#define pcpx(c) KISS_FFT_DEBUG("%g + %gi\n",(double)((c)->r),(double)((c)->i))

#define KISS_FFT_TMP_ALLOC(nbytes) KISS_FFT_MALLOC(nbytes)
#define KISS_FFT_TMP_FREE(ptr)     KISS_FFT_FREE(ptr)

#endif
