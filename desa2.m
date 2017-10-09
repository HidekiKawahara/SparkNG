function output = desa2(x, fs)
phx = tkeo(x);
phy = tkeo(x([2:end, end]) - x([1, 1:end-1]));
omg = asin(real(sqrt(phy ./ phx / 4)));
amp = 2 * phx ./ real(sqrt(phy));
output.omg = omg([3, 3, 3:end-2, end-2, end-2]) * fs;
output.amp = amp([3, 3, 3:end-2, end-2, end-2]);
end

function phi = tkeo(x)
phi = x .^ 2 - x([1, 1:end-1]) .* x([2:end, end]);
end