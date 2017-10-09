function outStr = testJitShimAALF(jitterSD,shimmerSD,ppcent,fv,f0,vq,perturbation)
%%  Test L-F model with randomness
%   Author: Hideki Kawahara
%   12/Dec./2015

fs = 44100;
duration = 0.5;
tt = (0:1/fs:duration)';
switch vq
    case 1
        tp = 0.4134;
        te = 0.5530;
        ta = 0.0041;
        tc = 0.5817;
    case 2
        tp = 0.4621;
        te = 0.6604;
        ta = 0.0270;
        tc = 0.7712;
    case 3
        tp = 0.4808;
        te = 0.5955;
        ta = 0.0269;
        tc = 0.7200;

end;
f0Base = f0;
f0 = f0Base*2.0.^(ppcent/1200*sin(2*pi*fv*tt));

%%
%shimmerSD = 0.0;
outStr = AAFLFmodelFromF0Trajectory(f0,tt,fs,tp,te,ta,tc,jitterSD,shimmerSD,perturbation);
soundsc(outStr.antiAliasedSignal,fs)
end
