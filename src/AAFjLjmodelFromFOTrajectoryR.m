function output = AAFjLjmodelFromFOTrajectoryR(fOi, fs, A, B, C, R, F, D)
% Generate similar shape F-L source signal useg given fO trajectory
%  output = AAFjLjmodelFromFOTrajectory(fOi, fs, A, B, C, R, F, D)
%
% Argument
%   fOi : fundamental frequency trajectory in sampling resolution (Hz)
%   fs  : sampling frequency (Hz)
%   A, B, C, R, F, D : Fujisaki-Ljungqvist model parameter
%
% Output
%   output : structure with the following fields
%     antiAliasedSignal : antialiased F-L model output
%     antiAliasedOnly : antialiased F-L model output without equalization
%     rawSignal : directly discretized F-L model output

% 24/Jan./2017 by Hideki Kawahara
% 11/Feb./2017 revised for new aaf

phase_i = cumsum(2 * pi * fOi / fs);
index_v = (1:length(phase_i))';
mean_fO = mean(fOi);
d_phase_org = 1 / fs * 2 * pi * mean_fO;
g = phase_i(:) * 0;
gapp = g;
graw = g;
d_phase = d_phase_org;
margin_p = 5 * d_phase;
for initial_phase = 2 * pi:2 * pi:phase_i(end) - 2 * pi
  tmp_seg = phase_i(phase_i - initial_phase > -margin_p  & ...
    phase_i - initial_phase <= 2 * pi+margin_p) - initial_phase;
  fO_seg = fOi(phase_i - initial_phase > -margin_p  & ...
    phase_i - initial_phase <= 2 * pi+margin_p);
  tput = ...
    antialiasedFLmodelSingleR(tmp_seg, A, B, C, R, F, D, fs, mean(fO_seg));
  rout = rawFLmodelSingle(tmp_seg, A, B, C, R, F, D);
  idx_a = index_v(phase_i - initial_phase > -margin_p  & ...
    phase_i - initial_phase <= 2 * pi+margin_p);
  gapp(idx_a) = gapp(idx_a) + tput.g;
  graw(idx_a) = graw(idx_a) + rout.g;
end
hc = [0.2624710164 0.4265335164 0.2250165621 0.0726831633 0.0125124215 0.0007833203];
equalizerStr = equalizerDesignAAFX(hc,68,80, 1.5);
a = equalizerStr.iirCoefficient;
% This zero padding is to compensate the intrinsic delay of the symmetric
% anti-aliasing smoother
gfar = filter(sum(a) * [0 0 1], a, gapp);
output.antiAliasedSignal = gfar;
output.antiAliasedOnly = gapp;
output.rawSignal = graw;
end