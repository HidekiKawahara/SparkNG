%%  elapsed time for window functions
%   by Hideki Kawahara
%   24/Oct./2014

lengthList = 2.0.^(8:14)';
iteration = 100;

tic;nuttallwin12(973);toc
tic;blackman(973);toc
tic;kaiser(973,12.45);toc
tic;dpss(973,3.55);toc

elapsedTimeList = zeros(4,length(lengthList));
for ii = 1:length(lengthList)
    wlength = lengthList(ii)+1;
    timeBlackman = 0;
    timeNuttall = 0;
    timeKaiser = 0;
    timeDpss = 0;
    for jj = 1:iteration
        tic;nuttallwin12(wlength);t1 = toc;
        tic;blackman(wlength);t2 = toc;
        tic;kaiser(wlength,12.45);t3 = toc;
        tic;dpss(wlength,3.55);t4 = toc;
        timeBlackman = timeBlackman+t1;
        timeNuttall = timeNuttall+t2;
        timeKaiser = timeKaiser+t3;
        timeDpss = timeDpss+t4;
    end;
    timeBlackman = timeBlackman/iteration;
    timeNuttall = timeNuttall/iteration;
    timeKaiser = timeKaiser/iteration;
    timeDpss = timeDpss/iteration;
    elapsedTimeList(:,ii) = [timeBlackman timeNuttall timeKaiser timeDpss]';
end;
%%
figure
loglog(lengthList,elapsedTimeList*1000,'o-','linewidth',2);
grid on;
set(gca,'fontsize',15);
xlabel('window size in sample');
ylabel('elapsed time (ms)');
legend('Blackman','Nuttall','Kaiser','DPSS','location','northwest');
set(gca,'xlim',[200 20000])
