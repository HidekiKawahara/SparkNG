function out = closeI4k0(t,Tw,td,beetaa)
u1 = double(t>Tw & t-td<Tw);
u2 = double(t>-Tw & t-td<-Tw);
out = -(1/beetaa)*(exp(-beetaa*t).*(abs(t)<=Tw)-exp(-beetaa*(t-td)).*(abs(t-td)<=Tw)+ ...
    u1*exp(-beetaa*Tw)-u2*exp(beetaa*Tw));
out = out.*exp(-beetaa*t);

