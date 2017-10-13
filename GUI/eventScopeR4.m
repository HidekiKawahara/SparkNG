function varargout = eventScopeR4(varargin)
% EVENTSCOPER4 MATLAB code for eventScopeR4.fig
%      EVENTSCOPER4, by itself, creates a new EVENTSCOPER4 or raises the existing
%      singleton*.
%
%      H = EVENTSCOPER4 returns the handle to a new EVENTSCOPER4 or the handle to
%      the existing singleton*.
%
%      EVENTSCOPER4('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in EVENTSCOPER4.M with the given input arguments.
%
%      EVENTSCOPER4('Property','Value',...) creates a new EVENTSCOPER4 or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before eventScopeR4_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to eventScopeR4_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

%   Sample program for realtime event detection
%   Designed and coded by Hideki Kawahara
%   28/April/2014
%   29/April/2014 slightly cleaned up
%   30/April/2014 further cleaning
%   02/May/2014 f0 display revision
%   31/Aug./2015 machine independent and resizable
%
% Comment:
%   Timer structure used in this routine can be a bad practice.
%   This tool will be redesigned completely.

% This work is licensed under the Creative Commons
% Attribution 4.0 International License.
% To view a copy of this license, visit
% http://creativecommons.org/licenses/by/4.0/.

% Edit the above text to modify the response to help eventScopeR4

% Last Modified by GUIDE v2.5 02-May-2014 10:27:55

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
    'gui_Singleton',  gui_Singleton, ...
    'gui_OpeningFcn', @eventScopeR4_OpeningFcn, ...
    'gui_OutputFcn',  @eventScopeR4_OutputFcn, ...
    'gui_LayoutFcn',  [] , ...
    'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT
end

% --- Executes just before eventScopeR4 is made visible.
function eventScopeR4_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to eventScopeR4 (see VARARGIN)

% Choose default command line output for eventScopeR4
handles.output = hObject;
myGUIdata = guidata(hObject);
myGUIdata.samplingFrequency = 44100;
timerEventInterval = 0.050; % in second
myGUIdata.timerEventInterval = timerEventInterval;
guidata(hObject, myGUIdata);
myGUIdata = initializeDisplay(myGUIdata);
timer50ms = timer('TimerFcn',@synchDrawGUI, 'Period',timerEventInterval,'ExecutionMode','fixedRate', ...
    'userData',handles.eventScopeGUI);
myGUIdata.timer50ms = timer50ms;
timerForWaveDraw = timer('TimerFcn',@waveDrawServer,'ExecutionMode','singleShot', ...
    'userData',handles.eventScopeGUI);
myGUIdata.timerForWaveDraw = timerForWaveDraw;
%spectrumBarServer
timerForSpectrumBar = timer('TimerFcn',@spectrumBarServer,'ExecutionMode','singleShot', ...
    'userData',handles.eventScopeGUI);
myGUIdata.timerForSpectrumBar = timerForSpectrumBar;
timerForKurtosisBar = timer('TimerFcn',@kurtosisBarServer,'ExecutionMode','singleShot', ...
    'userData',handles.eventScopeGUI);
myGUIdata.timerForKurtosisBar = timerForKurtosisBar;
%fineF0Server
timerForFineF0 = timer('TimerFcn',@fineF0Server,'ExecutionMode','singleShot', ...
    'userData',handles.eventScopeGUI);
myGUIdata.timerForFineF0 = timerForFineF0;
myGUIdata.recordObj1 = audiorecorder(myGUIdata.samplingFrequency,24,1);
set(myGUIdata.recordObj1,'TimerPeriod',0.2);
record(myGUIdata.recordObj1);
myGUIdata.maxAudioRecorderCount = myGUIdata.maxTargetPoint;

myGUIdata.maxLevel = -100;
myGUIdata.lastLevel = 0;
myGUIdata.lastLastLevel = 0;
myGUIdata.jumpLimit = 10;
myGUIdata.output = hObject;
myGUIdata.audioRecorderCount = myGUIdata.maxAudioRecorderCount;

% Update handles structure
guidata(hObject, myGUIdata);
myGUIdata = startRealtime(myGUIdata);
myGUIdata.startTime = datevec(now);
guidata(hObject, myGUIdata);
% UIWAIT makes eventScopeR4 wait for user response (see UIRESUME)
% uiwait(handles.eventScopeGUI);
end

% --- private function
function myGUIdata = startRealtime(myGUIdata)
switch get(myGUIdata.timer50ms,'running')
    case 'on'
        stop(myGUIdata.timer50ms);
end
myGUIdata.audioRecorderCount = myGUIdata.maxAudioRecorderCount;
myGUIdata.lastPosition = 1;
record(myGUIdata.recordObj1);
switch get(myGUIdata.timer50ms,'running')
    case 'off'
        start(myGUIdata.timer50ms);
    case 'on'
    otherwise
        disp('timer is bloken!');
end
set(myGUIdata.periodicHandle,'ydata',myGUIdata.tAxis+NaN);
set(myGUIdata.peakyHandle,'ydata',myGUIdata.tAxis+NaN);
%myGUIdata.peakyData = myGUIdata.tAxis+NaN;
set(myGUIdata.onsetHandle,'ydata',myGUIdata.tAxis+NaN);
%myGUIdata.onsetData = myGUIdata.tAxis+NaN;
set(myGUIdata.powerHandle,'ydata',myGUIdata.tAxis+NaN);
set(myGUIdata.noteHandle,'ydata',myGUIdata.tAxis*0+NaN);
set(myGUIdata.stopButton,'enable','on');
set(myGUIdata.startButton,'enable','off');
myGUIdata.countStarted = false;
end

% --- private function
function myGUIdata = initializeDisplay(myGUIdata)
axes(myGUIdata.waveformViewerAxis);
myGUIdata.viewWidth = 0.035;
tx = 0:floor(myGUIdata.samplingFrequency*myGUIdata.viewWidth);
myGUIdata.waveHandle = plot(tx,randn(length(tx),1),'linewidth',2);
set(gca,'xlim',[tx(1) tx(end)]);
axis('off')
myGUIdata.maxTargetPoint = 200;%500;
%--------------
axes(myGUIdata.spectrumBarAxis);
fs = myGUIdata.samplingFrequency;
baseChannelFrequency = 20;
myGUIdata.centerFrequencyList = baseChannelFrequency*2.0.^(0:1/3:log2(fs/2/baseChannelFrequency*2^(-1/6)))';
myGUIdata.fLow = myGUIdata.centerFrequencyList*2^(-1/6);
myGUIdata.fHigh = myGUIdata.centerFrequencyList*2^(1/6);
myGUIdata.channelID = 1:length(myGUIdata.centerFrequencyList);
myGUIdata.barHandle = bar(myGUIdata.channelID,80*rand(length(myGUIdata.centerFrequencyList),1),'facecolor',[0.3 0.3 1]);
myGUIdata.tickList = [20 30 40 50 60 70 80 90 100 200 300 400 500 600 700 800 900 1000 ...
    2000 3000 4000 5000 6000 7000 8000 9000 10000];
myGUIdata.tickLabel = {'02';'03';' ';'05';' ';'07';' ';' ';'.1';'.2';'.3';' ';'.5';' ';'.7';' ';' ';'1'; ...
    '2';'3';' ';'5';' ';'7';' ';' ';'10'};
myGUIdata.tickocation = interp1(myGUIdata.centerFrequencyList,myGUIdata.channelID,myGUIdata.tickList);
set(myGUIdata.barHandle,'BarWidth',1);
grid on;
xlabel('frequency (kHz)');
ylabel('level (dB)');
set(myGUIdata.spectrumBarAxis,'ylim',[0 90]);
%hold on;plot([20 fs/2],0*[1 1],'k','linewidth',2);hold off
set(myGUIdata.spectrumBarAxis,'xlim',[0.5 myGUIdata.channelID(end)+0.5]);
set(myGUIdata.spectrumBarAxis,'xtick',myGUIdata.tickocation,'xtickLabel',myGUIdata.tickLabel);
ytick = 0:10:90;
ytickLabel = {'-90';'-80';'-70';'-60';'-50';'-40';'-30';'-20';'-10';'0'};
set(myGUIdata.spectrumBarAxis,'ytick',ytick,'ytickLabel',ytickLabel);
myGUIdata.windowLength = 0.04;
myGUIdata.windowSizeInSample = round(myGUIdata.windowLength*fs);
w = blackman(myGUIdata.windowSizeInSample);
myGUIdata.window = w/sqrt(sum(w.^2));
myGUIdata.fftl = 2^ceil(log2(myGUIdata.windowSizeInSample));
myGUIdata.fAxis = (0:myGUIdata.fftl-1)'/myGUIdata.fftl*fs;
wTmp = real(ifft(abs(fft(w,myGUIdata.fftl)).^2));
fAxisDFT = myGUIdata.fAxis;
fAxisDFT(fAxisDFT>fs/2) = fAxisDFT(fAxisDFT>fs/2)-fs;
myGUIdata.baseBandLimit = 3000;
myGUIdata.shaper = 0.5+0.5*cos(pi*fAxisDFT/myGUIdata.baseBandLimit);
myGUIdata.shaper(abs(fAxisDFT)>myGUIdata.baseBandLimit) = 0;
%myGUIdata.shaper = myGUIdata.shaper;
myGUIdata.lagwindow = (wTmp/wTmp(1)).^(0.8);
myGUIdata.lagAxis = (0:myGUIdata.fftl-1)/fs;
%--------------------
axes(myGUIdata.parameterViewerAxis);
myGUIdata.tAxis = (0:myGUIdata.maxTargetPoint-1)*myGUIdata.timerEventInterval;
myGUIdata.periodicHandle = plot(myGUIdata.tAxis,myGUIdata.tAxis*0+1,'color',[0 0.8 0],'linewidth',7);
hold on
myGUIdata.peakyHandle = plot(myGUIdata.tAxis,myGUIdata.tAxis*0+2,'m','linewidth',7);
myGUIdata.onsetHandle = plot(myGUIdata.tAxis,myGUIdata.tAxis*0+1.5,'r','linewidth',7);
myGUIdata.powerHandle = plot(myGUIdata.tAxis,myGUIdata.tAxis*0+3,'b','linewidth',2);
set(myGUIdata.parameterViewerAxis,'ylim',[0.5 5],'xlim',[0 myGUIdata.tAxis(end)]);
set(myGUIdata.parameterViewerAxis,'ytick',[1 1.5 2 3],'ytickLabel',{'periodic';'onset';'peaky';'level'});
set(myGUIdata.parameterViewerAxis,'xticklabel',[]);
grid on;
hold off;
%---------------------
axes(myGUIdata.kurtosisBarAxis);
myGUIdata.kurtosisBarHandle = bar(1,3,'m');grid on;
myGUIdata.kurtosisLimit = 40;
set(myGUIdata.kurtosisBarAxis,'ylim',[1 myGUIdata.kurtosisLimit],'xtick',[]);
xlabel('kurtosis')
set(myGUIdata.kurtosisBarAxis,'yscale','log');
ytick = [1:10 20:10:100];
ytickLabel = {'1';'2';'3';' ';'5';' ';'7';' ';' ';'10';...
    '20';'30';'40';'50';' ';' ';' ';' ';'100';};
set(myGUIdata.kurtosisBarAxis,'ytick',ytick,'ytickLabel',ytickLabel);
set(myGUIdata.kurtosisBarHandle,'BarWidth',1)
w = blackman(31);
ww = w/sum(w);
ww(16) = ww(16)-1;
myGUIdata.kurtosisHPF = -ww;
%---------------------
axes(myGUIdata.powerBarAxis);
myGUIdata.totalPowerBarHandle = bar(1,-80,'b');grid on;
set(myGUIdata.powerBarAxis,'ylim',[0 90],'xtick',[]);
xlabel('power');
ylabel('level (dB)')
set(myGUIdata.powerBarAxis,'ytick',[0:10:90],'ytickLabel',...
    {'-90';'-80';'-70';'-60';'-50';'-40';'-30';'-20';'-10';'0'});
set(myGUIdata.totalPowerBarHandle,'BarWidth',1)
%---------------------
axes(myGUIdata.periodicityBarAxis);
myGUIdata.periodicityBarHandle = bar(1,0.5,'g');grid on;
set(myGUIdata.periodicityBarAxis,'ylim',[0 1],'xtick',[],'ytick',0:0.1:1);
xlabel('max.corr.');
set(myGUIdata.periodicityBarHandle,'BarWidth',1)
%---------------------
%noteAxis
myGUIdata.noteID = (-7:27+7)';
%110*2.0.^((-2:27)/12);
myGUIdata.noteName = {'D2';' ';'E2';'F2';' ';'G2';' ';'A2';' ';'H2';'C3';' ';'D3';' ';'E3';'F3';' ';'G3';' ';'A3'; ...
    ' ';'H3';'C4';' ';'D4';' ';'E4';' ';'F4';'G4';' ';'A4';' ';'H4';'C5' ...
    ;' ';'D5';' ';'E5';'F5';' ';'G5'};
axes(myGUIdata.noteAxis);
myGUIdata = initializeForFineF0(myGUIdata);
hold on;
myGUIdata.SecondNoteHandle = plot(myGUIdata.tAxis,myGUIdata.tAxis*0,'s','markersize',5, ...
    'markerfacecolor',[0.5 0.8 0.5],'markeredgecolor',[0.5 0.8 0.5]);
myGUIdata.noteHandle = plot(myGUIdata.tAxis,myGUIdata.tAxis*0,'s','markersize',7, ...
    'markerfacecolor',[0 0.8 0],'markeredgecolor',[0 0.8 0]);
frequencyTick = [40 50 60 70 80 90 100 150 200 300 400 500 600 700 800 900 1000];
frequencyBase = 10:10:2000;
hold off
myGUIdata.freqtickLocation = interp1(frequencyBase,12*log2(frequencyBase/110),frequencyTick);
myGUIdata.freqTickLabel = {'40';'50';'60';'70';'80';'90';'100';'150';'200';'300';'400';'500';'600';'700';'800';'900';'1000';};
set(myGUIdata.noteAxis,'ytick',myGUIdata.noteID,'ytickLabel',myGUIdata.noteName);
set(myGUIdata.SecondNoteHandle,'ydata',myGUIdata.tAxis*0+NaN);
set(myGUIdata.noteHandle,'ydata',myGUIdata.tAxis*0+NaN);
grid on;
set(myGUIdata.noteAxis,'ylim',[myGUIdata.noteID(1) myGUIdata.noteID(end)+1],'xlim',[0 myGUIdata.tAxis(end)]);
%---------------------
axes(myGUIdata.colorPadAxis);
tcmx = zeros(30,10,3);
tcmx(4:27,3:8,:) = 1;
myGUIdata.baseTrueColor = tcmx;
myGUIdata.colorPadHandle = image(tcmx);
axis('off')
set(myGUIdata.fpsText,'string','20.0 fps');
%---------------------
set(myGUIdata.noteRadioButton,'userdata',myGUIdata,'enable','on');
set(myGUIdata.freqRadioButton,'userdata',myGUIdata,'enable','on');
set(myGUIdata.axisModePanel,'userdata',myGUIdata,'SelectionChangeFcn',@modeRadioButterServer);
set(myGUIdata.saveFileButton,'enable','off');
end

function myGUIdata = initializeForFineF0(myGUIdata)
fs = myGUIdata.samplingFrequency;
myGUIdata.fineFrameShift = 0.010;
myGUIdata.fineTimeAxis = 0:myGUIdata.fineFrameShift:myGUIdata.tAxis(end);
myGUIdata.fineF0Handle = plot(myGUIdata.fineTimeAxis,myGUIdata.fineTimeAxis*0,'s','markersize',5, ...
    'markerfacecolor',[0 0.7 0],'markeredgecolor',[0 0.7 0]);
hold on
%myGUIdata.fine2ndF0Handle = plot(myGUIdata.fineTimeAxis,myGUIdata.fineTimeAxis*0,'s','markersize',3, ...
%    'markerfacecolor',[0.4 0.9 0.4],'markeredgecolor',[0.4 0.9 0.4]);
hold off
set(myGUIdata.fineF0Handle,'ydata',myGUIdata.fineTimeAxis*0+NaN);
%set(myGUIdata.fine2ndF0Handle,'ydata',myGUIdata.fineTimeAxis*0+NaN);
frameShift = 0.010; % 10ms
frameLength = 0.046; % 40ms
narrowWindow = 0.004; % 10ms
fsb4 = fs/4;
windowLengthInSample = round(frameLength*fsb4/2)*2+1; % always odd number
baseIndex = (-round(frameLength*fsb4/2):round(frameLength*fsb4/2))';
fftl = 2^ceil(log2(windowLengthInSample));
w = hanning(windowLengthInSample);
x = randn(round(myGUIdata.tAxis(end)*fs),1);
%xb4 = x(1:4:end);
narrowWindow = hanning(round(narrowWindow*fsb4/2)*2+1);
lagNarrowWindow = conv(narrowWindow,narrowWindow);
halfNarrorLength = round((length(lagNarrowWindow)-1)/2);
lagWindowForDFT = zeros(fftl,1);
lagWindowForDFT(1:halfNarrorLength+1) = lagNarrowWindow(halfNarrorLength+1:end);
lagWindowForDFT(fftl:-1:fftl-halfNarrorLength+1) = lagNarrowWindow(halfNarrorLength+2:end);
fx = (0:fftl-1)/fftl*fsb4;
fx(fx>fsb4/2) = fx(fx>fsb4/2)-fsb4;
hanningLPF = (0.5+0.5*cos(pi*fx(:)/2000)).^2;
hanningLPF(abs(fx)>2000) = 0;
wConv = conv(w,w);
[centerValue,centerIndex] = max(wConv);
mainLagWindow = zeros(fftl,1);
mainLagWindow(1:fftl/2) = wConv(centerIndex+(1:fftl/2)-1);
mainLagWindow(fftl:-1:fftl/2+1) = wConv(centerIndex+(1:fftl/2));
mainLagWindow = mainLagWindow.^0.7; % ad hoc
mainLagWindow(1:10) = mainLagWindow(1:10)*10;
mainLagWindow(end:-1:end-9) = mainLagWindow(end:-1:end-9)*10;

tickLocations = 0:frameShift:(length(x)-1)/fs;
normalizedAcGram = zeros(fftl,length(tickLocations));
%--------
myGUIdata.frameShiftb4 = frameShift;
myGUIdata.frameLengthb4 = frameLength;
myGUIdata.windowLengthInSampleb4 = windowLengthInSample;
myGUIdata.fsb4 = fsb4;
myGUIdata.baseIndexb4 = baseIndex;
myGUIdata.tickLocationsb4 = tickLocations;
myGUIdata.tickIndexb4 = (1:length(tickLocations))';
myGUIdata.fftlb4 = fftl;
myGUIdata.wb4 = w;
myGUIdata.hanningLPFb4 = hanningLPF;
myGUIdata.lagWindowForDFTb4 = lagWindowForDFT;
myGUIdata.mainLagWindowb4 = mainLagWindow;
myGUIdata.normalizedAcGram = normalizedAcGram;
myGUIdata.countStarted = false;
%myGUIdata.tickB4ID = 0;
%myGUIdata
end
%    xSegment = xb4(max(1,min(length(xb4),baseIndex+round(tickLocations(ii)*fsb4))));
%    pw = abs(fft(xSegment.*w,fftl)).^2;
%    ac = real(ifft(pw));
%    normalizedPw = hanningLPF.*pw./fft(ac.*lagWindowForDFT);
%    normalizedAc = real(ifft(normalizedPw))./mainLagWindow;
%    mormalizedAcGram(:,ii) = normalizedAc/normalizedAc(1)/10;

function fineF0Server(obj, event, string_arg)
handleForTimer = get(obj,'userData');
myGUIdata = guidata(handleForTimer);
fs = myGUIdata.samplingFrequency;
bias = round(myGUIdata.frameLengthb4/2*myGUIdata.fsb4);
%myGUIdata.tickB4ID = myGUIdata.tickB4ID+1;
%x = myGUIdata.tmpAudio;
tmpIndex = length(myGUIdata.tmpAudio)-(round(myGUIdata.frameLengthb4*fs)+1+round(myGUIdata.frameShiftb4*fs*5)):length(myGUIdata.tmpAudio);
if length(tmpIndex) > myGUIdata.windowLengthInSampleb4
    x = myGUIdata.tmpAudio(max(1,tmpIndex));
    currentIndex = myGUIdata.maxTargetPoint-myGUIdata.audioRecorderCount;
    if currentIndex > 0
        xb4 = x(1:4:end);
        t0 = 1/myGUIdata.fsb4;
        ydata = get(myGUIdata.fineF0Handle,'ydata');
        %ydata2nd = get(myGUIdata.fine2ndF0Handle,'ydata');
        if 1 == 1
            for ii = 1:5
                xSegment = xb4(max(1,min(length(xb4),bias+myGUIdata.baseIndexb4+round(myGUIdata.frameShiftb4*(ii-1)*myGUIdata.fsb4))));
                pw = abs(fft(xSegment.*myGUIdata.wb4,myGUIdata.fftlb4)).^2;
                ac = real(ifft(pw));
                normalizedPw = myGUIdata.hanningLPFb4.*pw./fft(ac.*myGUIdata.lagWindowForDFTb4);
                normalizedAc = real(ifft(normalizedPw))./myGUIdata.mainLagWindowb4;
                normalizedAc = normalizedAc/normalizedAc(1)/10;
                %[peakLevel,maxpos] = max(normalizedAc(1:150));
                %bestLag = (peakIdx-1)*t0;
                [peakLevel,maxpos] = max(normalizedAc(1:150));
                maxpos = max(2,maxpos);
                bestLag = (0.5*(normalizedAc(maxpos-1)-normalizedAc(maxpos+1))/ ...
                    (normalizedAc(maxpos-1)+normalizedAc(maxpos+1)-2*normalizedAc(maxpos))+maxpos-1)*t0;
                notePosition = max(-7,min(myGUIdata.noteID(end)+1,(12*log2(1/bestLag/110))));
                if peakLevel > 0.55
                    ydata(min(length(ydata),ii+(currentIndex-1)*5)) = notePosition;
                else
                    %ydata2nd(min(length(ydata),ii+(currentIndex-1)*5)) = notePosition;
                end;
            end;
            %disp(num2str(peakLevel))
            set(myGUIdata.fineF0Handle,'ydata',ydata);
            %set(myGUIdata.fine2ndF0Handle,'ydata',ydata2nd);
        end;
    end;
end;
end

function modeRadioButterServer(obj, event, string_arg)
myGUIdata = get(obj,'userdata');
%disp('selection changed');
switch get(myGUIdata.noteRadioButton,'value')
    case 1
        set(myGUIdata.noteAxis,'ytick',myGUIdata.noteID,'ytickLabel',myGUIdata.noteName);
    otherwise
        set(myGUIdata.noteAxis,'ytick',myGUIdata.freqtickLocation,'ytickLabel',myGUIdata.freqTickLabel);
end
end

% --- private function
function synchDrawGUI(obj, event, string_arg)
handleForTimer = get(obj,'userData');
myGUIdata = guidata(handleForTimer);
fftl = myGUIdata.fftl;
numberOfSamples = fftl*6;
if get(myGUIdata.recordObj1,'TotalSamples') > numberOfSamples
    myGUIdata.tmpAudio = getaudiodata(myGUIdata.recordObj1);
    guidata(handleForTimer,myGUIdata);
    switch get(myGUIdata.timerForWaveDraw,'running')
        case 'off'
            start(myGUIdata.timerForWaveDraw);
    end;
    switch get(myGUIdata.timerForKurtosisBar,'running')
        case 'off'
            start(myGUIdata.timerForKurtosisBar);
    end;
    %timerForFineF0
    switch get(myGUIdata.timerForFineF0,'running')
        case 'off'
            start(myGUIdata.timerForFineF0);
    end;
    switch get(myGUIdata.timerForSpectrumBar,'running')
        case 'off'
            start(myGUIdata.timerForSpectrumBar);
    end;
    if myGUIdata.audioRecorderCount < 0
        fps = (myGUIdata.maxAudioRecorderCount+1)/etime(datevec(now),myGUIdata.startTime);
        switch get(myGUIdata.timer50ms,'running')
            case 'on'
                stop(myGUIdata.timer50ms);
        end
        stop(myGUIdata.recordObj1);
        set(myGUIdata.fpsText,'string',[num2str(fps,'%02.1f') ' fps']);
        set(myGUIdata.periodicHandle,'ydata',myGUIdata.tAxis+NaN);
        set(myGUIdata.peakyHandle,'ydata',myGUIdata.tAxis+NaN);
        %myGUIdata.peakyData = myGUIdata.tAxis+NaN;
        set(myGUIdata.onsetHandle,'ydata',myGUIdata.tAxis+NaN);
        %myGUIdata.onsetData = myGUIdata.tAxis+NaN;
        set(myGUIdata.powerHandle,'ydata',myGUIdata.tAxis+NaN);
        set(myGUIdata.noteHandle,'ydata',myGUIdata.tAxis*0+NaN);
        set(myGUIdata.fineF0Handle,'ydata',myGUIdata.fineTimeAxis*0+NaN);
        %set(myGUIdata.fine2ndF0Handle,'ydata',myGUIdata.fineTimeAxis*0+NaN);
        record(myGUIdata.recordObj1);
        myGUIdata.audioRecorderCount = myGUIdata.maxAudioRecorderCount;
        switch get(myGUIdata.timer50ms,'running')
            case 'off'
                start(myGUIdata.timer50ms);
        end
        myGUIdata.countStarted = false;
    else
        if ~myGUIdata.countStarted
            myGUIdata.countStarted = true;
            myGUIdata.startTime = datevec(now);
        end;
        %set(myGUIdata.peakyHandle,'ydata',myGUIdata.peakyData);
        %set(myGUIdata.onsetHandle,'ydata',myGUIdata.onsetData);
        set(myGUIdata.countText,'String',num2str(myGUIdata.audioRecorderCount));
        myGUIdata.audioRecorderCount = myGUIdata.audioRecorderCount-1;
        x = myGUIdata.tmpAudio(end-myGUIdata.windowSizeInSample+1:end);
        rawPower = abs(fft(x.*myGUIdata.window,myGUIdata.fftl)).^2/myGUIdata.fftl;
        %cumulatedPower = cumsum(rawPmower);
        myGUIdata.lastLastLevel = myGUIdata.lastLevel;
        myGUIdata.lastLevel = 10*log10(sum(rawPower));
    end;
end;
%drawnow
peakyData = get(myGUIdata.peakyHandle,'ydata');
onsetData = get(myGUIdata.onsetHandle,'ydata');
guidata(handleForTimer,myGUIdata);
%drawnow;
end

function waveDrawServer(obj, event, string_arg)
handleForTimer = get(obj,'userData');
myGUIdata = guidata(handleForTimer);
xdata = get(myGUIdata.waveHandle,'xdata');
ydata = myGUIdata.tmpAudio(end-length(xdata)+1:end);
set(myGUIdata.waveHandle,'ydata',ydata);
set(myGUIdata.waveformViewerAxis,'ylim',max(abs(ydata))*[-1 1]);
end

function kurtosisBarServer(obj, event, string_arg)
handleForTimer = get(obj,'userData');
myGUIdata = guidata(handleForTimer);
x = myGUIdata.tmpAudio(end-(myGUIdata.windowSizeInSample+length(myGUIdata.kurtosisHPF))+1:end);
xx = fftfilt(myGUIdata.kurtosisHPF,x);
xx = xx(length(myGUIdata.kurtosisHPF):end);
kutrosisValue = mean(xx.^4)/mean(xx.^2)^2;
set(myGUIdata.kurtosisBarHandle,'ydata',max(0,min(myGUIdata.kurtosisLimit,kutrosisValue)));
ydataPeaky = get(myGUIdata.peakyHandle,'ydata');
currentIndex = myGUIdata.maxTargetPoint-myGUIdata.audioRecorderCount;
if kutrosisValue > 5.9; % p < 10^(-4) for exp. dist (3.7 % p < 10^(-5) for normal distribution)
    ydataPeaky(max(1,min(myGUIdata.maxTargetPoint,currentIndex))) = 2;
    %myGUIdata.peakyData(max(1,min(myGUIdata.maxTargetPoint,currentIndex))) = 2;
    set(myGUIdata.kurtosisBarHandle,'facecolor','m');
    set(myGUIdata.peakyHandle,'ydata',ydataPeaky);
else
    set(myGUIdata.kurtosisBarHandle,'facecolor',[0.6 0 0.6]);
end;
set(myGUIdata.totalPowerBarHandle,'ydata',max(0,min(90,90+20*log10(std(x)))));
%guidata(handleForTimer,myGUIdata);
end

function spectrumBarServer(obj, event, string_arg)
handleForTimer = get(obj,'userData');
myGUIdata = guidata(handleForTimer);
x = myGUIdata.tmpAudio(end-myGUIdata.windowSizeInSample+1:end);
rawPower = abs(fft(x.*myGUIdata.window,myGUIdata.fftl)).^2/myGUIdata.fftl;
cumulatedPower = cumsum(rawPower);
powerH = interp1(myGUIdata.fAxis,cumulatedPower,myGUIdata.fHigh);
powerL = interp1(myGUIdata.fAxis,cumulatedPower,myGUIdata.fLow);
bandPower = (powerH-powerL)/cumulatedPower(end)*2*std(x)^2;
ydata = max(0,min(90,90+10*log10(bandPower)));
set(myGUIdata.barHandle,'ydata',ydata);
ydataPower = get(myGUIdata.powerHandle,'ydata');
currentIndex = myGUIdata.maxTargetPoint-myGUIdata.audioRecorderCount;
ydataPower(max(1,min(myGUIdata.maxTargetPoint,currentIndex))) = ...
    3+max(0,min(2,1.5+2.5/80*10*log10(cumulatedPower(end))));
set(myGUIdata.powerHandle,'ydata',ydataPower);
if myGUIdata.lastLevel+myGUIdata.jumpLimit < 10*log10(cumulatedPower(end))
    ydataOnset = get(myGUIdata.onsetHandle,'ydata');
    ydataOnset(max(1,min(myGUIdata.maxTargetPoint,currentIndex))) = 1.5;
    set(myGUIdata.totalPowerBarHandle,'facecolor','r');
    set(myGUIdata.onsetHandle,'ydata',ydataOnset);
elseif (myGUIdata.lastLastLevel+myGUIdata.jumpLimit < 10*log10(cumulatedPower(end)))
    %ydataOnset = get(myGUIdata.onsetHandle,'ydata');
    %ydataOnset = myGUIdata.onsetData;
    ydataOnset = get(myGUIdata.onsetHandle,'ydata');
    %if isnan(ydataOnset(max(1,min(myGUIdata.maxTargetPoint,currentIndex-1))))
        ydataOnset(max(1,min(myGUIdata.maxTargetPoint,currentIndex-1))) = 1.5;
        %myGUIdata.onsetData = ydataOnset;
        set(myGUIdata.totalPowerBarHandle,'facecolor','r');
        set(myGUIdata.onsetHandle,'ydata',ydataOnset);
    %end;
else
    set(myGUIdata.totalPowerBarHandle,'facecolor','b');
end;
modifiedAutoCorrelation = real(ifft(rawPower.*myGUIdata.shaper));
modifiedAutoCorrelation = modifiedAutoCorrelation/modifiedAutoCorrelation(1);
modifiedAutoCorrelation = modifiedAutoCorrelation./myGUIdata.lagwindow;
[maxModifiedAutoCorrelation,lagIDx] = max(modifiedAutoCorrelation((myGUIdata.lagAxis>0.0005) & (myGUIdata.lagAxis<0.014)));
%truncatedLag = myGUIdata.lagAxis((myGUIdata.lagAxis>0.0005) & (myGUIdata.lagAxis<0.014));
%bestLag = truncatedLag(lagIDx);
set(myGUIdata.periodicityBarHandle,'ydata',maxModifiedAutoCorrelation);
if maxModifiedAutoCorrelation > 0.8%0.75
    ydataPeriod = get(myGUIdata.periodicHandle,'ydata');
    ydataPeriod(max(1,min(myGUIdata.maxTargetPoint,currentIndex))) = 1;
    set(myGUIdata.periodicHandle,'ydata',ydataPeriod);
    %notePosition = max(-7,min(myGUIdata.noteID(end)+1,(12*log2(1/bestLag/110))));
    %ydataNote = get(myGUIdata.noteHandle,'ydata');
    %if notePosition < myGUIdata.noteID(end)+1
    %    ydataNote(max(1,min(myGUIdata.maxTargetPoint,currentIndex))) = notePosition;
    %end;
    %set(myGUIdata.noteHandle,'ydata',ydataNote);
    set(myGUIdata.periodicityBarHandle,'facecolor','g');
else
    set(myGUIdata.periodicityBarHandle,'facecolor',[0 0.6 0]);
end;
cdata = myGUIdata.baseTrueColor;
rgbList = [sum(bandPower(1:20)) sum(bandPower(18:26)) sum(bandPower(25:end))];
rgbList = rgbList/max(rgbList);
cdata(:,:,1) = cdata(:,:,1)*rgbList(1);
cdata(:,:,2) = cdata(:,:,2)*rgbList(2);
cdata(:,:,3) = cdata(:,:,3)*rgbList(3);
set(myGUIdata.colorPadHandle,'cdata',cdata);
if 1 == 2
    myGUIdata.lastLastLevel = myGUIdata.lastLevel;
    myGUIdata.lastLevel = 10*log10(cumulatedPower(end));
    guidata(handleForTimer,myGUIdata);
end;
end

% --- Outputs from this function are returned to the command line.
function varargout = eventScopeR4_OutputFcn(hObject, eventdata, handles)
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;
end

% --- Executes on button press in startButton.
function startButton_Callback(hObject, eventdata, handles)
% hObject    handle to startButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
myGUIdata = guidata(handles.eventScopeGUI);
myGUIdata = startRealtime(myGUIdata);
set(myGUIdata.saveFileButton,'enable','off');
guidata(hObject, myGUIdata);
end

% --- Executes on button press in stopButton.
function stopButton_Callback(hObject, eventdata, handles)
% hObject    handle to stopButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
myGUIdata = guidata(handles.eventScopeGUI);
%disp('timer ends')
switch get(myGUIdata.timer50ms,'running')
    case 'on'
        stop(myGUIdata.timer50ms)
end;
stop(myGUIdata.recordObj1);
set(myGUIdata.stopButton,'enable','off');
set(myGUIdata.startButton,'enable','on');
set(myGUIdata.saveFileButton,'enable','on');
end

% --- Executes on button press in quitButton.
function quitButton_Callback(hObject, eventdata, handles)
% hObject    handle to quitButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
myGUIdata = guidata(handles.eventScopeGUI);
%disp('timer ends')
switch get(myGUIdata.timer50ms,'running')
    case 'on'
        stop(myGUIdata.timer50ms)
end;
stop(myGUIdata.recordObj1);
delete(myGUIdata.timer50ms);
delete(myGUIdata.recordObj1);
delete(myGUIdata.timerForWaveDraw);
delete(myGUIdata.timerForSpectrumBar);
delete(myGUIdata.timerForKurtosisBar);
delete(myGUIdata.timerForFineF0);
close(handles.eventScopeGUI);
end


% --- If Enable == 'on', executes on mouse press in 5 pixel border.
% --- Otherwise, executes on mouse press in 5 pixel border or over noteRadioButton.
function noteRadioButton_ButtonDownFcn(hObject, eventdata, handles)
% hObject    handle to noteRadioButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
end


% --- If Enable == 'on', executes on mouse press in 5 pixel border.
% --- Otherwise, executes on mouse press in 5 pixel border or over freqRadioButton.
function freqRadioButton_ButtonDownFcn(hObject, eventdata, handles)
% hObject    handle to freqRadioButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
end


% --- Executes during object creation, after setting all properties.
function axisModePanel_CreateFcn(hObject, eventdata, handles)
% hObject    handle to axisModePanel (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called
end


% --------------------------------------------------------------------
function axisModePanel_ButtonDownFcn(hObject, eventdata, handles)
% hObject    handle to axisModePanel (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
myGUIdata = get(hObject,'userdata');
%disp('axisModePanel was hit');
switch get(myGUIdata.freqRadioButton,'value')
    case 1
        set(myGUIdata.noteAxis,'ytick',myGUIdata.freqtickLocation,'ytickLabel',myGUIdata.freqTickLabel);
    otherwise
        set(myGUIdata.noteAxis,'ytick',myGUIdata.noteID,'ytickLabel',myGUIdata.noteName);
end;
end

% --- Executes on button press in saveFileButton.
function saveFileButton_Callback(hObject, eventdata, handles)
% hObject    handle to saveFileButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
myGUIdata = guidata(handles.eventScopeGUI);
outFileName = ['eventData' datestr(now,30) '.wav'];
[file,path] = uiputfile(outFileName,'Save the captured data');
if length(file) == 1 && length(path) == 1
    if file == 0 || path == 0
        %okInd = 0;
        disp('Save is cancelled!');
        return;
    end;
end;
audiowrite([path file],myGUIdata.tmpAudio,myGUIdata.samplingFrequency);
end
