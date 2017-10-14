function output = antiAliasedCExponentialSegment(bet, tt, two)

%Copyright 2017 Hideki Kawahara
%
%Licensed under the Apache License, Version 2.0 (the "License");
%you may not use this file except in compliance with the License.
%You may obtain a copy of the License at
%
%    http://www.apache.org/licenses/LICENSE-2.0
%
%Unless required by applicable law or agreed to in writing, software
%distributed under the License is distributed on an "AS IS" BASIS,
%WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
%See the License for the specific language governing permissions and
%limitations under the License. 

tw = two * 1.5;
alph = pi / tw;
aa = [0.2624710164 0.4265335164 0.2250165621 0.0726831633 0.0125124215 0.0007833203];
m = length(aa) - 1;
outbuf = tt * 0;
for k = 0:m
  seg1 = tt(tt >= tw & tt <= tw+1);
  seg2 = tt(abs(tt) < tw);
  seg3 = tt(abs(1-tt) <= tw); % fragile? using "<" made error
  y1 = (k*alph*sin(k*alph*seg2)-bet*cos(k*alph*seg2) ...
    +(-1)^k*bet*exp(bet*tw)*exp(bet*seg2))/(k^2 * alph^2 + bet*bet);
  yy = ((-1)^k * bet * exp(bet * seg1) * (exp(bet * tw) - exp(-bet * tw))/(k^2 * alph^2 + bet*bet));
  y3 = ((k*alph*exp(bet)*sin(k*alph*(seg3-1)) + bet*exp(bet*(tw+seg3))*(-1)^k ...
    - bet*exp(bet)*cos(k*alph*(seg3-1))) / (k^2 * alph^2 + bet*bet));
  outbuf(tt >= tw & tt <= tw+1) = outbuf(tt >= tw & tt <= tw+1) + aa(k+1) * yy;
  outbuf(abs(tt) < tw) =  outbuf(abs(tt) < tw) + aa(k+1) * y1;
  outbuf(abs(1-tt) <= tw) =  outbuf(abs(1-tt) <= tw) - aa(k+1) * y3;
end
output = outbuf / (tw * aa(1) * 2);
end