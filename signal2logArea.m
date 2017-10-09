function logArea = signal2logArea(x)
%   by Hideki Kawahara
%   This is only a quick and dirty hack. Please refer to proper reference
%   for estimating vocal tract area function.
%   18/Jan./2014

%   This is valid only for signals sampled at 8000Hz.

n = length(x);
w = blackman(n);
ww = w/sqrt(sum(w.^2));
fftl = 2^ceil(log2(n));
%x = [0;x(2:end)-0.925*x(1:end-1)];
x = [0;diff(x)];
pw = abs(fft(x.*ww,fftl)).^2;
lpw = log(pw+sum(pw)/fftl/1000);
lpwn = lpw-mean(lpw);
theta = (0:fftl-1)/fftl*2*pi;
%c1 = 2*sum(cos(theta(:)).*lpwn)/fftl;
%c2 = sum(cos(2*theta(:)).*lpwn)/fftl; % This may not be necessary.
%pwc = real(exp(lpwn-c1*cos(theta(:))-c2*cos(2*theta(:))));
pwc = real(exp(lpwn-0.5*cos(theta(:))+0.5*cos(2*theta(:))));
ac = real(ifft(pwc));
[alp,err,k] = levinson(ac,9);
s = ref2area(-k);
logArea = log(s);
end

function s = ref2area(k)

n = length(k);
s = zeros(n+1,1);
s(end) = 1;
for ii = n:-1:1
    s(ii) = s(ii+1)*(1-k(ii))/(1+k(ii));
end;
end
