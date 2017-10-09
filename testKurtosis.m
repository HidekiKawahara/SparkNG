%%  kurtosis distribution simulation for normal distribution
%   29/April/2014

fs = 44100;
lengthInS = 0.04;
lengthInSample = round(fs*lengthInS);
iterations = 100000;
kurtosisList = zeros(iterations,1);
for ii = 1:iterations
    xn = randn(lengthInSample,1);
    kurtosisList(ii) = mean(xn.^4)/std(xn)^4;
end;
figure;
semilogy(sort(kurtosisList),(iterations:-1:1)/iterations);grid on;

%%

fs = 44100;
lengthInS = 0.04;
lengthInSample = round(fs*lengthInS);
iterations = 100000;
kurtosisList = zeros(iterations,1);
for ii = 1:iterations
    xn = rand(lengthInSample,1);
    xn = sign(xn-0.5).*(exp(abs(xn-0.5)*10)-1);
    kurtosisList(ii) = mean(xn.^4)/std(xn)^4;
end;
figure;
semilogy(sort(kurtosisList),(iterations:-1:1)/iterations);grid on;
