%% Test revised AA Fujisaki-Ljungqvist model simple function
% This is free to modify and use.
% 24, 25/Jan./2017 by Hideki Kawahara
% 20/Feb./2017

clear all
close all
%%
fs = 44100;
duration = 2;
tt = (0:1 / fs:duration)';
mean_fO = 220; % Hz
mean_fO = 880; % Hz
mean_fO = 887; % Hz
vibrato_f = 5.2;% Hz
vibrato_depth = 6;% cent for peak deviation

fOi = 2.0 .^ (log2(mean_fO) + vibrato_depth / 1200 * sin(2 * pi * vibrato_f * tt + 0 * randn(length(tt), 1)));
%%
R = 0.48;
F = 0.15;
D = 0.12;

A = 0.2;
B = -1;
C = -0.6;

%% Temporally static F-L model parameter

output_const = AAFjLjmodelFromFOTrajectoryR(fOi, fs, A, B, C, R, F, D);
output_nutl = AAFjLjmodelFromFOTrajectory(fOi, fs, A, B, C, R, F, D);

%%
y = output_const.antiAliasedSignal;
figure;
plot((0:length(y) - 1) / fs, y);
grid on;
set(gca, 'fontsize', 15, 'fontname', 'Helvetica');
xlabel('time (s)');

%%
y_direct = output_const.rawSignal;
y_nuttall = output_nutl.antiAliasedSignal;
sgramStrY = stftSpectrogramStructure(y,fs,40,2,'nuttallwin12self');
sgramStrD = stftSpectrogramStructure(y_direct,fs,40,2,'nuttallwin12self');
sgramStrN = stftSpectrogramStructure(y_nuttall,fs,40,2,'nuttallwin12self');
%%
pw_antWithEq = 10*log10(mean(sgramStrY.rawSpectrogram(:, 210:230), 2));
pw_direct = 10*log10(mean(sgramStrD.rawSpectrogram(:, 210:230), 2));
pw_nuttall = 10*log10(mean(sgramStrN.rawSpectrogram(:, 210:230), 2));
%%
figure;
plot(sgramStrY.frequencyAxis, pw_direct - max(pw_direct), 'g', ...
  'linewidth', 2);
grid on;
hold all
plot(sgramStrY.frequencyAxis, pw_nuttall - max(pw_nuttall), 'r', 'linewidth', 2);
plot(sgramStrY.frequencyAxis, pw_antWithEq - max(pw_antWithEq), 'k',  ...
  'linewidth', 4);
set(gca, 'fontsize', 15, 'fontname', 'Helvetica', 'linewidth', 2);
axis([0 fs/2 -180 5]);
ylabel('leval (dB)');
xlabel('frequency (Hz)');
legend('direct', 'Nuttall-11', '6-term proposed', 'location', 'northeast');
print -depsc aaFLforIS.eps

%%
sgram_6term = 10 * log10(sgramStrY.rawSpectrogram(:, 100:900));
sgram_6term = max(-140, sgram_6term - max(sgram_6term));
sgram_prev = 10 * log10(sgramStrN.rawSpectrogram(:, 100:900));
sgram_prev = max(-140, sgram_prev - max(sgram_prev));
sgram_direct = 10 * log10(sgramStrD.rawSpectrogram(:, 100:900));
sgram_direct = max(-140, sgram_direct - max(sgram_direct));
tt = sgramStrY.temporalPositions;
figure;imagesc(tt([100 900]),[0 fs/2], sgram_6term);
axis('xy');
set(gca, 'fontsize', 15, 'fontname', 'Helvetica');
xlabel('time (s)');
ylabel('frequency (Hz)');
colorbar
title('6-term proposed');
print -depsc aaFLmodelRevSgramIS.eps
figure;imagesc(tt([100 900]),[0 fs/2], sgram_prev);
axis('xy');
set(gca, 'fontsize', 15, 'fontname', 'Helvetica');
xlabel('time (s)');
ylabel('frequency (Hz)');
colorbar
title('Nuttall-11');
print -depsc aaFLmodelOldSgramIS.eps
figure;imagesc(tt([100 900]),[0 fs/2], sgram_direct);
axis('xy');
set(gca, 'fontsize', 15, 'fontname', 'Helvetica');
xlabel('time (s)');
ylabel('frequency (Hz)');
colorbar
title('direct');
print -depsc aaFLmodelDirectSgramIS.eps



