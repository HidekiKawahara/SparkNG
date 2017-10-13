function varargout = realtimeSpectrogramV3(varargin)
%   Running spectrogram in realtime. Type:
%   realtimeSpectrogramV3
%   to start.

%   Designed and coded by Hideki Kawahara (kawahara AT sys.wakayama-u.ac.jp)
%   19/Dec./2013
%   20/Dec./2013 added dynamic range control and zooming and pan tools
%   21/Dec./2013 bug fix. Please excuse me!
%   22/Dec./2013 added wide-band spectrogram, 1/3 band, ERB_N number, Bark
%                filter bank simulators
%   24/Dec./2013 bug fix of frequency axis labels
%   31/Aug./2015 machine independent and resizable

% This work is licensed under the Creative Commons 
% Attribution 4.0 International License.
% To view a copy of this license, visit
% http://creativecommons.org/licenses/by/4.0/.

% REALTIMESPECTROGRAMV3 MATLAB code for realtimeSpectrogramV3.fig
%      REALTIMESPECTROGRAMV3, by itself, creates a new REALTIMESPECTROGRAMV3 or raises the existing
%      singleton*.
%
%      H = REALTIMESPECTROGRAMV3 returns the handle to a new REALTIMESPECTROGRAMV3 or the handle to
%      the existing singleton*.
%
%      REALTIMESPECTROGRAMV3('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in REALTIMESPECTROGRAMV3.M with the given input arguments.
%
%      REALTIMESPECTROGRAMV3('Property','Value',...) creates a new REALTIMESPECTROGRAMV3 or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before realtimeSpectrogramV3_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to realtimeSpectrogramV3_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help realtimeSpectrogramV3

% Last Modified by GUIDE v2.5 21-Dec-2013 23:28:52

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
    'gui_Singleton',  gui_Singleton, ...
    'gui_OpeningFcn', @realtimeSpectrogramV3_OpeningFcn, ...
    'gui_OutputFcn',  @realtimeSpectrogramV3_OutputFcn, ...
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

% --- Executes just before realtimeSpectrogramV3 is made visible.
function realtimeSpectrogramV3_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to realtimeSpectrogramV3 (see VARARGIN)

% Choose default command line output for realtimeSpectrogramV3
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);
%handles
delete(timerfindall);
initializeDisplay(handles);
myGUIdata = guidata(handles.realTimeSgramGUI);
%myGUIdata
timerEventInterval = 0.1; % in second
%timerEventInterval = 0.075; % in second
timer50ms = timer('TimerFcn',@synchDrawGUI, 'Period',timerEventInterval,'ExecutionMode','fixedRate', ...
    'userData',handles.realTimeSgramGUI);
%handleForTimer = handles.multiScopeMainGUI; % global
myGUIdata.timer50ms = timer50ms;
myGUIdata.smallviewerWidth = 30; % 30 ms is defaule
myGUIdata.recordObj1 = audiorecorder(myGUIdata.samplingFrequency,24,1);
set(myGUIdata.recordObj1,'TimerPeriod',0.1);
record(myGUIdata.recordObj1)
myGUIdata.maxAudioRecorderCount = 200;
myGUIdata.maxLevel = -100;
myGUIdata.audioRecorderCount = myGUIdata.maxAudioRecorderCount;
myGUIdata.displayTypeList = cellstr(get(myGUIdata.displayPopupMenu,'String'));
%myGUIdata.displayTypeList = myGUIdata.displayTypeList(1:2);
set(myGUIdata.displayPopupMenu,'String',myGUIdata.displayTypeList)
myGUIdata.displayType = myGUIdata.displayTypeList{1};
guidata(handles.realTimeSgramGUI,myGUIdata);
startButton_Callback(hObject, eventdata, handles)
% UIWAIT makes realtimeSpectrogramV3 wait for user response (see UIRESUME)
% uiwait(handles.realTimeSgramGUI);
end

function initializeDisplay(handles)
myGUIdata = guidata(handles.realTimeSgramGUI);
myGUIdata.samplingFrequency = 44100;
axes(handles.sgramAxis);
myGUIdata = settingForWideband(myGUIdata);
fxx = myGUIdata.visibleFrequencyAxis;
tx = myGUIdata.timeAxis;
myGUIdata.sgramHandle = image([tx(1) tx(end)]-tx(end),[fxx(1) fxx(end)],myGUIdata.initialSgramData);
axis('xy');
set(gca,'fontunit','normalized','fontsize',0.025);
myGUIdata.linearTicLocationListWide = get(handles.sgramAxis,'ytick');
myGUIdata.linearTickLabelListWide = get(handles.sgramAxis,'ytickLabel');
myGUIdata = settingForNarrowband(myGUIdata);
fxx = myGUIdata.visibleFrequencyAxis;
tx = myGUIdata.timeAxis;
myGUIdata.sgramHandle = image([tx(1) tx(end)]-tx(end),[fxx(1) fxx(end)],myGUIdata.initialSgramData);
set(gca,'fontunit','normalized','fontsize',0.03);
axis('xy');
%colormap(1-gray)
myGUIdata.titleText = title('Narrowband spectrogram','fontunit','normalized','fontsize',0.03);
xlabel('time (s)');
ylabel('frequency (Hz)')
myGUIdata.linearTicLocationList = get(handles.sgramAxis,'ytick');
myGUIdata.linearTickLabelList = get(handles.sgramAxis,'ytickLabel');
set(myGUIdata.dynamicRanbeText,'string',[num2str(myGUIdata.dynamicRange,'%3.0f') ' dB']);
%set(myGUIdata.sgramHandle,'erasemode','none');
set(myGUIdata.displayPopupMenu,'enable','off');
drawnow;
guidata(handles.realTimeSgramGUI,myGUIdata);
end

%--- private function for make it narrow spectrogram
function myGUIdata = settingForNarrowband(myGUIdata)
myGUIdata.windowLengthInMs = 80; %80
myGUIdata.higherFrequencyLimit = 3600;
fs = myGUIdata.samplingFrequency;
fftl = 2^ceil(log2(myGUIdata.windowLengthInMs*fs/1000));
%fftl = 1024;
fx = (0:fftl/2)/fftl*fs;
fxx = fx(fx<myGUIdata.higherFrequencyLimit);
frameShift = 0.007;
tx = 0:frameShift:4;
myGUIdata.initialSgramData = rand(length(fxx),length(tx))*62+1;
myGUIdata.frameShift = frameShift;
myGUIdata.visibleFrequencyAxis = fxx;
myGUIdata.timeAxis = tx;
myGUIdata.fftl = fftl;
myGUIdata.fftBuffer = zeros(fftl,length(tx));
myGUIdata.lastPosition = 1;
myGUIdata.frameShiftInSample = round(myGUIdata.frameShift*fs);
%myGUIdata.windowFunction = blackman(round(myGUIdata.windowLengthInMs*fs/1000));
myGUIdata.windowFunction = nuttallwin(round(myGUIdata.windowLengthInMs*fs/1000));
myGUIdata.windowLengthInSample = length(myGUIdata.windowFunction);
myGUIdata.dynamicRange = 80;
set(myGUIdata.dynamicRangeSlider,'Value',0.2);
set(myGUIdata.dynamicRanbeText,'string',[num2str(myGUIdata.dynamicRange,'%3.0f') ' dB']);
myGUIdata.maxLevel = -100;
end

%--- private function for make it narrow spectrogram
function myGUIdata = settingForThirdband(myGUIdata)
myGUIdata.windowLengthInMs = 80;
myGUIdata.higherFrequencyLimit = 3600;
fs = myGUIdata.samplingFrequency;
fftl = 2^ceil(log2(myGUIdata.windowLengthInMs*fs/1000));
%fftl = 1024;
fx = (0:fftl/2)/fftl*fs;
%fxx = fx(fx<myGUIdata.higherFrequencyLimit);
frameShift = 0.007;
tx = 0:frameShift:4;
myGUIdata.initialSgramData = rand(length(fx),length(tx))*62+1;
switch get(myGUIdata.displayPopupMenu,'Value')
    case 5
        filterBankStr = simulatedFilterBank(myGUIdata.initialSgramData,fx,'third');
    case 3
        filterBankStr = simulatedFilterBank(myGUIdata.initialSgramData,fx,'ERB');
    case 4
        filterBankStr = simulatedFilterBank(myGUIdata.initialSgramData,fx,'Bark');
end;
myGUIdata.initialSgramData = filterBankStr.filteredSgramTriangle;
myGUIdata.frameShift = frameShift;
myGUIdata.visibleFrequencyAxis = filterBankStr.fcList;
myGUIdata.timeAxis = tx;
myGUIdata.fftl = fftl;
myGUIdata.fftBuffer = zeros(fftl,length(tx));
myGUIdata.lastPosition = 1;
myGUIdata.frameShiftInSample = round(myGUIdata.frameShift*fs);
%myGUIdata.windowFunction = blackman(round(myGUIdata.windowLengthInMs*fs/1000));
myGUIdata.windowFunction = nuttallwin(round(myGUIdata.windowLengthInMs*fs/1000));
myGUIdata.windowLengthInSample = length(myGUIdata.windowFunction);
myGUIdata.ticLocationList = filterBankStr.ticLocationList;
myGUIdata.tickLabelList = filterBankStr.tickLabelList;
myGUIdata.dynamicRange = 80;
set(myGUIdata.dynamicRangeSlider,'Value',0.2);
set(myGUIdata.dynamicRanbeText,'string',[num2str(myGUIdata.dynamicRange,'%3.0f') ' dB']);
myGUIdata.maxLevel = -100;
end

%--- private function for make it wide spectrogram
function myGUIdata = settingForWideband(myGUIdata)
myGUIdata.windowLengthInMs = 10;
myGUIdata.higherFrequencyLimit = 8000;
fs = myGUIdata.samplingFrequency;
fftl = 2^ceil(log2(myGUIdata.windowLengthInMs*fs/1000)+1);
%fftl = 1024;
fx = (0:fftl/2)/fftl*fs;
fxx = fx(fx<myGUIdata.higherFrequencyLimit);
frameShift = 0.0005;
tx = 0:frameShift:1;
myGUIdata.initialSgramData = rand(length(fxx),length(tx))*62+1;
myGUIdata.frameShift = frameShift;
myGUIdata.visibleFrequencyAxis = fxx;
myGUIdata.timeAxis = tx;
myGUIdata.fftl = fftl;
myGUIdata.fftBuffer = zeros(fftl,length(tx));
myGUIdata.lastPosition = 1;
myGUIdata.frameShiftInSample = round(myGUIdata.frameShift*fs);
%myGUIdata.windowFunction = blackman(round(myGUIdata.windowLengthInMs*fs/1000));
myGUIdata.windowFunction = nuttallwin(round(myGUIdata.windowLengthInMs*fs/1000));
myGUIdata.windowLengthInSample = length(myGUIdata.windowFunction);
myGUIdata.dynamicRange = 80;
set(myGUIdata.dynamicRangeSlider,'Value',0.2);
set(myGUIdata.dynamicRanbeText,'string',[num2str(myGUIdata.dynamicRange,'%3.0f') ' dB']);
myGUIdata.maxLevel = -100;
end

function synchDrawGUI(obj, event, string_arg)
handleForTimer = get(obj,'userData');
myGUIdata = guidata(handleForTimer);
numberOfSamples = myGUIdata.windowLengthInSample;
dynamicRange = myGUIdata.dynamicRange;
fftl = myGUIdata.fftl;
w = myGUIdata.windowFunction;
fxx = myGUIdata.visibleFrequencyAxis;
fs = myGUIdata.samplingFrequency;
if get(myGUIdata.recordObj1,'TotalSamples') > fftl*4
    tmpAudio = getaudiodata(myGUIdata.recordObj1);
    currentPoint = length(tmpAudio);
    if length(currentPoint-numberOfSamples+1:currentPoint) > 10
        set(myGUIdata.counterText,'string',num2str(myGUIdata.audioRecorderCount));
        myGUIdata.audioRecorderCount = myGUIdata.audioRecorderCount-1;
        spectrogramBuffer = get(myGUIdata.sgramHandle,'cdata');
        ii = 0;
        while myGUIdata.lastPosition+myGUIdata.frameShiftInSample+numberOfSamples < currentPoint
            ii = ii+1;
            currentIndex = myGUIdata.lastPosition+myGUIdata.frameShiftInSample;
            x = tmpAudio(currentIndex+(0:numberOfSamples-1));
            switch get(myGUIdata.displayPopupMenu,'Value')
                case {1,2}
                    tmpSpectrum = 20*log10(abs(fft(x.*w,fftl)));
                case {3,4,5}
                    tmpSpectrum = abs(fft(x.*w,fftl)).^2;
            end;
            myGUIdata.fftBuffer(:,ii) = tmpSpectrum;
            myGUIdata.lastPosition = currentIndex;
        end;
        nFrames = ii;
        if nFrames > 0
            tmpSgram = myGUIdata.fftBuffer(:,1:nFrames);
            switch get(myGUIdata.displayPopupMenu,'Value')
                case 5
                    fx = (0:fftl/2)/fftl*fs;
                    filterBankStr = simulatedFilterBank(tmpSgram(1:fftl/2+1,:),fx,'third');
                    tmpSgram = 10*log10(filterBankStr.filteredSgramTriangle);
                case 3
                    fx = (0:fftl/2)/fftl*fs;
                    filterBankStr = simulatedFilterBank(tmpSgram(1:fftl/2+1,:),fx,'ERB');
                    tmpSgram = 10*log10(filterBankStr.filteredSgramTriangle); 
                case 4
                    fx = (0:fftl/2)/fftl*fs;
                    filterBankStr = simulatedFilterBank(tmpSgram(1:fftl/2+1,:),fx,'Bark');
                    tmpSgram = 10*log10(filterBankStr.filteredSgramTriangle); 
            end;
            if myGUIdata.maxLevel < max(tmpSgram(:))
                myGUIdata.maxLevel = max(tmpSgram(:));
            else
                myGUIdata.maxLevel = max(-100,myGUIdata.maxLevel*0.998);
            end;
            tmpSgram = 62*max(0,(tmpSgram-myGUIdata.maxLevel)+dynamicRange)/dynamicRange+1;
            spectrogramBuffer(:,1:end-nFrames) = spectrogramBuffer(:,nFrames+1:end);
            spectrogramBuffer(:,end-nFrames+1:end) = tmpSgram(1:length(fxx),:);
            set(myGUIdata.sgramHandle,'cdata',spectrogramBuffer);
        else
            disp('no data read!');
        end;
    else
        disp('overrun!')
    end;
    if myGUIdata.audioRecorderCount < 0
        switch get(myGUIdata.timer50ms,'running')
            case 'on'
                stop(myGUIdata.timer50ms);
        end
        disp('Initilizing audio buffer');
        stop(myGUIdata.recordObj1);
        record(myGUIdata.recordObj1);
        myGUIdata.audioRecorderCount = myGUIdata.maxAudioRecorderCount;
        myGUIdata.lastPosition = 1;
        switch get(myGUIdata.timer50ms,'running')
            case 'off'
                start(myGUIdata.timer50ms);
        end
    end;
    guidata(handleForTimer,myGUIdata);
else
    disp(['Recorded data is not enough! Skipping this interruption....at ' datestr(now,30)]);
end;
end

% --- Outputs from this function are returned to the command line.
function varargout = realtimeSpectrogramV3_OutputFcn(hObject, eventdata, handles)
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
myGUIdata = guidata(handles.realTimeSgramGUI);
set(myGUIdata.saveButton,'enable','off');
set(myGUIdata.startButton,'enable','off');
set(myGUIdata.playButton,'enable','off');
set(myGUIdata.stopButton,'enable','on');
set(myGUIdata.displayPopupMenu,'enable','off');
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
guidata(handles.realTimeSgramGUI,myGUIdata);
end

% --- Executes on button press in stopButton.
function stopButton_Callback(hObject, eventdata, handles)
% hObject    handle to stopButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
myGUIdata = guidata(handles.realTimeSgramGUI);
set(myGUIdata.saveButton,'enable','on');
set(myGUIdata.startButton,'enable','on');
set(myGUIdata.playButton,'enable','on');
set(myGUIdata.stopButton,'enable','off');
set(myGUIdata.displayPopupMenu,'enable','on');
switch get(myGUIdata.timer50ms,'running')
    case 'on'
        stop(myGUIdata.timer50ms)
    case 'off'
    otherwise
        disp('timer is bloken!');
end;
myGUIdata.audioData = getaudiodata(myGUIdata.recordObj1);
stop(myGUIdata.recordObj1);
guidata(handles.realTimeSgramGUI,myGUIdata);
end

% --- Executes on button press in playButton.
function playButton_Callback(hObject, eventdata, handles)
% hObject    handle to playButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
myGUIdata = guidata(handles.realTimeSgramGUI);
x = myGUIdata.audioData;
fs = myGUIdata.samplingFrequency;
minus4 = max(1,round((length(x)/fs-4)*fs));
sound(x(minus4:end)/max(abs(x(minus4:end)))*0.99,fs);
end

% --- Executes on button press in saveButton.
function saveButton_Callback(hObject, eventdata, handles)
% hObject    handle to saveButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
myGUIdata = guidata(handles.realTimeSgramGUI);
outFileName = ['relFFTIn' datestr(now,30) '.wav'];
[file,path] = uiputfile(outFileName,'Save the last 4 second data');
if length(file) == 1 && length(path) == 1
    if file == 0 || path == 0
        %okInd = 0;
        disp('Save is cancelled!');
        return;
    end;
end;
wavwrite(myGUIdata.audioData,myGUIdata.samplingFrequency,16,[path file]);
end

% --- Executes on button press in quitButton.
function quitButton_Callback(hObject, eventdata, handles)
% hObject    handle to quitButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
myGUIdata = guidata(handles.realTimeSgramGUI);
%disp('timer ends')
switch get(myGUIdata.timer50ms,'running')
    case 'on'
        stop(myGUIdata.timer50ms)
end;
stop(myGUIdata.recordObj1);
delete(myGUIdata.timer50ms);
delete(myGUIdata.recordObj1);
close(handles.realTimeSgramGUI);
end


% --- Executes on slider movement.
function dynamicRangeSlider_Callback(hObject, eventdata, handles)
% hObject    handle to dynamicRangeSlider (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'Value') returns position of slider
%        get(hObject,'Min') and get(hObject,'Max') to determine range of slider
myGUIdata = guidata(handles.realTimeSgramGUI);
value = get(hObject,'Value');
myGUIdata.dynamicRange = max(1,abs((value-1)*100));
set(myGUIdata.dynamicRanbeText,'string',[num2str(myGUIdata.dynamicRange,'%3.0f') ' dB']);
guidata(handles.realTimeSgramGUI,myGUIdata);
end

% --- Executes during object creation, after setting all properties.
function dynamicRangeSlider_CreateFcn(hObject, eventdata, handles)
% hObject    handle to dynamicRangeSlider (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end
set(hObject,'value',0.2);
end


% --- Executes on selection change in displayPopupMenu.
function displayPopupMenu_Callback(hObject, eventdata, handles)
% hObject    handle to displayPopupMenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns displayPopupMenu contents as cell array
%        contents{get(hObject,'Value')} returns selected item from displayPopupMenu
myGUIdata = guidata(handles.realTimeSgramGUI);
%disp('hit!')
contents = cellstr(get(hObject,'String'));
myGUIdata.displayType = contents{get(hObject,'Value')};
switch get(myGUIdata.timer50ms,'running')
    case 'on'
        stop(myGUIdata.timer50ms)
    case 'off'
    otherwise
        disp('timer is bloken!');
end;
switch get(hObject,'Value')
    case 1
        myGUIdata = settingForNarrowband(myGUIdata);
        set(myGUIdata.sgramHandle,'cdata',myGUIdata.initialSgramData*0+1);%, ...
        set(myGUIdata.sgramHandle,'xdata',[myGUIdata.timeAxis(1) myGUIdata.timeAxis(end)]-myGUIdata.timeAxis(end), ...
            'ydata',[myGUIdata.visibleFrequencyAxis(1) myGUIdata.visibleFrequencyAxis(end)]);
        set(myGUIdata.sgramAxis,'xlim',[myGUIdata.timeAxis(1) myGUIdata.timeAxis(end)]-myGUIdata.timeAxis(end), ...
            'ylim',[myGUIdata.visibleFrequencyAxis(1) myGUIdata.visibleFrequencyAxis(end)]);
        set(myGUIdata.sgramAxis,'ytick',myGUIdata.linearTicLocationList);
        set(myGUIdata.sgramAxis,'ytickLabel',myGUIdata.linearTickLabelList);
        set(myGUIdata.titleText,'string','Narrowband spectrogram','fontunit','normalized','fontsize',0.03);
        enableZoomingTools(myGUIdata);
    case 2
        myGUIdata = settingForWideband(myGUIdata);
        set(myGUIdata.sgramHandle,'cdata',myGUIdata.initialSgramData*0+1);%, ...
        set(myGUIdata.sgramHandle,'xdata',[myGUIdata.timeAxis(1) myGUIdata.timeAxis(end)]-myGUIdata.timeAxis(end), ...
            'ydata',[myGUIdata.visibleFrequencyAxis(1) myGUIdata.visibleFrequencyAxis(end)]);
        set(myGUIdata.sgramAxis,'xlim',[myGUIdata.timeAxis(1) myGUIdata.timeAxis(end)]-myGUIdata.timeAxis(end), ...
            'ylim',[myGUIdata.visibleFrequencyAxis(1) myGUIdata.visibleFrequencyAxis(end)]);
        set(myGUIdata.titleText,'string','Wideband spectrogram','fontunit','normalized','fontsize',0.03);
        set(myGUIdata.sgramAxis,'ytick',myGUIdata.linearTicLocationListWide);
        set(myGUIdata.sgramAxis,'ytickLabel',myGUIdata.linearTickLabelListWide);
        enableZoomingTools(myGUIdata);
    case {3,4,5}
        myGUIdata = settingForThirdband(myGUIdata);
        set(myGUIdata.sgramHandle,'cdata',myGUIdata.initialSgramData*0+1);%, ...
        set(myGUIdata.sgramHandle,'xdata',[myGUIdata.timeAxis(1) myGUIdata.timeAxis(end)]-myGUIdata.timeAxis(end), ...
            'ydata',[myGUIdata.visibleFrequencyAxis(1) myGUIdata.visibleFrequencyAxis(end)]);
        set(myGUIdata.sgramAxis,'xlim',[myGUIdata.timeAxis(1) myGUIdata.timeAxis(end)]-myGUIdata.timeAxis(end), ...
            'ylim',[myGUIdata.visibleFrequencyAxis(1) myGUIdata.visibleFrequencyAxis(end)]);
        %keyboard;
        set(myGUIdata.sgramAxis,'ytick',myGUIdata.ticLocationList,'yticklabel',myGUIdata.tickLabelList);
        switch get(hObject,'Value')
            case 5
                set(myGUIdata.titleText,'string','Simulated 1/3 octave band filter, based on 80 ms Nuttallwin','fontunit','normalized','fontsize',0.03);
            case 3
                set(myGUIdata.titleText,'string','Simulated ERB_N filter, based on 80 ms Nuttallwin (temporal resolution is misleading!)','fontunit','normalized','fontsize',0.03);
            case 4
                set(myGUIdata.titleText,'string','Simulated Bark filter, based on 80 ms Nuttallwin (temporal resolution is misleading!)','fontunit','normalized','fontsize',0.03);
        end;
        disableZoomingTools(myGUIdata);
end
get(myGUIdata.sgramHandle)
%start(myGUIdata.timer50ms);
guidata(handles.realTimeSgramGUI,myGUIdata);
startButton_Callback(myGUIdata.startButton, eventdata, handles);
end

% --- Executes during object creation, after setting all properties.
function displayPopupMenu_CreateFcn(hObject, eventdata, handles)
% hObject    handle to displayPopupMenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
end

% ---- private functions
function enableZoomingTools(myGUIdata)
set(myGUIdata.uitoggletool3,'enable','on');
set(myGUIdata.uitoggletool2,'enable','on');
set(myGUIdata.uitoggletool1,'enable','on');
end

function disableZoomingTools(myGUIdata)
set(myGUIdata.uitoggletool3,'enable','off');
set(myGUIdata.uitoggletool2,'enable','off');
set(myGUIdata.uitoggletool1,'enable','off');
end
