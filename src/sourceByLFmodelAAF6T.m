function modelOut = sourceByLFmodelAAF6T(timeAxis, tp, te, ta, tc, Tworg)
% modelOut = sourceByLFmodelAAF6T(timeAxis, tp, te, ta, tc, Tworg)
% Generate one cycle of antialiased L-F model output
% antialiasing uses 6-term cosine series
%
% Argument
%   timeAxis : normalized time axis (normalized time: T0 = 1)
%   tp, te, ta, tc : F-L model parameters
%   Tworg : nominal half length of the antialiasing function 
%
% Output
%   modelOut : structure witht the following fields
%     antiAliasedSource : antialiased L-F model output (no equalization)
%     source : direct discretization of L-F model output
%     volumeVerocity : volume velocity (no equalization)

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
     
modelParameter = generateLFmodelParameter(tp, te, ta, tc);
output = generateAALFmodelOut(timeAxis, modelParameter, Tworg);
modelOut.antiAliasedSource = output.antialiasedSignal;
modelOut.source = output.source;
modelOut.volumeVerocity = output.volumeVerocity;
end