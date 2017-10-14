function outStr = AAFLFmodelFromF0Trajectory6T(f0In,timeAxis,fs,tp,te,ta,tc,varargin)
% outStr = AAFLFmodelFromF0Trajectory6T(f0In,timeAxis,fs,tp,te,ta,tc)
% Generate antialiased L-F model output using the input F0 trajectory
% revised antialiasing with 6-term cosine series and IIR equalizer
%
% Arguments
%   f0In : fundamental frequency trajetory (Hz)
%   timeAxis : time axis on which the f0 trajectory is defined. (s)
%   tp,te,ta,tc are L-F model parameters
%
% Output
%   outStr : structure with the following fields
%     antiAliasedSignal : antialiased excitation source with equalization
%     antiAliasedOnly : antialiased excitation source without equalization
%     LFmodelOut : direct discretization of the L-F model output
%     LFvolumeVelocity : volume velocity without antialiasing
%     samplingFrequency : sampling frequency (Hz)
%     f0Interpolated : F0 trajectory at audio rate (Hz)
%     temporalPosition : time axis at audio rate (s)
%     startPointList : sample index list of each pitch cycle
%     pvPhase : phase represented in principal value
%     elapsedTime : elapsed time for processing

%   12/Dec./2015 added jitter and shimmer
%   15/Dec./2015 randamization type updated
%   21/Feb./2017
% copyright Hideki Kawahara 21/Feb./2017 

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

startTime = tic;
nVarargin = length(varargin);
jitterSD = 0;
shimmerSD = 0;
perturbation = 'gaussian';
if ~isempty(varargin)
  switch nVarargin
    case 1
      jitterSD = varargin{1};
    case 2
      jitterSD = varargin{1};
      shimmerSD = varargin{2};
    case 3
      jitterSD = varargin{1};
      shimmerSD = varargin{2};
      perturbation = varargin{3};
  end
end
tt = (timeAxis(1):1 / fs:timeAxis(end))';
f0 = exp(interp1(timeAxis, log(f0In), tt, 'linear', 'extrap'));
theta = cumsum(2 * pi * f0 .* ones(length(tt), 1) / fs);

pvPhase = angle(exp(1i * theta));
indexList = 1:length(theta)-1;
startPointList = indexList(diff(pvPhase)<-5);

lastPoint = 1;
outSignal = tt * 0;
directOut = tt * 0;
directVV = tt * 0;
nyqFreq = fs / 2;
for ii = 1:length(startPointList) - 2
  segment = [pvPhase(lastPoint + 1:startPointList(ii)) - 2 * pi; ...
    pvPhase(startPointList(ii) + 1:startPointList(ii + 1));
    pvPhase(startPointList(ii + 1) + 1:startPointList(ii + 2)) + 2 * pi] + pi;
  normalizedTime = segment / 2 / pi + jitterSD * perturbationFunction(perturbation);
  averageF0 = mean(f0(startPointList(ii) + 1:startPointList(ii + 1)));
  Tw = 2 / nyqFreq;
  Tworg = Tw * averageF0;
  modelOut = sourceByLFmodelAAF6T(normalizedTime, tp, te, ta, tc, Tworg);
  outSignal(lastPoint+1:startPointList(ii + 2)) = ...
    outSignal(lastPoint+1:startPointList(ii + 2)) + ...
    modelOut.antiAliasedSource * ...
    (1 + shimmerSD*perturbationFunction2(perturbation));
  directOut(lastPoint + 1:startPointList(ii + 2)) = ...
    directOut(lastPoint + 1:startPointList(ii + 2)) + modelOut.source;
  directVV(lastPoint + 1:startPointList(ii + 2)) = ...
    directVV(lastPoint + 1:startPointList(ii + 2)) + modelOut.volumeVerocity;
  lastPoint = startPointList(ii);
end
%% Equalizer
hc = [0.2624710164 0.4265335164 0.2250165621 0.0726831633 0.0125124215 0.0007833203];
equalizerStr = equalizerDesignAAFX(hc, 68, 80, 1.5);
a = equalizerStr.iirCoefficient;
yfix = filter(sum(a) * [0 0 1], a, outSignal);

%%
outStr.antiAliasedSignal = yfix;
outStr.antiAliasedOnly = outSignal;
outStr.LFmodelOut = directOut;
outStr.LFvolumeVelocity = directVV;
outStr.samplingFrequency = fs;
outStr.f0Interpolated = f0;
outStr.temporalPosition = tt;
outStr.startPointList = startPointList;
outStr.pvPhase = pvPhase;
outStr.elapsedTime = toc(startTime);
end



