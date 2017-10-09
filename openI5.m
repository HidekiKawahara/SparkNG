function out = openI5(t,Tw,te,alphaa,omgg,k)

%   08/Nov./2015 bug fix for concatination
u1 = double(t>Tw & t-te<Tw);
u2 = double(t>-Tw & t-te<-Tw);
term1 = (-1)^k*(u1.*exp((-alphaa-1i*omgg)*Tw) ...
    -u2.*exp(-(-alphaa-1i*omgg)*Tw));
term2 = exp((-alphaa-1i*omgg+1i*k*pi/Tw)*t).*(-Tw< t & t <=Tw);%fix
term3 = exp((-alphaa-1i*omgg+1i*k*pi/Tw)*(t-te)).*(-Tw < t-te & t-te <=Tw); %fix
out = (term1+term2-term3)/(-alphaa-1i*omgg+1i*k*pi/Tw);