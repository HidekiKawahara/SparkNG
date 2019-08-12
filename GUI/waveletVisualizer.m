function varargout = waveletVisualizer(varargin)
% WAVELETVISUALIZER MATLAB code for waveletVisualizer.fig
%      WAVELETVISUALIZER, by itself, creates a new WAVELETVISUALIZER or raises the existing
%      singleton*.
%
%      H = WAVELETVISUALIZER returns the handle to a new WAVELETVISUALIZER or the handle to
%      the existing singleton*.
%
%      WAVELETVISUALIZER('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in WAVELETVISUALIZER.M with the given input arguments.
%
%      WAVELETVISUALIZER('Property','Value',...) creates a new WAVELETVISUALIZER or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before waveletVisualizer_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to waveletVisualizer_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Designed and implemented by Hideki Kawahara
%
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

% Edit the above text to modify the response to help waveletVisualizer

% Last Modified by GUIDE v2.5 02-Dec-2018 00:37:38

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
    'gui_Singleton',  gui_Singleton, ...
    'gui_OpeningFcn', @waveletVisualizer_OpeningFcn, ...
    'gui_OutputFcn',  @waveletVisualizer_OutputFcn, ...
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

% --- Executes just before waveletVisualizer is made visible.
function waveletVisualizer_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to waveletVisualizer (see VARARGIN)

% Choose default command line output for waveletVisualizer
handles.output = hObject;
%--- user procedure starts
delete(timerfindall);
myGUIdata = guidata(hObject);
myGUIdata.handles = handles;
myGUIdata = setDefault(myGUIdata);
myGUIdata = initializeGraphics(myGUIdata);
%myGUIdata.displayAttribute = 'Phase';
timerEventInterval = 0.050; % in second
myGUIdata.timerEventInterval = timerEventInterval;
myGUIdata.avfoDisplay = 110;
%--- audio monitor preparation
myGUIdata.recordObj1 = audiorecorder(myGUIdata.samplingFrequency,24,1);
set(myGUIdata.recordObj1,'TimerPeriod',0.2);
myGUIdata.maxTargetPoint = 400;% This is for audio recorder
myGUIdata.maxAudioRecorderCount = myGUIdata.maxTargetPoint;
myGUIdata.audioRecorderCount = myGUIdata.maxAudioRecorderCount;
set(myGUIdata.counterTxt, 'String', num2str(myGUIdata.audioRecorderCount));
guidata(hObject, myGUIdata);
%myGUIdata
%--- wave draw timer preparation
timerForWaveDraw = timer('TimerFcn',@waveDrawServer,'ExecutionMode','fixedRate', ...
    'Period', timerEventInterval,'userData',hObject);
myGUIdata.timerForWaveDraw = timerForWaveDraw;
set(myGUIdata.startButton, 'enable', 'off');
set(myGUIdata.stopbutton, 'enable', 'on');
set(myGUIdata.quitbutton, 'enable', 'on');
set(myGUIdata.saveButton, 'enable', 'off');
set(myGUIdata.viewerWidthPopup, 'visible', 'off');
set(myGUIdata.fLowPopup, 'visible', 'off');
set(myGUIdata.fHighPopup, 'visible', 'off');
set(myGUIdata.stretchPopup, 'visible', 'off');
set(myGUIdata.defaultButton, 'visible', 'off');
guidata(hObject, myGUIdata);
myGUIdata = startRealtime(myGUIdata);
%---

myGUIdata.output = hObject;
%--- user procedure ends
% Update handles structure
%guidata(hObject, handles); This is original
guidata(hObject, myGUIdata);

% UIWAIT makes waveletVisualizer wait for user response (see UIRESUME)
% uiwait(handles.excitationViewerGUI);
end

% --- Outputs from this function are returned to the command line.
function varargout = waveletVisualizer_OutputFcn(hObject, eventdata, handles)
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;
end

%--- user defined supporting functions starts
function myGUIdata = setDefault(myGUIdata)
myGUIdata.samplingFrequency = 22050;
myGUIdata.channels_in_octave = 8;
myGUIdata.low_frequency = 110 * 2^(-1/3);%100;
myGUIdata.high_freuency = 5000;
myGUIdata.halfTimeSpan = 0.008; % 8 ms (default)
myGUIdata.fftl = 2048;
myGUIdata.stretching_factor = 1.0;
myGUIdata.synchPhase = -120;
set(myGUIdata.viewerWidthPopup, 'value', 3);
set(myGUIdata.fLowPopup, 'value', 3);
set(myGUIdata.fHighPopup, 'value', 2);
set(myGUIdata.stretchPopup, 'value', 2);
set(myGUIdata.phaseEdit, 'string', -120);
end

function waveDrawServer(obj, event, string_arg)
handleForTimer = get(obj,'userData');
myGUIdata = guidata(handleForTimer);
xdata = get(myGUIdata.waveHandle,'xdata');
wvltStr = myGUIdata.wvltStr;
fc_list = wvltStr.fc_list;
max_bias = wvltStr.wvlt(1).bias;
n_data = length(xdata);
channels_oct = myGUIdata.channels_in_octave;
base_index = 1:n_data;
buffer_index = 1:3 * n_data;
%buffer_index(end)
%size(myGUIdata.imageBuffer)
switch get(myGUIdata.recordObj1,'running')
    case 'on'
        if get(myGUIdata.recordObj1,'TotalSamples')  >  max_bias * 4 + 3 * n_data
            myGUIdata.tmpAudio = getaudiodata(myGUIdata.recordObj1);
            if length(myGUIdata.tmpAudio) >  max_bias * 4 + 3 * n_data
                x = myGUIdata.tmpAudio(end-(max_bias * 4 + 3 * n_data)+1:end);
                for ii = 1:myGUIdata.n_channles
                    y = fftfilt(wvltStr.wvlt(ii).w, x);
                    myGUIdata.imageBuffer(ii, :) = y(wvltStr.wvlt(ii).bias + wvltStr.wvlt(1).bias + buffer_index);
                end
                x_original = x(buffer_index + wvltStr.wvlt(1).bias);
                instFreqBuffer = angle(myGUIdata.imageBuffer ./ myGUIdata.imageBuffer(:, max(1, buffer_index - 1)));
                myGUIdata.imageBufferTmp = angle(myGUIdata.imageBuffer);
                rawSTD = (std(instFreqBuffer(:, 2:end)') * myGUIdata.samplingFrequency / 2 / pi) .^ 2;
                rawSTD = sqrt(rawSTD([1 1:end-1]) + rawSTD + rawSTD([2:end end]));
                fsdData = log(rawSTD(:) ./ fc_list(:));
                bw_list = 1 ./ ((2^(1/channels_oct/2)-2^(-1/channels_oct/2)) * fc_list * 2 * pi);
                gd_gram_raw = -diag(bw_list) * angle(myGUIdata.imageBuffer ./ ...
                    myGUIdata.imageBuffer([1 1:end-1], :));
                gd_gram = diag(fc_list) * gd_gram_raw;
                gdData = std(max(-1, min(1, gd_gram(:, 2:end)')));
                gdData(1) = gdData(2);
                gdData = log((gdData([1 1:end-1]) + gdData +gdData([2:end end])) / 3);
                mixData = gdData(:) + fsdData(:); % mixed cost function for fo
                [~, min_ch] = min(mixData);%gdData(:) + fsdData(:));
                fund_phase = angle(myGUIdata.imageBuffer(min_ch, :) * exp(-1i * myGUIdata.synchPhase / 360 * 2 * pi)); %myGUIdata.synchPhase
                avfo = mean(instFreqBuffer(min_ch, 2:end)) * myGUIdata.samplingFrequency / 2 / pi;
                syncID = buffer_index(fund_phase .* fund_phase(max(1, buffer_index - 1)) < 0 & ...
                    fund_phase(max(1, buffer_index - 1)) < fund_phase & ...
                    buffer_index > n_data & buffer_index < buffer_index(end) - n_data);
                if ~isempty(syncID)
                    [~, bias_center] = min(abs(syncID - buffer_index(end) / 2));
                    if isempty(bias_center)
                        bias_center = round(buffer_index(end) / 2);
                    end
                    center_id = syncID(bias_center);
                else
                    center_id = round(buffer_index(end) / 2);
                end
                selector = max(1, min(buffer_index(end), base_index + center_id - round(base_index(end) / 2)));
                fs = myGUIdata.samplingFrequency;
                contents = cellstr(get(myGUIdata.displayImagePopup,'String'));
                %myGUIdata.displayAttribute = contents{get(myGUIdata.displayImagePopup,'Value')};
                switch contents{get(myGUIdata.displayImagePopup,'Value')} %myGUIdata.displayAttribute
                    case 'Phase'
                        myGUIdata.waveletImage = myGUIdata.imageBufferTmp(:, selector);
                    case 'Inst. Freq. /fc'
                        myGUIdata.waveletImage = max(0.75, min(1.4, diag(1 ./ fc_list)...
                            * instFreqBuffer(:, selector) * fs / 2 / pi));
                    case 'Group delay*fc'
                        myGUIdata.waveletImage = max(-1, min(1, gd_gram(:, selector)));
                    case 'Absolute value'
                        levelBuf = 20 * log10(abs(myGUIdata.imageBuffer(:, selector)));
                        mx_level = max(max(levelBuf));
                        myGUIdata.waveletImage = max(mx_level - 70, levelBuf);
                end
                myGUIdata.gainData = mean(abs(myGUIdata.imageBuffer(:, selector)) .^ 2, 2);
                myGUIdata.gainData = 10 * log10(myGUIdata.gainData);
                set(myGUIdata.wvltImageHandle,'cdata',myGUIdata.waveletImage);
                set(myGUIdata.freqSDHandle, 'xdata', mixData / max(abs(mixData)) * xdata(end) * 1000);
                ydata = x_original(base_index + center_id - round(base_index(end) / 2));
                set(myGUIdata.waveHandle,'ydata', ydata);
                set(myGUIdata.dBpowerAxis, 'xlim', [-69 0]);
                set(myGUIdata.gainHandle, 'xdata', -80 - myGUIdata.gainData);
                fo_in_channel = 1 + log2(avfo / myGUIdata.low_frequency) * myGUIdata.channels_in_octave;
                set(myGUIdata.foCursor, 'ydata', fo_in_channel * [1 1]);
                set(myGUIdata.waveAxis,'ylim',max(abs(ydata))*[-1 1]);
                set(myGUIdata.foViewer, 'String', num2str(avfo, '%6.1f'));
                [~, croma_id] = min(abs(avfo - myGUIdata.croma_scale));
                myGUIdata.avfoDisplay = myGUIdata.avfoDisplay * 0.0 + avfo * 1.0;
                [~, croma_id_smooth] = min(abs(myGUIdata.avfoDisplay - myGUIdata.croma_scale));
                set(myGUIdata.tunerHandle, 'ydata', [0 0] + ...
                    1200 * log2(myGUIdata.avfoDisplay / myGUIdata.croma_scale(croma_id_smooth)));
                set(myGUIdata.noteNameText, 'String', myGUIdata.note_name_struct.name{croma_id_smooth});
            end
            myGUIdata.audioRecorderCount = myGUIdata.audioRecorderCount - 1;
            set(myGUIdata.counterTxt, 'String', num2str(myGUIdata.audioRecorderCount));
        end
end
switch get(myGUIdata.timerForWaveDraw, 'running')
    case 'off'
        start(myGUIdata.timerForWaveDraw);
end
if myGUIdata.audioRecorderCount < 0
    set(myGUIdata.counterTxt, 'String', 'Initializing ...');
    switch get(myGUIdata.timerForWaveDraw, 'running')
        case 'on'
            stop(myGUIdata.timerForWaveDraw);
    end
    switch get(myGUIdata.recordObj1,'running')
        case 'on'
            stop(myGUIdata.recordObj1);
    end
    myGUIdata.audioRecorderCount = myGUIdata.maxAudioRecorderCount;
    myGUIdata = startRealtime(myGUIdata);
end
guidata(handleForTimer,myGUIdata);
end

function myGUIdata = startRealtime(myGUIdata)
myGUIdata.audioRecorderCount = myGUIdata.maxAudioRecorderCount;
myGUIdata.lastPosition = 1;
record(myGUIdata.recordObj1);
pause(0.3)
switch get(myGUIdata.timerForWaveDraw,'running')
    case 'off'
        start(myGUIdata.timerForWaveDraw);
    case 'on'
    otherwise
        disp('timer is bloken!');
end
end

function myGUIdata = initializeGraphics(myGUIdata)
waveAxisHandle = myGUIdata.waveAxis;
fs = myGUIdata.samplingFrequency;
%------ waveform display
halfTimeSpan = myGUIdata.halfTimeSpan;
axes(waveAxisHandle);
time_axis = (-round(halfTimeSpan * fs):round(halfTimeSpan * fs)) / fs;
myGUIdata.waveHandle = plot(time_axis, randn(length(time_axis), 1), 'k');
set(gca, 'xlim', halfTimeSpan*[-1 1], 'fontsize', 14, 'xtick', [], 'ytick', []);
%xlabel('time (s)')
grid on;
%------- wavelet display
axes(myGUIdata.waveletAxis);
wvltStr = designCos6Wavelet(fs, myGUIdata.low_frequency, myGUIdata.high_freuency, ...
    myGUIdata.fftl, myGUIdata.stretching_factor, myGUIdata.channels_in_octave);
myGUIdata.n_channles = length(wvltStr.fc_list);
waveletImage = zeros(myGUIdata.n_channles, length(time_axis));
for ii = 1:myGUIdata.n_channles
    waveletImage(ii, :) = cos(time_axis / halfTimeSpan * pi * wvltStr.fc_list(ii) / wvltStr.fc_list(1));
end
myGUIdata.wvltImageHandle = imagesc(halfTimeSpan*[-1 1] * 1000, ...
    [1 myGUIdata.n_channles], waveletImage); axis('xy');
colormap(hsv);
hold all
myGUIdata.freqSDHandle = plot(zeros(myGUIdata.n_channles, 1), ...
    (1:myGUIdata.n_channles), 'w', 'linewidth', 3);
fc_list = wvltStr.fc_list;
ytickFreq = [50 60 70 80 90 100 200 300 400 500 600 700 800 900 1000 2000 3000 4000 5000];
ytick = interp1(log(fc_list), 1:length(fc_list), log(ytickFreq), 'linear', 'extrap');
ytickLabel = num2str(ytickFreq', '%4.0f');
set(gca, 'fontsize', 14, 'ytick', ytick, 'ytickLabel', ytickLabel, ...
    'ylim', [1 myGUIdata.n_channles],'xlim', halfTimeSpan*[-1 1] * 1000);
xlabel('time (ms)')
ylabel('frequency (Hz)');

%-------- wavelet level display
axes(myGUIdata.dBpowerAxis);
gainv = zeros(length(fc_list), 1) - 15;
for ii = 1:length(ytick)
    plot([-60 0], [1 1] * ytick(ii), 'color', [0.5 0.5 0.5]);
    hold all
end
croma_base = 27.5;
croma_scale = croma_base * 2 .^ (0:1 / 12:log2(myGUIdata.high_freuency / croma_base));
croma_scale_channel = 1 + log2(croma_scale / myGUIdata.low_frequency) * myGUIdata.channels_in_octave;
for ii = 1:length(croma_scale)
    plot([-69 -60], [1 1] * croma_scale_channel(ii), 'g');
end
for ii = 2:7
    if ii * 12 + 1 <= length(croma_scale_channel) && ...
            ii * 12 + 1 + 3 - 12 <= length(croma_scale_channel) && ...
            ii * 12 + 1 + 3 + 4 - 12 <= length(croma_scale_channel)
        text(-66, croma_scale_channel(ii * 12 + 1), ['A' num2str(ii)])
        text(-66, croma_scale_channel(ii * 12 + 1 + 3 - 12), ['C' num2str(ii)])
        text(-66, croma_scale_channel(ii * 12 + 1 + 3 + 4 - 12), ['E' num2str(ii)])
    end
end
note_name_base = {'C', 'C#', 'D', 'D#', 'E', 'F', 'F#', 'G', 'G#', 'A', 'A#', 'B'};
note_name_struct = struct;
for ii = 4:length(croma_scale)
    note_index = rem((ii - 4), 12) + 1;
    octave_id = floor(log2(croma_scale(ii) / croma_scale(4))) + 1;
    note_name_struct.name{ii} = [note_name_base{note_index} num2str(octave_id)];
end
myGUIdata.note_name_struct = note_name_struct;
myGUIdata.foCursor = plot([-60 0], [5 5], 'c', 'linewidth', 3);
myGUIdata.gainHandle = plot(gainv, 1:length(fc_list), 'k', 'linewidth', 2);
axis([-69 0 1 length(fc_list)]); grid on;
xlabel('level (rel. dB)');
%xtick = get(gca, 'xtick');
xtick = -60:10:0;
xtickLabel = num2str(xtick(end:-1:1)');
set(gca, 'ytick', [], 'fontsize', 14, 'xtick', xtick, 'xtickLabel', xtickLabel, 'xlim', [-69 0]);
myGUIdata.gainData = get(myGUIdata.gainHandle, 'xdata');
%---- tuner display
axes(myGUIdata.tunerAxis)
plot([-1 1], [0 0], 'k', 'linewidth', 2)
hold all
myGUIdata.tunerHandle = plot([-1 1], [0 0] + 0.2, 'g', 'linewidth', 5);
axis([-1 1 -50 50]);
set(gca, 'ytick', [], 'xtick', [], 'linewidth', 2);
myGUIdata.croma_scale = croma_scale;
myGUIdata.wvltStr = wvltStr;
myGUIdata.waveletImage = waveletImage;
myGUIdata.imageBuffer = zeros(myGUIdata.n_channles, length(time_axis) * 3);
myGUIdata.imageBufferTmp = zeros(myGUIdata.n_channles, length(time_axis) * 3);
myGUIdata.instFreqBuffer = zeros(myGUIdata.n_channles, length(time_axis) * 3);
%myGUIdata.displayAttribute = 'Phase';
update_colormap(myGUIdata);
end

function update_colormap(myGUIdata)
contents = cellstr(get(myGUIdata.displayImagePopup,'String'));
%myGUIdata.displayAttribute = contents{get(hObject,'Value')};
switch contents{get(myGUIdata.displayImagePopup,'Value')} %myGUIdata.displayAttribute
    case 'Phase'
        colormap(hsv);
    case 'Inst. Freq. /fc'
        colormap(hsv);
    case 'Group delay*fc'
        colormap(hsv);
    case 'Absolute value'
        colormap(jet);
end
end

%--- user defined supporting functions ends

% --- Executes on button press in startButton.
function startButton_Callback(hObject, eventdata, handles)
% hObject    handle to startButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
myGUIdata = guidata(hObject);
myGUIdata.audioRecorderCount = myGUIdata.maxAudioRecorderCount;
record(myGUIdata.recordObj1);
pause(0.3)
start(myGUIdata.timerForWaveDraw);
set(myGUIdata.startButton, 'enable', 'off');
set(myGUIdata.stopbutton, 'enable', 'on');
set(myGUIdata.quitbutton, 'enable', 'on');
set(myGUIdata.saveButton, 'enable', 'off');
guidata(hObject, myGUIdata);
end

% --- Executes on button press in stopbutton.
function stopbutton_Callback(hObject, eventdata, handles)
% hObject    handle to stopbutton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
myGUIdata = guidata(hObject);
switch get(myGUIdata.timerForWaveDraw, 'running')
    case 'on'
        stop(myGUIdata.timerForWaveDraw);
end
switch get(myGUIdata.recordObj1, 'running')
    case 'on'
        stop(myGUIdata.recordObj1);
end
set(myGUIdata.startButton, 'enable', 'on');
set(myGUIdata.stopbutton, 'enable', 'off');
set(myGUIdata.quitbutton, 'enable', 'on');
set(myGUIdata.saveButton, 'enable', 'on');
guidata(hObject, myGUIdata);
end

% --- Executes on button press in quitbutton.
function quitbutton_Callback(hObject, eventdata, handles)
% hObject    handle to quitbutton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
myGUIdata = guidata(hObject);
stop(myGUIdata.timerForWaveDraw);
delete(timerfindall);
stop(myGUIdata.recordObj1);
close(handles.excitationViewerGUI);
end


% --- Executes on selection change in displayImagePopup.
function displayImagePopup_Callback(hObject, eventdata, handles)
% hObject    handle to displayImagePopup (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns displayImagePopup contents as cell array
%        contents{get(hObject,'Value')} returns selected item from displayImagePopup
stopbutton_Callback(hObject, eventdata, handles);
myGUIdata = guidata(hObject);
contents = cellstr(get(hObject,'String'));
%myGUIdata.displayAttribute = contents{get(hObject,'Value')};
axes(myGUIdata.waveletAxis);
update_colormap(myGUIdata);
%switch contents{get(hObject,'Value')} %myGUIdata.displayAttribute
%    case 'Phase'
%        colormap(hsv);
%    case 'Inst. Freq. /fc'
%        colormap(hsv);
%    case 'Group delay*fc'
%        colormap(hsv);
%    case 'Absolute value'
%        colormap(jet);
%end
guidata(hObject, myGUIdata);
startButton_Callback(hObject, eventdata, handles);
end


% --- Executes during object creation, after setting all properties.
function displayImagePopup_CreateFcn(hObject, eventdata, handles)
% hObject    handle to displayImagePopup (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
end


% --- Executes on button press in saveButton.
function saveButton_Callback(hObject, eventdata, handles)
% hObject    handle to saveButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
myGUIdata = guidata(hObject);
outFileName = ['snapD' datestr(now, 30) '.wav'];
audiowrite( outFileName, myGUIdata.tmpAudio, myGUIdata.samplingFrequency, ...
    'BitsPerSample', 32);
disp(['snapshot file:' outFileName]);
set(myGUIdata.saveButton, 'enable', 'off');
end


% --- Executes on selection change in modePopup.
function modePopup_Callback(hObject, eventdata, handles)
% hObject    handle to modePopup (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns modePopup contents as cell array
%        contents{get(hObject,'Value')} returns selected item from modePopup
myGUIdata = guidata(hObject);
contents = cellstr(get(hObject,'String'));
myGUIdata.operationMode = contents{get(hObject,'Value')};
switch myGUIdata.operationMode
    case 'Normal'
        set(myGUIdata.viewerWidthPopup, 'visible', 'off');
        set(myGUIdata.fLowPopup, 'visible', 'off');
        set(myGUIdata.fHighPopup, 'visible', 'off');
        set(myGUIdata.defaultButton, 'visible', 'off');
        set(myGUIdata.stretchPopup, 'visible', 'off');
    case 'Experimental'
        set(myGUIdata.viewerWidthPopup, 'visible', 'on');
        set(myGUIdata.fLowPopup, 'visible', 'on');
        set(myGUIdata.fHighPopup, 'visible', 'on');
        set(myGUIdata.defaultButton, 'visible', 'on');
        set(myGUIdata.stretchPopup, 'visible', 'on');
end
guidata(hObject, myGUIdata);
end

% --- Executes during object creation, after setting all properties.
function modePopup_CreateFcn(hObject, eventdata, handles)
% hObject    handle to modePopup (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
end

% --- Executes on selection change in fHighPopup.
function fHighPopup_Callback(hObject, eventdata, handles)
% hObject    handle to fHighPopup (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns fHighPopup contents as cell array
%        contents{get(hObject,'Value')} returns selected item from fHighPopup
stopbutton_Callback(hObject, eventdata, handles);
myGUIdata = guidata(hObject);
contents = cellstr(get(hObject,'String'));
viewWidthstring = contents{get(hObject,'Value')};
stringValue = sscanf(viewWidthstring, '%s %f %s');
myGUIdata.high_freuency = stringValue(4);
delete(myGUIdata.wvltImageHandle);
delete(myGUIdata.gainHandle);
cla(myGUIdata.tunerAxis);
cla(myGUIdata.dBpowerAxis);
cla(myGUIdata.waveletAxis);
cla(myGUIdata.waveAxis);
myGUIdata = initializeGraphics(myGUIdata);
guidata(hObject, myGUIdata);
startButton_Callback(hObject, eventdata, handles);
end

% --- Executes during object creation, after setting all properties.
function fHighPopup_CreateFcn(hObject, eventdata, handles)
% hObject    handle to fHighPopup (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
end

% --- Executes on selection change in fLowPopup.
function fLowPopup_Callback(hObject, eventdata, handles)
% hObject    handle to fLowPopup (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns fLowPopup contents as cell array
%        contents{get(hObject,'Value')} returns selected item from fLowPopup
stopbutton_Callback(hObject, eventdata, handles);
myGUIdata = guidata(hObject);
contents = cellstr(get(hObject,'String'));
viewWidthstring = contents{get(hObject,'Value')};
stringValue = sscanf(viewWidthstring, '%s %f %s');
myGUIdata.low_frequency = stringValue(4);
delete(myGUIdata.wvltImageHandle);
delete(myGUIdata.gainHandle);
cla(myGUIdata.tunerAxis);
cla(myGUIdata.dBpowerAxis);
cla(myGUIdata.waveletAxis);
cla(myGUIdata.waveAxis);
myGUIdata = initializeGraphics(myGUIdata);
guidata(hObject, myGUIdata);
startButton_Callback(hObject, eventdata, handles);
end

% --- Executes during object creation, after setting all properties.
function fLowPopup_CreateFcn(hObject, eventdata, handles)
% hObject    handle to fLowPopup (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
end

% --- Executes on selection change in viewerWidthPopup.
function viewerWidthPopup_Callback(hObject, eventdata, handles)
% hObject    handle to viewerWidthPopup (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns viewerWidthPopup contents as cell array
%        contents{get(hObject,'Value')} returns selected item from viewerWidthPopup
stopbutton_Callback(hObject, eventdata, handles);
myGUIdata = guidata(hObject);
contents = cellstr(get(hObject,'String'));
viewWidthstring = contents{get(hObject,'Value')};
stringValue = sscanf(viewWidthstring, '%s %f %s');
myGUIdata.halfTimeSpan = stringValue(4) / 2 / 1000;
delete(myGUIdata.wvltImageHandle);
delete(myGUIdata.gainHandle);
cla(myGUIdata.tunerAxis);
cla(myGUIdata.dBpowerAxis);
cla(myGUIdata.waveletAxis);
cla(myGUIdata.waveAxis);
myGUIdata = initializeGraphics(myGUIdata);
guidata(hObject, myGUIdata);
startButton_Callback(hObject, eventdata, handles);
end

% --- Executes during object creation, after setting all properties.
function viewerWidthPopup_CreateFcn(hObject, eventdata, handles)
% hObject    handle to viewerWidthPopup (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
end


% --- Executes on button press in defaultButton.
function defaultButton_Callback(hObject, eventdata, handles)
% hObject    handle to defaultButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
stopbutton_Callback(hObject, eventdata, handles);
myGUIdata = guidata(hObject);
myGUIdata = setDefault(myGUIdata);
cla(myGUIdata.tunerAxis);
cla(myGUIdata.dBpowerAxis);
cla(myGUIdata.waveletAxis);
cla(myGUIdata.waveAxis);
myGUIdata = initializeGraphics(myGUIdata);
guidata(hObject, myGUIdata);
startButton_Callback(hObject, eventdata, handles);
end


% --- Executes on selection change in stretchPopup.
function stretchPopup_Callback(hObject, eventdata, handles)
% hObject    handle to stretchPopup (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns stretchPopup contents as cell array
%        contents{get(hObject,'Value')} returns selected item from stretchPopup
stopbutton_Callback(hObject, eventdata, handles);
myGUIdata = guidata(hObject);
contents = cellstr(get(hObject,'String'));
viewWidthstring = contents{get(hObject,'Value')};
stringValue = sscanf(viewWidthstring, '%s %f');
myGUIdata.stretching_factor = stringValue(5);
delete(myGUIdata.wvltImageHandle);
delete(myGUIdata.gainHandle);
cla(myGUIdata.tunerAxis);
cla(myGUIdata.dBpowerAxis);
cla(myGUIdata.waveletAxis);
cla(myGUIdata.waveAxis);
myGUIdata = initializeGraphics(myGUIdata);
guidata(hObject, myGUIdata);
startButton_Callback(hObject, eventdata, handles);
end

% --- Executes during object creation, after setting all properties.
function stretchPopup_CreateFcn(hObject, eventdata, handles)
% hObject    handle to stretchPopup (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
end



function phaseEdit_Callback(hObject, eventdata, handles)
% hObject    handle to phaseEdit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of phaseEdit as text
%        str2double(get(hObject,'String')) returns contents of phaseEdit as a double
if ~isnan(str2double(get(hObject,'String')))
    myGUIdata = guidata(hObject);
    myGUIdata.synchPhase = str2double(get(hObject,'String'));
    guidata(hObject, myGUIdata);
end
end


% --- Executes during object creation, after setting all properties.
function phaseEdit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to phaseEdit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
end
