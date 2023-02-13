function result = setupScenario(f, seqcmd, varargin)
% Perform sequencer-related functions. 
    % define and run a sequence or execute sequence-related commands
    % 
    % 'cmd' must contain one of the following command strings:
    %       'list' - shows a list of all defined segments (also returns a
    %                vector with the defined segments)
    %       'delete' - delete the sequence table
    %       'event' - force an event signal
    %       'trigger' - force a trigger signal
    %       'select' - select the segment in sequence
    %       'define' - define a sequence in sequence
    % For the M8190A only, the following additional commands are available:
    %       'amplitudeTable' - define the amplitude table
    %       'frequencyTable' - define the frequency table
    %       'actionDefine' - define a new action, returns the action ID
    %       'actionDelete' - delete the action in seqcmd.sequence
    %       'actionDeleteAll' - delete all actions
    %
    % if cmd equals 'define', then
    % sequence must contain a vector of structs with the following elements.
    %     sequence(i).segmentNumber
    %     sequence(i).segmentLoop    (Optional. Default = 1)
    %     sequence(i).segmentAdvance (Optional. Default = 'auto')
    %     sequence(i).markerEnable   (Optional. Default = false)
    % where:
    % <segmentNumber> is the segment number (starting with 1)
    % <segmentLoop> indicates how often the segment will be repeated (1 to 2^32)
    % <segmentAdvance> is one of 'Auto', 'Conditional', 'Repeat', 'Stepped'
    % <markerEnable> is true or false and indicated is the marker that is
    %        defined in this segment will be generated on the output or not
    %
    % For the M8190A *ONLY*:
    % The sequence struct can optionally contain 5 more elements:
    %  sequence(i).sequenceInit        (0 or 1, 1=start of sequence, default: 0)
    %  sequence(i).sequenceEnd         (0 or 1, 1=end of sequence, default: 0)
    %  sequence(i).sequenceLoop        (1 to 2^32: sequence repeat count, default: 1)
    %  sequence(i).sequenceAdvance     (same possible values as segmentAdvance, default: 'auto')
    %  sequence(i).scenarioEnd         (0 or 1, 1=end of scenario, default: 0)
    %  sequence(i).amplitudeInit       (0 or 1, 1=initialize amplitude pointer. Default = 0)
    %  sequence(i).amplitudeNext       (0 or 1, 1=use next amplitude value. Default = 0)
    %  sequence(i).frequencyInit       (0 or 1, 1=initialize frequency pointer. Default = 0)
    %  sequence(i).frequencyNext       (0 or 1, 1=use next frequency value. Default = 0)
    %  sequence(i).actionID            (0 to 2^24-1, -1 = unused. Default: -1)
    %
    % For the M8190A *only*:
    % <segmentNumber> can be zero to indicate an "idle" command. In that case,
    % <segmentLoop> indicates the number of samples to pause
    %
    % For the M8190A *only*:
    % if cmd equals 'actionDefine', then
    % sequence must contain a cell array with alternating strings and values.
    % The string represents the type of action and value is a vector of
    % associated parameter(s). Valid action strings are:
    % Action            Action String  Parameters
    % Carrier Frequency CFRequency	   [ integral part of frequency in Hz, fractional part of frequency in Hz ]
    % Phase Offset      POFFset        [ phase in parts of full cycle (-0.5 ... +0.5)]
    % Phase Reset       PRESet         [ phase in parts of full cycle (-0.5 ... +0.5)]
    % Phase Bump        PBUMp          [ phase in parts of full cycle (-0.5 ... +0.5)]
    % Sweep Rate        SRATe          [ Sweep Rate integral part in Hz/us, sweep rate fractional part in Hz/us ]
    % Sweep Run         SRUN           []
    % Sweep Hold        SHOLd          []
    % Sweep Restart     SREStart       []
    % Amplitude         AMPLitude      [ Amplitude in the range 0...1 ]
    % the call will return an "actionID", which can be used in a sequence entry
    
    %% parse optional arguments
    downloadToChannel{1} = 'I+Q to channel 1+2';
    run = 0;
    for i = 1:nargin-2
        if (ischar(varargin{i}))
            switch lower(varargin{i})
                case 'downloadtochannel'; downloadToChannel = varargin(i+1);
                case 'run'; run = varargin{i+1};
            end
        end
    end
    
    % Determine channels
    [realCh, imagCh] = M8190.determineChannels(downloadToChannel{1});

    % check what to do: seqcmd.cmd contains the function to perform and
    % seqcmd.sequence contains the parameter(s)
    result = [];
    switch (seqcmd.cmd)
        case 'list'
            s = sscanf(query(f, sprintf(':TRACe%d:CATalog?', max(realCh, imagCh))), '%d,');
            s = reshape(s,2,length(s)/2);
            if (s(1,1) == 0)
                errordlg({'There are no segments defined.' ...
                    'Please load segments before calling this function and make sure' ...
                    'that the "send *RST" checkbox in the config window is un-checked'} );
            else
                errordlg(sprintf('The following segments are defined:%s', ...
                    sprintf(' %d', s(1,:))));
                result = s(1,:);
            end
        case 'delete'
            for i = [realCh imagCh]
                if (i)
                    M8190.xfprintf(f, sprintf(':ABORt%d', i));
                    M8190.xfprintf(f, sprintf(':TRACe%d:DELete:ALL', i));
                    M8190.xfprintf(f, sprintf(':STABle%d:RESET', i));
                end
            end
        case 'event'
            M8190.xfprintf(f, ':TRIGger:ADVance:IMMediate');
        case 'trigger'
            M8190.xfprintf(f, ':TRIGger:BEGin:IMMediate');
        case 'define'
            defineScenario(f, seqcmd, realCh, imagCh, run);
        case 'amplitudeTable'
            M8190.xfprintf(f, ':ABORt');
            list = seqcmd.sequence;
            for i = [realCh imagCh]
                if (i)
                    binary = 0;
                    if (binary)
                        list = 32767 * int32(list);
                        binblockwrite(f, list, 'int32', sprintf(':ATABle%d:DATA 0,', i));
                        M8190.xfprintf(f, '');
                    else
                        cmd = sprintf(',%g', list);
                        M8190.xfprintf(f, sprintf(':ATABle%d:DATA 0%s', i, cmd));
                    end
                end
            end
        case 'frequencyTable'
            M8190.xfprintf(f, ':ABORt');
            list = seqcmd.sequence;
            for i = [realCh imagCh]
                if (i)
                    binary = 0;
                    if (binary)
                        binblockwrite(f, list, 'float32', sprintf(':FTABle%d:DATA 0,', i));
                        M8190.xfprintf(f, '');
                    else
                        cmd = sprintf(',%.1f', list);
                        M8190.xfprintf(f, sprintf(':FTABle%d:DATA 0%s', i, cmd));
                    end
                end
            end
        case 'actionDefine'
            M8190.xfprintf(f, ':ABORt');
            list = seqcmd.sequence;
            for i = [realCh imagCh]
                if (i)
                    result = str2double(query(f, sprintf(':ACTion%d:DEFine:NEW?', i)));
                    for j = 1:2:length(list)
                        if (isempty(list{j+1}))
                            % no parameter e.g.      SRUN
                            M8190.xfprintf(f, sprintf(':ACTion%d:APPend %d,%s', ...
                                i, result, list{j}));
                        elseif (isscalar(list{j+1}))
                            % single parameter e.g.   PBUMp, 0.4
                            M8190.xfprintf(f, sprintf(':ACTion%d:APPend %d,%s,%.15g', ...
                                i, result, list{j}, list{j+1}));
                        else
                            % dual parameter e.g.   CFRequency, 100e6, 0.5
                            M8190.xfprintf(f, sprintf(':ACTion%d:APPend %d,%s,%.15g,%.15g', ...
                                i, result, list{j}, list{j+1}));
                        end
                    end
                end
            end
        case 'actionDelete'
            for i = [realCh imagCh]
                if (i)
                    M8190.xfprintf(f, sprintf(':ABORt%d', i));
                    M8190.xfprintf(f, sprintf(':ACTion%d:DELete %d', i, seqcmd.sequence));
                end
            end
        case 'actionDeleteAll'
            for i = [realCh imagCh]
                if (i)
                    M8190.xfprintf(f, sprintf(':ABORt%d', i));
                    M8190.xfprintf(f, sprintf(':ACTion%d:DELete:ALL', i));
                end
            end
        case 'dynamic'
            for i = [realCh imagCh]
                if (i)
                    M8190.xfprintf(f, sprintf(':ABORt%d', i));
                    M8190.xfprintf(f, sprintf(':STABle%d:DYNamic %d', i, seqcmd.sequence));
                end
            end
        case 'mode'
            for i = [realCh imagCh]
                if (i)
                    M8190.xfprintf(f, sprintf(':ABORt%d', i));
                    M8190.xfprintf(f, sprintf(':FUNCtion%d:MODE %s', i, seqcmd.sequence));
                end
            end
            if (run)
                for i = [realCh imagCh]
                    if (i)
                        M8190.xfprintf(f, sprintf(':INIT:IMMediate%d', i));
                    end
                end
            end
        case 'triggerMode'
            switch seqcmd.sequence
                case 'triggered'
                    s = '0';
                case 'continuous'
                    s = '1';
                otherwise
                    error('unknown triggerMode');
            end
            for i = [realCh imagCh]
                if (i)
                    M8190.xfprintf(f, sprintf(':INIT:CONTinuous%d %s', i, s));
                end
            end
        case 'stop'
            for i = [realCh imagCh]
                if (i)
                    M8190.xfprintf(f, sprintf(':ABORt%d', i));
                end
            end
        otherwise
            errordlg(['undefined sequence command: ' seqcmd.cmd]);
    end
end


function defineScenario(f, seqcmd, realCh, imagCh, run)
% define a new scenario table
    M8190.xfprintf(f, ':ABORt');
    seqtable = seqcmd.sequence;
    
    % check if only valid fieldnames are used (typo?)
    fields = fieldnames(seqtable);
    fields(find(strcmp(fields, 'segmentNumber'))) = [];
    fields(find(strcmp(fields, 'segmentLoops'))) = [];
    fields(find(strcmp(fields, 'segmentAdvance'))) = [];
    fields(find(strcmp(fields, 'sequenceAdvance'))) = [];
    fields(find(strcmp(fields, 'sequenceLoops'))) = [];
    fields(find(strcmp(fields, 'markerEnable'))) = [];
    fields(find(strcmp(fields, 'sequenceInit'))) = [];
    fields(find(strcmp(fields, 'sequenceEnd'))) = [];
    fields(find(strcmp(fields, 'scenarioEnd'))) = [];
    fields(find(strcmp(fields, 'amplitudeInit'))) = [];
    fields(find(strcmp(fields, 'amplitudeNext'))) = [];
    fields(find(strcmp(fields, 'frequencyInit'))) = [];
    fields(find(strcmp(fields, 'frequencyNext'))) = [];
    fields(find(strcmp(fields, 'actionID'))) = [];
    if (~isempty(fields))
        disp('The following field names are unknown:');
        disp(fields);
        error('unknown field names');
    end
    
    % check if all the segments are defined
    s = sscanf(query(f, sprintf(':trac%d:cat?', max(realCh, imagCh))), '%d,');
    s = reshape(s,2,length(s)/2);
    notDef = [];
    for i = 1:length(seqtable)
        if (isempty(find(s(1,:) == seqtable(i).segmentNumber, 1)))
            notDef = [notDef seqtable(i).segmentNumber];
        end
    end
    notDef = notDef(notDef > 0);    % ignore zero and negative numbers, they are special commands
    if (~isempty(notDef))
        errordlg({ sprintf('The following segments are used in the sequence but not defined:%s.', ...
            sprintf(' %d', notDef)) ...
            'Please load segments before calling this function and make sure' ...
            'that the "send *RST" checkbox in the config window is un-checked'} );
        return;
    end
    
    % download the sequence table
    seqData = uint32(zeros(6 * length(seqtable), 1));
    for i = 1:length(seqtable)
            seqTabEntry = calculateSeqTableEntry(seqtable(i), i, length(seqtable));
            seqData(6*i-5:6*i) = seqTabEntry;
    end
    % swap MSB and LSB bytes in case of TCP/IP connection
    if (strcmp(f.type, 'tcpip'))
        seqData = swapbytes(seqData);
    end
    for i = [realCh imagCh]
        if (i)
            binblockwrite(f, seqData, 'uint32', sprintf(':STABle%d:DATA 0,', i));
            M8190.xfprintf(f, '');
%            disp(dec2hex(seqData));
%            cmd = sprintf(',%.0f', seqData);
%            xfprintf(f, sprintf(':STABle%d:DATA 0%s', i, cmd));
            
            M8190.xfprintf(f, sprintf(':STABle%d:SCENario:SELect %d', i, 0));
            M8190.xfprintf(f, sprintf(':STABle%d:DYNamic:STATe 0', i));
            M8190.xfprintf(f, sprintf(':FUNCtion%d:MODE STScenario', i));
        end
    end
    
    if (run)
        for i = [realCh imagCh]
            if (i)
                M8190.xfprintf(f, sprintf(':INIT:IMMediate%d', i));
            end
        end
    end

end

function seqTabEntry = calculateSeqTableEntry(seqline, currLine, numLines)
% calculate the six 32-bit words that make up one sequence table entry.
% For details on the format, see user guide section 4.20.6
%
% The content of the six 32-bit words depends on the type of entry:
% Data Entry: Control / Seq.Loops / Segm.Loops / Segm.ID / Start Offset / End Offset
% Idle Cmd:   Control / Seq.Loops / Cmd Code(0) / Idle Sample / Delay / Unused
% Action:     Control / Seq.Loops / Cmd Code(1) + Act.ID / Segm.ID / Start Offset / End Offset
    cbitCmd = 32;
    cbitEndSequence = 31;
    cbitEndScenario = 30;
    cbitInitSequence = 29;
    cbitMarkerEnable = 25;
    cbitAmplitudeInit = 16;
    cbitAmplitudeNext = 15;
    cbitFrequencyInit = 14;
    cbitFrequencyNext = 13;
    cmaskSegmentAuto = hex2dec('00000000');
    cmaskSegmentCond = hex2dec('00010000');
    cmaskSegmentRept = hex2dec('00020000');
    cmaskSegmentStep = hex2dec('00030000');
    cmaskSequenceAuto = hex2dec('00000000');
    cmaskSequenceCond = hex2dec('00100000');
    cmaskSequenceRept = hex2dec('00200000');
    cmaskSequenceStep = hex2dec('00300000');
    seqLoopCnt = 1;

    ctrl = uint32(0);
    seqTabEntry = uint32(zeros(6, 1));        % initialize the return value
    if (seqline.segmentNumber == 0)           % segment# = 0 means: idle command
        ctrl = bitset(ctrl, cbitCmd);         % set the command bit
        seqTabEntry(3) = 0;                   % Idle command code = 0
        seqTabEntry(4) = 0;                   % Sample value
        if (isfield(seqline, 'segmentLoops') && ~isempty(seqline.segmentLoops))
            seqTabEntry(5) = seqline.segmentLoops;  % use segment loops as delay
        else
            seqTabEntry(5) = 1;
        end
        seqTabEntry(6) = 0;                   % unused
    else
        if (isfield(seqline, 'actionID')&& ~isempty(seqline.actionID) && seqline.actionID >= 0)
            % if it is an actionID, set the command bit and action Cmd Code
            % and store actionID in 24 MSB of word#3.
            % The segment will not be repeated. segmentLoops is ignored
            ctrl = bitset(ctrl, cbitCmd);
            seqTabEntry(3) = 1 + bitshift(uint32(seqline.actionID), 16);
            if (isfield(seqline, 'segmentLoops') && ~isempty(seqline.segmentLoops) && seqline.segmentLoops >1) %  i added  =
                errordlg(['segmentLoops will be ignored when an actionID is specified (seq entry ' num2str(currLine) ')']);
            end
        else
            % normal data entries have the segment loop count in word#3
            seqTabEntry(3) = seqline.segmentLoops;
        end
        
        % seqTabEntry(3) = 1;% my commnnd
        
        seqTabEntry(4) = seqline.segmentNumber;
        seqTabEntry(5) = 0;                   % start pointer
        seqTabEntry(6) = hex2dec('ffffffff'); % end pointer
        if (isfield(seqline, 'segment') && ~isempty(seqline.segmentAdvance))
            switch (seqline.segmentAdvance)
                case 'Auto';        ctrl = bitor(ctrl, cmaskSegmentAuto);
                case 'Conditional'; ctrl = bitor(ctrl, cmaskSegmentCond);
                case 'Repeat';      ctrl = bitor(ctrl, cmaskSegmentRept);
                case 'Stepped';     ctrl = bitor(ctrl, cmaskSegmentStep);
            end
        end
        if (isfield(seqline, 'markerEnable') && ~isempty(seqline.markerEnable) && seqline.markerEnable)
            ctrl = bitset(ctrl, cbitMarkerEnable);
        end
    end
    % set the amplitude and frequency table flags
    if (isfield(seqline, 'amplitudeInit') && ~isempty(seqline.amplitudeInit) && seqline.amplitudeInit)
        ctrl = bitset(ctrl, cbitAmplitudeInit);
    end
    if (isfield(seqline, 'amplitudeNext') && ~isempty(seqline.amplitudeNext) && seqline.amplitudeNext)
        ctrl = bitset(ctrl, cbitAmplitudeNext);
    end
    if (isfield(seqline, 'frequencyInit') && ~isempty(seqline.frequencyInit) && seqline.frequencyInit)
        ctrl = bitset(ctrl, cbitFrequencyInit);
    end
    if (isfield(seqline, 'frequencyNext') && ~isempty(seqline.frequencyNext) && seqline.frequencyNext)
        ctrl = bitset(ctrl, cbitFrequencyNext);
    end
    % if the sequence fields exist, then set the sequence control bits
    % according to those fields
    if (isfield(seqline, 'sequenceInit'))
        if (seqline.sequenceInit)  % init sequence flag
            ctrl = bitset(ctrl, cbitInitSequence);
        end
        if (isfield(seqline, 'sequenceEnd')&& ~isempty(seqline.sequenceEnd) && seqline.sequenceEnd)
            ctrl = bitset(ctrl, cbitEndSequence);
        end
        if (isfield(seqline, 'sequenceLoops') && ~isempty(seqline.sequenceLoops))
            seqLoopCnt = seqline.sequenceLoops;
        end
        if (isfield(seqline, 'sequenceAdvance') && ~isempty(seqline.sequenceAdvance))
            switch (seqline.sequenceAdvance)  % sequence advance mode
                case 'Auto';        ctrl = bitor(ctrl, cmaskSequenceAuto);
                case 'Conditional'; ctrl = bitor(ctrl, cmaskSequenceCond);
                case 'Repeat';      ctrl = bitor(ctrl, cmaskSequenceRept);
                case 'Stepped';     ctrl = bitor(ctrl, cmaskSequenceStep);
            end
        end
        if (isfield(seqline, 'scenarioEnd') && ~isempty(seqline.scenarioEnd) && seqline.scenarioEnd)
            ctrl = bitset(ctrl, cbitEndScenario);
        end
    else
        % otherwise assume a single sequence and set start and
        % end of sequence flags automatically
        if (currLine == 1)
            ctrl = bitset(ctrl, cbitInitSequence);
        end
        if (currLine == numLines)
            ctrl = bitset(ctrl, cbitEndSequence);
        end
    end
    seqTabEntry(1) = ctrl;                % control word
    seqTabEntry(2) = seqLoopCnt;          % sequence loops
end