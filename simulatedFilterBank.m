function filterBankStr = simulatedFilterBank(sgram,fx,bankType)
%   Filter bank simulator based on FFT power spectrum

%   22/Dec./2013 by Hideki Kawahara
%   This simulation is rough approximation. Please refer to the original
%   papers for serious scientific applications. This routine is provided "as
%   is" and no warranty. 
%   This is a sample code. Use this as you like.

sgram = cumsum(sgram);
fLow = 50;
tickFrequencyList = [50 70 100 150 200 300 400 500 700 1000 1500 2000 3000 4000 5000 7000 10000 15000 20000];
filterBankStr.tickLabelList = char({'50';'70';'100';'150';'200';'300';'400';'500'; ...
    '700';'1000';'1500';'2000';'3000';'4000';'5000';'7000';'10000';'15000';'20000'});
switch bankType
    case 'third'
        logFrequencyAxis = fLow*2.0.^(0:1/24:log2(fx(end)/fLow)-1/6)';
        fxUpper = logFrequencyAxis*2^(1/6);
        fxLower = logFrequencyAxis*2^(-1/6);
        upperCumPower = interp1(fx,sgram,fxUpper,'linear','extrap');
        lowerCumPower = interp1(fx,sgram,fxLower,'linear','extrap');
        filterBankStr.filteredSgramRectangle = upperCumPower-lowerCumPower;
        sgram = cumsum(filterBankStr.filteredSgramRectangle);
        upperCumPower = interp1(logFrequencyAxis,sgram,fxUpper,'linear','extrap');
        lowerCumPower = interp1(logFrequencyAxis,sgram,fxLower,'linear','extrap');
        filterBankStr.filteredSgramTriangle = upperCumPower-lowerCumPower;
        filterBankStr.fcList = logFrequencyAxis;
    case 'ERB'
        logFrequencyAxis = fLow*2.0.^(0:1/24:log2(fx(end)/fLow)-1/6)';
        ERBofLogFrequencyAxis = freq2ERBprv(logFrequencyAxis);
        ERBFrequencyAxis = (0:200)'/200*(ERBofLogFrequencyAxis(end)-ERBofLogFrequencyAxis(1)) ...
            +ERBofLogFrequencyAxis(1);
        logFrequencyAxisTmp = interp1(ERBofLogFrequencyAxis,logFrequencyAxis,ERBFrequencyAxis,'linear','extrap');
        %fxUpper = logFrequencyAxis*2^(1/6);
        fxUpper = interp1(ERBofLogFrequencyAxis,logFrequencyAxis,ERBFrequencyAxis+0.5,'linear','extrap');
        fxLower = interp1(ERBofLogFrequencyAxis,logFrequencyAxis,ERBFrequencyAxis-0.5,'linear','extrap');
        upperCumPower = interp1(fx,sgram,fxUpper,'linear','extrap');
        lowerCumPower = interp1(fx,sgram,fxLower,'linear','extrap');
        filterBankStr.filteredSgramRectangle = upperCumPower-lowerCumPower;
        sgram = cumsum(filterBankStr.filteredSgramRectangle);
        upperCumPower = interp1(logFrequencyAxisTmp,sgram,fxUpper,'linear','extrap');
        lowerCumPower = interp1(logFrequencyAxisTmp,sgram,fxLower,'linear','extrap');
        filterBankStr.filteredSgramTriangle = upperCumPower-lowerCumPower;
        filterBankStr.fcList = logFrequencyAxisTmp;
    case 'Bark'
        logFrequencyAxis = fLow*2.0.^(0:1/24:log2(fx(end)/fLow)-1/6)';
        ERBofLogFrequencyAxis = freq2BarkPrv(logFrequencyAxis);
        ERBFrequencyAxis = (0:200)'/200*(ERBofLogFrequencyAxis(end)-ERBofLogFrequencyAxis(1)) ...
            +ERBofLogFrequencyAxis(1);
        logFrequencyAxisTmp = interp1(ERBofLogFrequencyAxis,logFrequencyAxis,ERBFrequencyAxis,'linear','extrap');
        fxUpper = interp1(ERBofLogFrequencyAxis,logFrequencyAxis,ERBFrequencyAxis+0.5,'linear','extrap');
        fxLower = interp1(ERBofLogFrequencyAxis,logFrequencyAxis,ERBFrequencyAxis-0.5,'linear','extrap');
        upperCumPower = interp1(fx,sgram,fxUpper,'linear','extrap');
        lowerCumPower = interp1(fx,sgram,fxLower,'linear','extrap');
        filterBankStr.filteredSgramRectangle = upperCumPower-lowerCumPower;
        sgram = cumsum(filterBankStr.filteredSgramRectangle);
        upperCumPower = interp1(logFrequencyAxisTmp,sgram,fxUpper,'linear','extrap');
        lowerCumPower = interp1(logFrequencyAxisTmp,sgram,fxLower,'linear','extrap');
        filterBankStr.filteredSgramTriangle = upperCumPower-lowerCumPower;
        filterBankStr.fcList = logFrequencyAxisTmp;
end;
fxTrim = (0:length(filterBankStr.fcList)-1)/(length(filterBankStr.fcList)-1)* ...
    (filterBankStr.fcList(end)-filterBankStr.fcList(1))+filterBankStr.fcList(1);
filterBankStr.ticLocationList = interp1(filterBankStr.fcList,fxTrim,tickFrequencyList,'linear','extrap');
end

function erbAxis = freq2ERBprv(axisInHz)
erbAxis=21.4*log10(0.00437*axisInHz+1);
end

function barkAxis = freq2BarkPrv(axisInHz)
barkAxis = 26.81./(1+1960.0./axisInHz)-0.53;
end
