function out = closeI2k0xi0(t,Tw,td)
out = -r(t-Tw)+r(t+Tw)+r(t-td-Tw)-r(t-td+Tw);

function rout = r(x)
rout = double(x.*(x>0));