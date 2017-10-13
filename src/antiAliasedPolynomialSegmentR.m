function output = antiAliasedPolynomialSegmentR(poly_coeff, tt, two)
% generate antialiased polynomial pulse using 6-term new window.
% output = antiAliasedPolynomialSegmentR(poly_coeff, tt, tw)
%
% Input argument
%   poly_coeff : vector consisting of polinomial coefficients
%                1st element corresponds to 0-th exponent coefficient
%   tt : discrete time axis, values are calculated using element of this
%        0 < t <= 1 is the support of the polynomial pulse
%   two : half length of the smoothing function. This routine uses
%        6-term new windowing function
%
% Output
%   output : antialiased polynomial pulse

% 17,18, 23, 25/Jan./2017 by Hideki Kawahara

%Copyright 2017 Hideki Kawahara
%
%Licensed under the Apache License, Version 2.0 (the "License");
%you may not use this file except in compliance with the License.
%You may obtain a copy of the License at
%
%    http://www.apache.org/licenses/LICENSE-2.0
%
%Unless required by applicable law or agreed to in writing, software
%distributed under the License is distributed on an "AS IS" BASIS,
%WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
%See the License for the specific language governing permissions and
%limitations under the License.

tw = two * 1.5; % 1.5 is scaling factor of 6-term new window
%hc = [0.338946 0.481973 0.161054 0.018027]; % Nuttall-11 coefficient
%hc = [0.355768 0.487396 0.144232 0.012604]; % Nuttall-12 coefficient
%hc = [0.3635819 0.4891775 0.1365995 0.0106411];% matlab nuttallwin
%hc = [20 30 12 2] / 64;
hc = [0.2625000000 0.4265625000 0.2250000000 0.0726562500 ...
  0.0125000000 0.0007812500];
m = length(hc) - 1;
hc = hc / (2 * tw * hc(1));
n = length(poly_coeff) - 1;

C = zeros(n + 1, m);
S = zeros(n + 1, m);
U = zeros(n + 1, 1 + n + 1);
V = zeros(n + 1, n + 1);

r = 0;
for k = 1:m
  C(r + 1, k) = 0;
  S(r + 1, k) = tw / (k * pi) * hc(k + 1);
end
U(r + 1, 1 + 1) = hc(1);
U(r + 1, 1) = - U(r + 1, 2:end) * ((-tw) .^ (1:n + 1)');
V(r + 1, 1) = 1;
for r = 1:n
  for k = 1:m
    C(r + 1, k) = -((r * tw) / (k * pi)) * S(r, k);
    S(r + 1, k) = ((r * tw) / (k * pi)) * C(r, k);
  end
  for k = 1:n + 1
    U(r + 1, k + 1) = (r / k) * U(r, k);
  end
  U(r + 1, 1) = -(U(r + 1, 2:end) * ((-tw) .^ (1:n + 1)') ...
    + C(r + 1, :) * ((-1) .^ (1:m)'));
  for k = 1:n
    V(r + 1, k + 1) = (r / k) * V(r, k);
  end
  V(r + 1, 1) = C(r + 1, :) * ((-1) .^ (1:m)') ...
    + U(r + 1, :) * ((tw) .^ (0:n + 1)') ...
    - V(r + 1, 2:end) * ((tw) .^ (1:n)');
end
B = zeros(n + 1, n + 1);
for ii = 1:n+1
  for jj = 1:ii
    nr = ii - 1;
    nk = jj - 1;
    B(ii, jj) = factorial(nr) / factorial(nk) / factorial(nr - nk);
  end
end
c0 = poly_coeff(:)'* C;
s0 = poly_coeff(:)'* S;
u0 = poly_coeff(:)'* U;
v = poly_coeff(:)'* V;
c1 = poly_coeff(:)'* B * C;
s1 = poly_coeff(:)'* B * S;
u1 = poly_coeff(:)'* B * U;

output = tt * 0;

tt1 = tt(tt > -tw & tt <= tw);
tt2 = tt(tt > tw & tt <= 1 - tw);
tt3 = tt(tt > 1 - tw & tt <= 1 + tw);
dt3 = tt(tt > 1 - tw & tt <= 1 + tw) - 1;
tt4 = tt(tt > tw & tt <= 1 + tw);

tm1 = tt1 .^ (0:n + 1);
tm2 = tt2 .^ (0:n + 1);
tm3 = tt3 .^ (0:n + 1);
dm3 = dt3 .^ (0:n + 1);
tm4 = tt4 .^ (0:n + 1);

tcs1 = tt1 * (1:m);
dcs3 = dt3 * (1:m);

g1 = cos(pi * tcs1 / tw) * c0' + sin(pi * tcs1 / tw) * s0' + tm1 * u0';
g2 = tm2(:, 1:n + 1) * v';
if tw > 1 - tw
  g3 = - (cos(pi * dcs3 / tw) * c1' + sin(pi * dcs3 / tw) * s1' + dm3 * u1');
else
  g3 = tm3(:, 1:n + 1) * v' - (cos(pi * dcs3 / tw) * c1' + sin(pi * dcs3 / tw) * s1' + dm3 * u1');
end
output(tt > -tw & tt <= tw) = output(tt > -tw & tt <= tw) + g1;
output(tt > tw & tt <= 1 - tw) = output(tt > tw & tt <= 1 - tw) + g2;
output(tt > 1 - tw & tt <= 1 + tw) = output(tt > 1 - tw & tt <= 1 + tw) + g3;
if tw > 1 - tw
  output(tt > tw & tt <= 1 + tw) = output(tt > tw & tt <= 1 + tw) + tm4(:, 1:n + 1) * v';
end
end
