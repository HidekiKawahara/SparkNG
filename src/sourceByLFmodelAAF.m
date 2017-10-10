function modelOut = sourceByLFmodelAAF(timeAxis,tp,te,ta,tc,Twor)
%   modelOut = sourceByLFmodelAAF(timeAxis,tp,te,ta,tc)
%   tp,te,ta, tc is assumed to be normalized by T0, the fundamental period
%   The time axis is also assumed to be normaized by T0.
%   This version is based on a closed form of anti-aliased L-F model
%
%   Designed and coded by Hideki Kawahara
%   27/May/2015
%   28/May/2015 Volume velocity is added
%   29/May/2015 bug fix
%   22/June/2015 Anti-aliased L-F model is added
%   12/June/2015 omegaG is added to the output
%   Definition of LF model is given by:
%   G.Fant, J.Liljencrants and Q.Lin,STL-QPSR,26,4,1-13,1985.

ak = [0.355768 0.487396 0.144232 0.012604]'; % Nuttall win
Tw = Twor/tc;
t = timeAxis(:)/tc;
tpN = tp/tc;
teN = te/tc;
taN = ta/tc;
fg = 1/(2*tpN);
omegaG = 2*pi*fg;
et = t*0; vv = t*0;
%--- design exponential decay
myfun = @(x,ta,te) (x*ta-1+exp(-x*(1-te)));
fun = @(x) myfun(x,taN,teN);
betaa = fzero(fun,1/taN);
et(t>=teN & t<1) = -1*(exp(-betaa*(t(t>=teN & t<1)-teN))-exp(-betaa*(1-teN)));
vv(t>=teN & t<1) = exp(-betaa*(t(t>=teN & t<1)-teN))/betaa+ ...
    (t(t>=teN & t<1)-teN)*exp(-betaa*(1-teN));
boundaryValue = exp(-betaa*(1-teN))/betaa+(1-teN)*exp(-betaa*(1-teN));
%--- design ramped sinusoid
a = -1/betaa+exp(-betaa*(1-teN))*(1/betaa+(1-teN));
myfun2 = @(x,wg,a,betaa,te)(a-(1-exp(-betaa*(1-te)))/(exp(x*te)*sin(wg*te))/ ...
    (x^2+wg^2)*(exp(x*te)*(x*sin(wg*te)-wg*cos(wg*te))+wg));
fun2 = @(x) myfun2(x,omegaG,a,betaa,teN);
alphaa = fzero(fun2,0);
e0 = -(1-exp(-betaa*(1-teN)))/(exp(alphaa*teN)*sin(omegaG*teN));
et(t<teN) = e0*exp(alphaa*t(t<teN)).*sin(omegaG*t(t<teN));
vv(t<teN) = e0/(alphaa^2+omegaG^2)* ...
    exp(alphaa*t(t<teN)).*(alphaa*sin(omegaG*t(t<teN))-omegaG*cos(omegaG*t(t<teN)));
initialValue = e0/(alphaa^2+omegaG^2)*(-omegaG);
vv(t<teN) = vv(t<teN)-initialValue; % boundary condition at t=0
vv(t>=teN & t<1) = vv(t>=teN & t<1)-boundaryValue; % boundary condition at t=1
td = 1-teN;
openSig = [openTermk(t,Tw,teN,alphaa,omegaG,0) openTermk(t,Tw,teN,alphaa,omegaG,1) ...
    openTermk(t,Tw,teN,alphaa,omegaG,2) openTermk(t,Tw,teN,alphaa,omegaG,3)]*ak;
x = t-teN;
clx2 = [closeI2k0xi0(x,Tw,td) closeI2kn0(x,Tw,td,1) closeI2kn0(x,Tw,td,2) closeI2kn0(x,Tw,td,3)]*ak;
clx3 = [closeI4(x,Tw,td,-betaa,0) closeI4(x,Tw,td,-betaa,1) closeI4(x,Tw,td,-betaa,2) closeI4(x,Tw,td,-betaa,3)]*ak;
closingSig = clx3-exp(-betaa*td)*clx2;
modelOut.normalizedTimeAxis = t;
modelOut.source = et.*(t>0 & t<1);
modelOut.volumeVerocity = vv;
modelOut.antiAliasedSource = (e0*openSig-closingSig)/(ak(1)*2*Tw);
% quick and dirty patch This patch is no-longer needed and harmful!
% 11/Nov./2015 HK !!
%maxValue = max(modelOut.antiAliasedSource);
%for ii = 2:length(modelOut.antiAliasedSource)-1
%    if modelOut.antiAliasedSource(ii-1)-modelOut.antiAliasedSource(ii)>0.2*maxValue && ...
%            modelOut.antiAliasedSource(ii+1)-modelOut.antiAliasedSource(ii)>0.2*maxValue
%        modelOut.antiAliasedSource(ii) = (modelOut.antiAliasedSource(ii-1)+modelOut.antiAliasedSource(ii+1))/2;
%    end;
%end;
% end of patch
modelOut.decayRate = betaa;
modelOut.growthRate = alphaa;
modelOut.omegaG = omegaG;

