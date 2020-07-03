/*
 * Copyright 2020 Paul Scherrer Institute
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

#ifndef _XRAY_H
#define _XRAY_H

#include "JFApp.h"

// Lab is in mm
// TODO: Ensure signs are OK
inline void detector_to_lab(float x, float y, float lab[3]) {
    float x_with_gaps = x + int(x/1030) * VERTICAL_GAP_PIXELS;
    float y_with_gaps = y + int(y/514) * HORIZONTAL_GAP_PIXELS;
    float x_beam_coord = x_with_gaps - experiment_settings.beam_x;
    float y_beam_coord = y_with_gaps - experiment_settings.beam_y;
    lab[0] = x_beam_coord * PIXEL_SIZE_IN_MM;
    lab[1] = y_beam_coord * PIXEL_SIZE_IN_MM;
    lab[2] = experiment_settings.detector_distance;
}

// For the time being, code below assumes "standard" diffraction geometry
// While capturing most of the cases, this will also optimize execution time
// Assume S0 = {0, 0, 1/lambda}, d1 = {1, 0, 0}, d2 = {0, 1, 0}, d3 = {0, 0, 1}
// see Kabsch, Acta Cryst D66, 133-144
// one_over_wavelength is expressed in A^-1
inline void lab_to_reciprocal(float p[3], float lab[3], float one_over_wavelength) {
    // [mm^-1] - this terms makes lab / one_over_norm_factor dimensionless and ensures norm == 1
    float one_over_norm_factor = 1.0/sqrt(lab[0]*lab[0] + lab[1]*lab[1] + lab[2]*lab[2]);
//    float one_over_wavelength = experiment_settings.energy_in_keV / 12.398; [A^-1]

    p[0] = lab[0] * one_over_wavelength * one_over_norm_factor;
    p[1] = lab[1] * one_over_wavelength * one_over_norm_factor;
    p[2] = (lab[2] * one_over_norm_factor - 1) * one_over_wavelength ;
}

// Assume m2 = {0, 1, 0}
// The function moves p back into origin of rotation
inline void reciprocal_rotate(float p0[3], float p[3], float omega_in_radian) {
    p0[0] = cos(omega_in_radian) * p[0] - sin(omega_in_radian) * p[2];
    p0[1] = p[1];
    p0[2] = sin(omega_in_radian) * p[0] + cos(omega_in_radian) * p[2];
}

inline float get_resolution(float lab[3]) {
    float wavelength =  WVL_1A_IN_KEV / (experiment_settings.energy_in_keV);
    // Assumes planar detector, 90 deg towards beam
    float beam_path = sqrt(lab[0]*lab[0] + lab[1]*lab[1] + lab[2]*lab[2]);

    // It is possible that beam center is directly on edge, so in this case a very small number (1 micron) is added to beam_path
    // to avoid division by zero
    if (lab[2] == beam_path) beam_path += 1e-3;
    float cos_2theta = lab[2] / beam_path;
    // cos(2theta) = cos(theta)^2 - sin(theta)^2
    // cos(2theta) = 1 - 2*sin(theta)^2
    // Technically two solutions for two theta, but it makes sense only to take positive one in this case
    float sin_theta = sqrt((1-cos_2theta)/2);
    return wavelength / (2*sin_theta);
}

inline float get_resolution_top() {
    float lab[3];
    lab[0] = 0.0f;
    lab[1] = -experiment_settings.beam_y * PIXEL_SIZE_IN_MM;
    lab[2] = experiment_settings.detector_distance;
    return get_resolution(lab);
}

inline float get_resolution_bottom() {
    float lab[3];
    lab[0] = 0.0f;
    lab[1] = ((NMODULES*NCARDS/2) * 514 + (NMODULES*NCARDS/2-1) * HORIZONTAL_GAP_PIXELS - experiment_settings.beam_y) * PIXEL_SIZE_IN_MM;
    lab[2] = experiment_settings.detector_distance;
    return get_resolution(lab);
}

inline float get_resolution_left() {
    float lab[3];
    lab[0] = -experiment_settings.beam_x * PIXEL_SIZE_IN_MM;
    lab[1] = 0.0f;   
    lab[2] = experiment_settings.detector_distance;
    return get_resolution(lab);
}

inline float get_resolution_right() {
    float lab[3];
    lab[0] = (2 * 1030 + VERTICAL_GAP_PIXELS - experiment_settings.beam_x) * PIXEL_SIZE_IN_MM;
    lab[1] = 0.0f;   
    lab[2] = experiment_settings.detector_distance;
    return get_resolution(lab);
}

#endif
