function output = antialiasedFLmodelSingleR(phase_i, A, B, C, R, F, D, fs, mean_fO)
% generate single cycle of Fujisaki-Ljungqvist glottal source model with
% anti-aliasing in the continuous time domain.
% output = antialiasedFLmodelSingleR(phase_i, A, B, C, R, F, D, fs, mean_fO)
%
% Input argument
%   phase_i : discrete cumulative phase sequence of FO component (radian)
%   A, B, C, R, F, D : Parameter of the F-L model. (T=1 is assumed.)
%   fs : sampling frequency (Hz)
%   mean_fO : representative fundamental frequency of this cycle (Hz)
%             This is used for desingning the anti-aliasing response
%
% Output
%   output : structure with the following fields
%     g : generated L-F model signal defined on phase_i locations
%     segment_1, 2, 3, 4 : constituent polynomial pulse of each segment
%     index_1, 2, 3, 4 : index where each segment values are added

% 18/Jan./2017 by Hideki Kawahara
% 11/Feb./2017 new antialiasing function

W = (R + F);
S = (R + F) / (R - F);
T = 1;
alphaa = (4 * A * R + 6 * F * B) / (2 * R^2 - F^2); % 26/Sept./2017 fix
betaa = (C * D) / (D - 3 * (T - W));

poly1 = [A, - (2 * A + R * alphaa) / R, (A + R * alphaa) / R^2]';
poly2 = [0, alphaa, (3 * B - 2 * F * alphaa) / (F^2), ...
  - (2 * B - F * alphaa) / (F^3)]';
poly3 = [C, -2 * (C - betaa) / D, (C - betaa) / D^2]';
poly4 = [betaa, 0]';

t = phase_i / 2 / pi;
d_t = 1 / fs * mean_fO;
g = phase_i(:) * 0;
margin_p = 8 * d_t;
index_v = (1:length(phase_i))';
seg1 = t(-margin_p < t & t <= R + margin_p) / R;
idx1 = index_v(-margin_p < t & t <= R + margin_p);
tw = 4 * d_t / R;
output1 = antiAliasedPolynomialSegmentR(poly1 .* [1, R, R^2]', seg1, tw);
g(idx1) = g(idx1) + output1;
seg2 = (t(R - margin_p < t & t <= W + margin_p) - R) / F;
idx2 = index_v(R - margin_p < t & t <= W + margin_p);
tw = 4 * d_t / F;
output2 = antiAliasedPolynomialSegmentR(poly2 .* [1, F, F^2, F^3]', seg2, tw);
g(idx2) = g(idx2) + output2;
seg3 = (t(W - margin_p < t & t <= W + D + margin_p) - W) / D;
idx3 = index_v(W - margin_p < t & t <= W + D + margin_p);
tw = 4 * d_t / D;
output3 = antiAliasedPolynomialSegmentR(poly3 .* [1, D, D^2]', seg3, tw);
g(idx3) = g(idx3) + output3;
seg4 = (t(W + D - margin_p < t & t <= 1 + margin_p) - D - W) / (1 - D - W);
idx4 = index_v(W + D - margin_p < t & t <= 1 + margin_p);
tw = 4 * d_t / (1 - D - W);
output4 = antiAliasedPolynomialSegmentR(poly4 .* [1, D]', seg4, tw);
g(idx4) = g(idx4) + output4;
output.g = g;
output.segment_1 = output1;
output.index_1 = idx1;
output.segment_2 = output2;
output.index_2 = idx2;
output.segment_3 = output3;
output.index_3 = idx3;
output.segment_4 = output4;
output.index_4 = idx4;
output.totalFlow = sum(cumsum(g(t > 0 & t < 1))) / sum(t > 0 & t < 1);
end