function w = nuttallwin12self(N)
%   w = nuttallwin12self(N)
%   Nuttall window with continuous first order derivative
%   No.12 example in [1] and self convolutoin

%   19/August/2011 by Hideki Kawahara
%   23/April/2014 by Hideki Kawahara

%   Reference:
%   [1] Nuttall, A.; ``Some windows with very good sidelobe behavior,'' 
%   Acoustics, Speech and Signal Processing, IEEE Transactions on , 
%   vol.29, no.1, pp. 84--91, Feb 1981. 
%   doi: 10.1109/TASSP.1981.1163506

a = nuttallwin12(ceil(N/2));
b = nuttallwin12(ceil((N+1)/2));
w = conv(a,b);
