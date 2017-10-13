function output = generateAALFmodelOut(timeAxis, modelParameter, two)
% output = generateAALFmodelOut(timeAxis, modelParameter, two)
% Generate one cycle of antialiased L-F model output
% antialiasing uses 6-term cosine series
%
% Argument
%   timeAxis : normalized time axis (normalized time: T0 = 1)
%   modelParameter : structure with the following fields
%     tp, te, ta, tc : F-L model parameters
%   two : nominal half length of the antialiasing function 
%
% Output
%   output : structure witht the following fields
%     antiAliasedSource : antialiased L-F model output (no equalization)
%     source : direct discretization of L-F model output
%     volumeVerocity : volume velocity (no equalization)

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

margin = two * 2;
te = modelParameter.te;
ta = modelParameter.ta;
tc = modelParameter.tc;
seg1 = timeAxis(timeAxis > 0 & timeAxis < modelParameter.te);
seg2 = timeAxis(timeAxis >= modelParameter.te & ...
  modelParameter.tc > timeAxis);
source = timeAxis * 0;
antialiasedSignal = timeAxis * 0;
cf = - exp(- modelParameter.alphaa * modelParameter.te) / ...
  sin(modelParameter.omegaG * modelParameter.te);
opening = cf * exp(modelParameter.alphaa * seg1) .* ...
  sin(modelParameter.omegaG * seg1);
source(timeAxis > 0 & timeAxis < modelParameter.te) = opening;
closing = -1 / (modelParameter.betaa * modelParameter.ta) * ...
  (exp(-modelParameter.betaa * (seg2 - modelParameter.te)) ...
  - exp(-modelParameter.betaa * (modelParameter.tc - modelParameter.te)));
source(timeAxis >= modelParameter.te & modelParameter.tc > timeAxis) = ...
  closing;
%---- Ug
vv = timeAxis * 0;
openVV = -(modelParameter.alphaa * sin(modelParameter.omegaG * seg1) ...
  - modelParameter.omegaG * cos(modelParameter.omegaG * seg1) ...
  + modelParameter.omegaG * exp(-modelParameter.alphaa * seg1)) ...
  / (modelParameter.alphaa^2 + modelParameter.omegaG^2) / sin(modelParameter.omegaG * te);
boundaryVV = -(modelParameter.alphaa * sin(modelParameter.omegaG * te) ...
  - modelParameter.omegaG * cos(modelParameter.omegaG * te) ...
  + modelParameter.omegaG * exp(-modelParameter.alphaa * te)) ...
  / (modelParameter.alphaa^2 + modelParameter.omegaG^2) / sin(modelParameter.omegaG * te);
closeVV = ((seg2 - te) * exp(-modelParameter.betaa * (tc - te))) / modelParameter.betaa / ta ...
  + (exp(-modelParameter.betaa * (seg2 - te)) - 1) / modelParameter.betaa^2 / ta;
vv(timeAxis > 0 & timeAxis < modelParameter.te) = openVV;
vv(timeAxis >= modelParameter.te & modelParameter.tc > timeAxis) = ...
  closeVV + boundaryVV;
%----
select1 = timeAxis > - margin & timeAxis < modelParameter.te + margin;
select2 = timeAxis >= modelParameter.te - margin & ...
  modelParameter.tc + margin > timeAxis;
exSeg1 = timeAxis(select1);
exSeg2 = timeAxis(select2);
piece1 = exSeg1 / modelParameter.te;
piece2 = (exSeg2 - modelParameter.te) ...
  / (modelParameter.tc - modelParameter.te);
tw1 = two / modelParameter.te;
tw2 = two / (modelParameter.tc - modelParameter.te);
beta1 = (modelParameter.alphaa + 1i * modelParameter.omegaG) * modelParameter.te;
out1 = cf * imag(antiAliasedCExponentialSegment(beta1, piece1, tw1));
beta2 = -modelParameter.betaa * (modelParameter.tc - modelParameter.te);
tmp1 = real(antiAliasedCExponentialSegment(beta2, piece2, tw2));
tmp2 = antiAliasedPolynomialSegmentR([1 0], piece2, tw2);
out2 = -tmp1 / (modelParameter.betaa * modelParameter.ta); 
out3 = exp(-modelParameter.betaa * (modelParameter.tc - modelParameter.te)) ...
  * tmp2(:) / (modelParameter.betaa * modelParameter.ta);
antialiasedSignal(select1) = antialiasedSignal(select1) + out1;
antialiasedSignal(select2) = antialiasedSignal(select2) + out2 + out3;
output.source = source;
output.antialiasedSignal = antialiasedSignal;
output.volumeVerocity = vv;
end