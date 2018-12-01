function output = designCos6Wavelet(fs, fl, fh, fftl, mag, channels_oct)
input_parameters.sampling_frequency = fs;
input_parameters.lower_frequency = fl;
input_parameters.higher_frequency = fh;
input_parameters.fft_length = fftl;
input_parameters.stretching_factor = mag;
input_parameters.channels_per_octave = channels_oct;
fx = (0:fftl-1)/fftl*fs;
fc_list = fl * 2.0 .^ (0:1/channels_oct:log2(fh/fl));
fx(fx > fs / 2) = fx(fx > fs / 2) - fs;
ak = [0.2624710164;0.4265335164;0.2250165621;0.0726831633;0.0125124215;0.0007833203];
wvlt = struct;
for ii = 1:length(fc_list)
  fc = fc_list(ii);
  n_to = round(mag * 3 * fs / fc);
  tx_we = (-n_to:n_to)'/ n_to;
  tx = (-n_to:n_to)'/ fs;
  we = cos(tx_we * [0 1 2 3 4 5] * pi) * ak;
  wr = we .* cos(2 * pi * tx * fc);
  wi = we .* sin(2 * pi * tx * fc);
  wvlt(ii).w = (wr+1i*wi)/sum(we);
  wvlt(ii).bias = n_to;
  wvlt(ii).t_axis = tx;
end
wcmp = wvlt(1).w * 0;
centerIdx = wvlt(1).bias + 1;
for ii = 1:length(wvlt)
  tmpIdx = -wvlt(ii).bias:wvlt(ii).bias;
  wcmp(centerIdx + tmpIdx) = wcmp(centerIdx + tmpIdx) + wvlt(ii).w;
end
%--- calibration for linear phase filter
x1khz = exp(1i * 2 * pi * 1000 * (1:fs)' / fs);
y1khz = fftfilt(wcmp, x1khz);
cf = mean(abs(y1khz(3 * centerIdx:end - 3 * centerIdx)));
wcmp = wcmp / cf;
w_gain = 20*log10(abs(fft(wcmp, fftl)));
%---
output.input_parameters = input_parameters;
output.fc_list = fc_list;
output.centerIdx = wvlt(1).bias + 1;
output.f_axis = fx;
output.response = wcmp;
output.gain = w_gain;
output.wvlt = wvlt;
end