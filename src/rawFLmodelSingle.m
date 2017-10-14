function output = rawFLmodelSingle(phase_i, A, B, C, R, F, D)
% generate single cycle of Fujisaki-Ljungqvist glottal source model without
% anti-aliasing in the continuous time domain.
% output = rawFLmodelSingle(phase_i, A, B, C, R, F, D)
%
% Input argument
%   phase_i : discrete cumulative phase sequence of FO component (radian)
%   A, B, C, R, F, D : Parameter of the F-L model. (T=1 is assumed.)
%
% Output
%   output : structure with the following fields
%     g : generated L-F model signal defined on phase_i locations
%     segment_1, 2, 3, 4 : constituent polynomial pulse of each segment
%     index_1, 2, 3, 4 : index where each segment values are added

% 19/Jan./2017 by Hideki Kawahara
% 26/Sept./2017 bug fixed by Hideki Kawahara
% This is free to modify and use.

W = (R + F);
T = 1;
alphaa = (4 * A * R + 6 * F * B) / (2 * R^2 - F^2); % fix 26/Sept./2017
betaa = (C * D) / (D - 3 * (T - W));

poly1 = [A, - (2 * A + R * alphaa) / R, (A + R * alphaa) / R^2]';
poly2 = [0, alphaa, (3 * B - 2 * F * alphaa) / (F^2), ...
  - (2 * B - F * alphaa) / (F^3)]';
poly3 = [C, -2 * (C - betaa) / D, (C - betaa) / D^2]';
poly4 = [betaa, 0]';

t = phase_i / 2 / pi;
g = phase_i(:) * 0;
index_v = (1:length(phase_i))';
seg1 = t(0 <= t & t <= R);
idx1 = index_v(0 <= t & t <= R);
g(idx1) = g(idx1) + (seg1 .^ (0:2)) * poly1;
seg2 = t(R < t & t <= W);
idx2 = index_v(R < t & t <= W);
g(idx2) = g(idx2) + ((seg2 - R) .^ (0:3)) * poly2;
seg3 = t(W < t & t <= W + D);
idx3 = index_v(W < t & t <= W + D);
g(idx3) = g(idx3) + ((seg3 - W) .^ (0:2)) * poly3;
seg4 = t(W + D < t & t <= 1);
idx4 = index_v(W + D < t & t <= 1);
g(idx4) = g(idx4) + ((seg4 - W - D) .^ (0:1)) * poly4;
output.g = g;
output.segment_1 = (seg1 .^ (0:2)) * poly1;
output.index_1 = idx1;
output.segment_2 = ((seg2 - R) .^ (0:3)) * poly2;
output.index_2 = idx2;
output.segment_3 = ((seg3 - W) .^ (0:2)) * poly3;
output.index_3 = idx3;
output.segment_4 = ((seg4 - W - D) .^ (0:1)) * poly4;
output.index_4 = idx4;
output.alpha = alphaa;
output.beta = betaa;
end