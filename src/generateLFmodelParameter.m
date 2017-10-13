function output = generateLFmodelParameter(tp, te, ta, tc)
% output = generateLFmodelParameter(tp, te, ta, tc)
% generate L-F model coefficients from time parameters
%
% Argument
%   tp, te, ta, tc : L-F model time parameters
%
% Output
%   output : structure with the following fields
%     omegaG, betaa, alphaa : L-F model coefficients
%     tp, te, ta, tc : L-F model time parameters (copy of input)

% by Hideki Kawahara : kawahara@sys.wakayama-u.ac.jp

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

fg = 1 / (2 * tp);
omegaG = 2 * pi * fg;
%--- design exponential decay
myfun = @(x, ta, te) (ta * x - 1 + exp(-x * (tc - te)));
fun = @(x) myfun(x, ta, te);
betaa = fzero(fun,1 / ta);
output.omegaG = omegaG;
output.betaa = betaa;
%--- design ramped sinusoid
myfun2 = @(x, ta, te, tc, omegaG, betaa)(-(x * sin(omegaG * te) ...
  - omegaG * cos(omegaG * te) + exp(-x * te) * omegaG) ...
  / (x^2 + omegaG^2) / sin(omegaG * te) ...
  + ((tc - te) * exp(-betaa * (tc - te)) - ta) / (betaa * ta));
fun2 = @(x) myfun2(x, ta, te, tc, omegaG, betaa);
alphaa = fzero(fun2, 2);
output.alphaa = alphaa;
output.te = te;
output.tp = tp;
output.ta = ta;
output.tc = tc;
end