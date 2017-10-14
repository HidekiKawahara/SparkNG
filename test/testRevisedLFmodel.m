%% Test revised version of the antialiased L-F (Fant and Liliencrants) model
% This is free to modify and use.
% 14/Oct./2017 by Hideki Kawahara

close all

%% Desing a time varying fo trajectory
% The fo value is set very high to illustrate antialiasing behavior clearly.

fs = 44100;
duration = 2;
tt = (0:1 / fs:duration)';
mean_fO = 887; % Hz
vibrato_f = 5.2;% Hz
vibrato_depth = 6;% cent for peak deviation

foi = 2.0 .^ (log2(mean_fO) + vibrato_depth / 1200 * sin(2 * pi * vibrato_f * tt + 0 * randn(length(tt), 1)));
%% Set L-F model parameters

% This is a modal parameter set
tp = 0.4134;
te = 0.5530;
ta = 0.0041;
tc = 0.5817;

%% Generate L-F model output 

output = AAFLFmodelFromF0Trajectory6T(foi,tt,fs,tp,te,ta,tc);

%% Display waveforms of the direct digitization, antialiasing only and
% antialiasing followed by equalizaiton

y = output.antiAliasedSignal;
y_only = output.antiAliasedOnly;
y_direct = output.LFmodelOut;
figure;
plot((0:length(y) - 1) / fs, y_direct, 'c', 'linewidth', 5);
hold all
plot((0:length(y) - 1) / fs, y_only, 'r', 'linewidth', 2);
plot((0:length(y) - 1) / fs, y, 'k');
grid on;
set(gca, 'fontsize', 15, 'fontname', 'Helvetica');
xlabel('time (s)');
axis([[0.5 2.5] / 1000 -1 0.3])
legend('direct', 'antialias only', 'a.a. with eq', 'location', 'southwest');

%% This also illustates how to use stftSpectrogramStructure

window_length_ms = 40;
window_shift_ms = 2;
window_f = 'nuttallwin12self'; % self convolution of Nuttall's 12-th item
sgramStrY = ...
  stftSpectrogramStructure(y, fs, window_length_ms, window_shift_ms, window_f);
sgramStrD = ...
  stftSpectrogramStructure(y_direct, fs, window_length_ms, window_shift_ms, window_f);
sgramStrO = ...
  stftSpectrogramStructure(y_only, fs, window_length_ms, window_shift_ms, window_f);
%% Selecing spectrum slice

pw_antWithEq = 10*log10(mean(sgramStrY.rawSpectrogram(:, 210:230), 2));
pw_direct = 10*log10(mean(sgramStrD.rawSpectrogram(:, 210:230), 2));
pw_only = 10*log10(mean(sgramStrO.rawSpectrogram(:, 210:230), 2));
%%

figure;
plot(sgramStrY.frequencyAxis, pw_direct - max(pw_direct), 'g', ...
  'linewidth', 2);
grid on;
hold all
plot(sgramStrY.frequencyAxis, pw_only - max(pw_only), 'r', 'linewidth', 2);
plot(sgramStrY.frequencyAxis, pw_antWithEq - max(pw_antWithEq), 'k',  ...
  'linewidth', 4);
set(gca, 'fontsize', 15, 'fontname', 'Helvetica', 'linewidth', 2);
axis([0 fs/2 -180 18]);
ylabel('leval (dB)');
xlabel('frequency (Hz)');
legend('direct', 'antialiasing only', 'antialiasing with eq', 'location', 'northeast');
%print -depsc aaLFforIS.eps

%%
sgram_6term = 10 * log10(sgramStrY.rawSpectrogram(:, 100:900));
sgram_6term = sgram_6term - max(sgram_6term);
sgram_only = 10 * log10(sgramStrO.rawSpectrogram(:, 100:900));
sgram_only = sgram_only - max(sgram_only);
sgram_direct = 10 * log10(sgramStrD.rawSpectrogram(:, 100:900));
sgram_direct = sgram_direct - max(sgram_direct);
tt = sgramStrY.temporalPositions;
figure;imagesc(tt([100 900]),[0 fs/2], sgram_6term);
set(gca, 'clim', [-140 0])
axis('xy');
set(gca, 'fontsize', 15, 'fontname', 'Helvetica');
xlabel('time (s)');
ylabel('frequency (Hz)');
colorbar
title('antialiasing with equalization');
%print -depsc aaLFmodelRevSgramIS.eps
figure;imagesc(tt([100 900]),[0 fs/2], sgram_only);
set(gca, 'clim', [-140 0])
axis('xy');
set(gca, 'fontsize', 15, 'fontname', 'Helvetica');
xlabel('time (s)');
ylabel('frequency (Hz)');
colorbar
title('Antialiasing only');
%print -depsc aaLFmodelOldSgramIS.eps
figure;imagesc(tt([100 900]),[0 fs/2], sgram_direct);
set(gca, 'clim', [-140 0])
axis('xy');
set(gca, 'fontsize', 15, 'fontname', 'Helvetica');
xlabel('time (s)');
ylabel('frequency (Hz)');
colorbar
title('direct');
%print -depsc aaLFmodelDirectSgramIS.eps

