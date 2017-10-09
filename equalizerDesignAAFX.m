function equalizerStr = equalizerDesignAAFX(cosineCoefficient,upperLimit,halfSample)
%   equalizerStr = equalizerDesignAAFX(cosineCoefficient,upperLimit)
%   cosineCoefficient   : [a0, a1, ... , ak] for example for Nuttallwin12
%                          [0.355768 0.487396 0.144232 0.012604]
%   upperLimit  : in dB for 85% flat range, 50 dB is for Nuttallwin12
%   halfSample  : in sample points. 80 sample is used for IEICE TR 2015
% with minimun phase window length adjustment

%   Designed and coded by Hideki Kawahara
%   05/July/2015

fs = 8000; % Any frequency is OK.
Tw = 4/(fs);
fftl = 32768;
fx = (0:fftl-1)'/fftl*fs;
omg = 2*pi*fx;
ak = cosineCoefficient;
hh = omg*0;
for ii = 1:length(ak)
    hh = hh+ak(ii)*(sin(omg*Tw+pi*(ii-1))./(omg*Tw+pi*(ii-1))+sin(omg*Tw-pi*(ii-1))./(omg*Tw-pi*(ii-1)));
end;
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
%-- output section
equalizerStr.response = eqqh/sum(eqqh);
equalizerStr.minimumPhaseResponse = mmResp;
equalizerStr.minimumPhaseResponseW = mmResp(1:hl2+1).*ww2(hl2+1:2*hl2+1);
equalizerStr.minimumPhaseResponseW = equalizerStr.minimumPhaseResponseW/sum(equalizerStr.minimumPhaseResponseW);
equalizerStr.antiCausalResp = equalizerStr.minimumPhaseResponseW(end:-1:1);
equalizerStr.timeIndex = -hl:hl;
equalizerStr.fAxis = fx(1:fftl/2+1)/fs;
equalizerStr.originalLPFGain = hh(1:fftl/2+1);
equalizerStr.fftl = fftl;


