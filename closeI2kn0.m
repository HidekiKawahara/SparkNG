function out = closeI2kn0(t,Tw,td,k)
out = Tw/k/pi*sin(k*pi*t.*(abs(t)<Tw)/Tw)-Tw/k/pi*sin(k*pi*(t-td).*(abs(t-td)<Tw)/Tw);
