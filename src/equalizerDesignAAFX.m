function equalizerStr = equalizerDesignAAFX(cosineCoefficient,upperLimit,halfSample,scale)
%   equalizerStr = equalizerDesignAAFX(cosineCoefficient,upperLimit, halfSample)
%   cosineCoefficient   : [a0, a1, ... , ak] for example for Nuttallwin12
%                          [0.355768 0.487396 0.144232 0.012604]
%   upperLimit  : in dB for 85% flat range, 50 dB is for Nuttallwin12
%   halfSample  : in sample points. 80 sample is used for IEICE TR 2015
%   scale : first zero frequency (Nuttall-11 is one)
% with minimun phase window length adjustment

%   Designed and coded by Hideki Kawahara
%   05/July/2015
%   22/Jan./2017 fixed fragility
%   23/Jan./2017 IIR filter implementation
%   11/Jan./2017 revised for new implementation

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

fs = 8000; % Any frequency is OK.
Tw = 4/(fs);
fftl = 32768;
fx = (0:fftl-1)'/fftl*fs;
fx(fx > fs / 2) = fx(fx > fs / 2) - fs;
omg = 2*pi*fx * scale;
ak = cosineCoefficient;
epss = 10 ^ (-13); % safeguard
h_denom1 = omg * (Tw * ones(1, length(ak))) + pi * ones(length(omg), 1) * (0:length(ak) - 1);
h_denom2 = omg * (Tw * ones(1, length(ak))) - pi * ones(length(omg), 1) * (0:length(ak) - 1);
h1 = sin(h_denom1) ./ h_denom1;
h2 = sin(h_denom2) ./ h_denom2;
h1(abs(h_denom1) < epss) = 1;
h2(abs(h_denom2) < epss) = 1;
hh = (h1 + h2) * ak(:);
hh = hh/2/ak(1);
hh(1) = 1;
%--- clean up hh --
for ii = 2:length(hh)-1
    if isnan(hh(ii))
        hh(ii) = (hh(ii-1)+hh(ii+1))/2;
    end;
end;
%--- equalizer design
hhdd = hh;
hhdd(end:-1:fftl/2+1) = hh(2:fftl/2+1);
gg = min(10^(upperLimit/20),1.0./hhdd);

%-- linear phase FIR equalizer
hl = halfSample;
ww = nuttallwin12(2*hl+1);
ihh = fftshift(real(ifft(gg)));

eqqh = ihh(fftl/2+(-hl:hl)+1).*ww;
%-- minimum phase response
cepstrum = ifft(log(gg));
comlexCepstrum = cepstrum;
comlexCepstrum(2:fftl/2) = cepstrum(2:fftl/2)*2;
comlexCepstrum(fftl/2+1:end) = 0;
mmResp = real(ifft(exp(fft(comlexCepstrum))));
hl2 = round(hl*1.36);
ww2 = nuttallwin12(2*hl2+1);
%-- IIR filter design
eqpw = abs(fft(eqqh/sum(eqqh), fftl)).^2;
eqac = real(ifft(eqpw));
r = eqac(1:7) / eqac(1);
a = levinson(r);
%-- output section
equalizerStr.response = eqqh/sum(eqqh);
equalizerStr.iirCoefficient = a;
equalizerStr.minimumPhaseResponse = mmResp;
equalizerStr.minimumPhaseResponseW = mmResp(1:hl2+1).*ww2(hl2+1:2*hl2+1);
equalizerStr.minimumPhaseResponseW = equalizerStr.minimumPhaseResponseW/sum(equalizerStr.minimumPhaseResponseW);
equalizerStr.antiCausalResp = equalizerStr.minimumPhaseResponseW(end:-1:1);
equalizerStr.timeIndex = -hl:hl;
equalizerStr.fAxis = fx(1:fftl/2+1)/fs;
equalizerStr.originalLPFGain = hh(1:fftl/2+1);
equalizerStr.fftl = fftl;
end



