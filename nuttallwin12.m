function w = nuttallwin12(N)
%   w = nuttallwin12(N)
%   Nuttall window with continuous first order derivative
%   No.12 example in [1]

%   19/August/2011 by Hideki Kawahara

%   Reference:
%   [1] Nuttall, A.; ``Some windows with very good sidelobe behavior,'' 
%   Acoustics, Speech and Signal Processing, IEEE Transactions on , 
%   vol.29, no.1, pp. 84--91, Feb 1981. 
%   doi: 10.1109/TASSP.1981.1163506

x = (0:N-1)'*2*pi/(N-1);
aa = [0.355768 0.487396 0.144232 0.012604];
BB = [aa(1); -aa(2); aa(3); -aa(4)];
w = cos(x* [0 1 2 3]) * BB;