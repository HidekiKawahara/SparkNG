function out = closeI4(t,Tw,td,beetaa,k)
u1 = double(t>Tw & t-td<Tw);
u2 = double(t>-Tw & t-td<-Tw);
coeff = -beetaa+1i*k*pi/Tw;
out = (real(1/coeff*(exp(coeff*t).*(abs(t)<=Tw)-exp(coeff*(t-td)).*(abs(t-td)<=Tw)))+ ...
    (-1)^k*real(1/coeff)*(u1*exp(-beetaa*Tw)-u2*exp(beetaa*Tw))).*exp(beetaa*t);

