classdef DSOX91604A < inst.gen
    % OSCILLOSCOPE
    % by Avico
    
    properties
        srate@double        = 1E9
        tpos@double         = 399
        trange@double       = 50
        syncCh@double       = 4
        probeCh@double     	= 2
        pumpCh@double     	= 3
        trigLvl@double     	= 0.3
        trigLvlRTIM@double 	= 0.03
        trigpw@double       = 45
        nAverages@double    = 16
        tpos_rtime@double   = 450
        data_path@char      = 'data\temp\'
        scr_path@char       = 'data\SCREENSHOTS\'
    end
    
    methods
        %% CONSTRUCTOR
        function self = DSOX91604A(varargin)
            %% default values
            vals = {10,...              Timeout
                    'littleEndian',...  ByteOrder
                    1e7...              InputBufferSize
                };
            fieldNames  = {'Timeout', 'ByteOrder', 'InputBufferSize'};
            for i = 1:nargin
                if (ischar(varargin{i})) % using name-value pairs for connection configuration
                    switch lower(varargin{i})
                        case 'timeout';         vals{1} = varargin(i+1);
                        case 'byteorder';       vals{2} = varargin{i+1};
                        case 'inputbuffersize'; vals{3} = varargin{i+1};
                    end
                elseif isstruct(varargin{i}) && isfield(varargin{i}, 'probeCh') % using struct for other properties
                    params = varargin{i};
                end
            end
            %% superclass constructor
            vendor      = 'agilent';
            rsrcname    = 'TCPIP1::xxx.xx.xxx.xxx::inst0::INSTR';  %% TCPIP ADDRESS
            idn         = 'DSOX91604A';
%             idn         = 'OSCILLOSCOPE';
            if isnan(vals{3}) && isnumeric(vals{3})
                fieldNames(3)   = [];
                vals(3)       = [];
            end
            args = reshape(cat(1, fieldNames, vals),1,[]);
            self@inst.gen(vendor, rsrcname, idn, args{:});
            %% drop all properties from parameters struct to object
            if exist('params', 'var')
                fieldNames = fieldnames(params);
                for j = 1:length(fieldNames)
                    self.(fieldNames{j}) = params.(fieldNames{j});
                end
            end
%             self.cls;
            self.iprintf('*CLS');
        end
        %% Common commands
        function cls( self )
            %% CLS, clear error quo
            self.iprintf('*CLS');
        end
        
        function answer = opc( self )
            answer = str2double(self.query('*OPC?'));
            while ~answer
                answer = str2double(self.query('*OPC?'));
            end
        end
        
        function stop( self )
            %% Set scope on Stop mode
            self.iprintf(':STOP');
        end
        
        function sing( self )
            %% Set scope on Single mode
            self.iprintf(':SINGle');
        end
        
        function run( self )
            %% Set scope on Single mode
            self.iprintf(':RUN');
        end
        
        function answer = timpos( self, t )
            if exist('t', 'var')
                self.iprintf(':TIMebase:POSition %dn', t); % time origin
                answer = true;
            else
                self.iprintf(':TIMebase:POSition?'); % time origin
                answer = self.iscanf('%f');
            end
        end
        function answer = avg( self, n )
            if exist('n', 'var')
                self.iprintf(':ACQuire:COUNt %dn', n); % average count
                answer = true;
            else
                self.iprintf(':ACQuire:COUNt?');
                answer = self.iscanf('%f');
            end
        end
        %% Configurations
        function setup( self, total_no_segments)
        %% SETUP osci for segmented experiment
            self.iprintf(':ACQuire:MODE SEGMented');                                % segmented mode
            if exist('total_no_segments', 'var')
                self.iprintf(':ACQuire:SEGMented:COUNt %d',     total_no_segments); % number of segments
            end
            self.iprintf(':ACQuire:SRATe %E',               self.srate);            % sampling rate
            self.iprintf(':TIMebase:POSition %dn',          self.tpos);             % time origin
            self.iprintf(':TIMebase:SCALe %dn',             self.trange);           % time range
            %% Trigger - EDGE on AWG's SYNC channel. Assuming sync markers are the sample markers (maybe shifted).
%             self.iprintf(':TRIGger:MODE EDGE');                                     % EDGE mode
%             self.iprintf(':TRIGger:EDGE:SOURce CHAN%d',     self.syncCh);           % Source
%             s = sprintf(':TRIGger:LEVel CHAN%d, %.3f',      self.syncCh,...         % Amplitude threshold
%                                                             self.trigLvl);
%             self.iprintf('%s', s);
            self.trigEdge;
        end
        function realtime( self )
        %% Configure scope to make realtime measurements
            self.iprintf(':ACQuire:MODE RTIMe'); % realtime mode
            self.iprintf(':ACQuire:SRATe %E',               self.srate);        % sampling rate
            self.iprintf(':TIMebase:POSition %dn',          self.tpos_rtime);   % time position
            %% Trigger - Pulse WIDth on PUMP channel, compatible with a series of pulses with a single pulse being longer than 25ns.
%             self.iprintf(':TRIGger:MODE PWIDth');                               % PWIDth mode
%             self.iprintf(':TRIGger:PWIDth:WIDTh %dns',      self.trigpw);    	% Pulse width threshold
%             self.iprintf(':TRIGger:PWIDth:SOURce CHAN%d', 	self.pumpCh);   	% Source
%             s = sprintf(':TRIGger:LEVel CHAN%d, %.3f',    	self.pumpCh,...     % Amplitude threshold
%                                                          	self.trigLvlRTIM);
%             self.iprintf('%s', s);
            self.trigPWIDTH;
            %% Averaging
            self.iprintf(':ACQuire:AVERage ON');
            self.iprintf(':ACQuire:COUNt %d',               self.nAverages);
            %% Run
            self.iprintf('*TRG');
        end
        %% TRIGGER
        function trigEdge( self, varargin )
            %% Trigger - EDGE on SYNC SAMPLE channel
            defaults = {self.syncCh, self.trigLvl};
            defaults(1:nargin-1) = varargin;
            ch  = defaults{1};
            lvl = defaults{2};
            self.iprintf(':TRIGger:MODE EDGE');                  	% EDGE mode
            self.iprintf(':TRIGger:EDGE:SOURce CHAN%d',     ch);  	% Source
            s = sprintf(':TRIGger:LEVel CHAN%d, %.3f',    	ch,...	% Amplitude threshold
                                                         	lvl);
            self.iprintf('%s', s);
            %% Run
            self.iprintf('*TRG');
        end
        function trigPWIDTH( self, varargin )
            %% Trigger - Pulse WIDth on PUMP channel, compatible with a series of pulses with a single pulse being longer than 25ns.
            defaults = {self.pumpCh, self.trigpw, self.trigLvlRTIM};
            defaults(1:nargin-1) = varargin;
            ch  = defaults{1};
            wid = defaults{2};
            lvl = defaults{3};
            self.iprintf(':TRIGger:MODE PWIDth');                  	% PWIDth mode
            self.iprintf(':TRIGger:PWIDth:DIR GTH');                % Greater than mode
            self.iprintf(':TRIGger:PWIDth:WIDTh %dns',      wid);	% Pulse width threshold
            self.iprintf(':TRIGger:PWIDth:SOURce CHAN%d',	ch);	% Source
            s = sprintf(':TRIGger:LEVel CHAN%d, %.3f',    	ch,...	% Amplitude threshold
                                                         	lvl);
            self.iprintf('%s', s);
            %% Run
            self.iprintf('*TRG');
        end
        %% AUTOSCALE
        function forceVertAutoScale(self)
        %% Force vertical autoscale on probe and pump channels
        % Has yet to acheive a good enough result, manual scaling is needed
        % still
%             self.iprintf(':STOP');
            self.iprintf(':AUTOSCALE:VERTical CHAN%d', self.probeCh);
            self.iprintf(':AUTOSCALE:VERTical CHAN%d', self.pumpCh);
        end
        %% Reading segments, traces, screenshoting
        function n = acqPoints( self )
            %% GET waveform number of points
%             self.iprintf(':ACQ:POINts?');     % time axis acquire points
            self.iprintf(':WAVeform:POINts?');  % time axis WAVeform points
            n = self.iscanf('%d');
        end
        function filename = read(self, varargin)
            %% Read segments
            defaults = {400, [], self.data_path};
            defaults(1:nargin-1) = varargin;
            avg_traces  = defaults{1}; % number of averages
            deg         = defaults{2}; % polarization synthesizer half plate degree
            spath       = defaults{3}; % saving path
            self.isopen();
            self.iprintf(':WAVEFORM:SOURCE CHAN%d', self.probeCh); % Source 
            self.iprintf(':WAVeform:VIEW ALL') % fetch the full waveform
            % Get the data back as a WORD (i.e., INT16), other options are ASCII and BYTE
            self.iprintf(':WAVEFORM:FORMAT WORD');
            % Set the byte order on the instrument as well
            self.iprintf(':WAVEFORM:BYTEORDER LSBFirst');
            self.iprintf(':WAVeform:SEGMented:COUNt?');     %  how many segments are acquired
            Nseg = self.iscanf('%d');
            if ~Nseg==0
                sz              = floor(self.conn.InputBufferSize/(Nseg*2).*.7)-1; % maximal batch size
                Norm_range      = min(sz, 70);  % normalization by leading range (1:Norm_range), might want to consider using "Norm_range" lowest values instead
                self.iprintf(':acquire:points?'); % time axis acquire points
                acq_pts         = self.iscanf('%d');
                YData           = zeros(acq_pts,Nseg/avg_traces,'double'); % preallocate double
                % Get preamble block
                preambleBlock   = query(self.conn,':WAVEFORM:PREAMBLE?');
                % Now send commmand to read data
                waveform = self.parsePreamble( preambleBlock ); % parse preamble
                self.iprintf(':WAVeform:SEGMented:ALL ON');     % enable all segmented data at once
                pb = utils.tqdmLike(acq_pts, 10, 'Reading data... ');
                for i =1:sz:acq_pts
                    %% for last reading request
                    if(acq_pts-i+1 <= sz), sz = acq_pts-i+1; end
                    if i+sz<acq_pts, j = i+sz-1; else j = acq_pts; end
                    %% Reading
                    mssg = sprintf(':WAV:DATA? %d, %d\n', i, sz); % read data a sz long data packet starting at index i (time-axis)
                    self.iprintf(mssg);
                    rawData = (self.binblockread('int16')); % unit16 is changed to int16
                    self.fread(1);
                    rawData = double(rawData);              % convert to double
                    rawData = reshape(rawData, [], Nseg);
                    %% Generate Y Data
                    y = (waveform.YIncrement.*((rawData) - waveform.YReference)) + waveform.YOrigin; 
                    %% Calculate leading notmalization factor
                    if  i==1 
                        avgn = sum(y(1:Norm_range,:),1)/Norm_range; 
                    end
                    y               = bsxfun(@rdivide, (y), avgn); % normalize   
                    rawData1        = mean(reshape(y, sz,Nseg/avg_traces,avg_traces),3); % correct one for our use, in dpp
                %       rawData1 = mean(reshape(YData, sz,avg_traces,Nseg/avg_traces),2); % correct one for our use in tailored reading
                    YData(i:j,:)    = reshape(rawData1,sz,Nseg/avg_traces);
                    pb = pb.update(i);
                end
                pb.fin();
                %% Generate X Data
                x = waveform.XIncrement.*(0:acq_pts-1) + waveform.XOrigin;
                %% Save results to directory
                if ~isempty(deg), polStr = sprintf('%.2fdeg',deg); else, polStr=''; end
                % nxt = utils.filenameIncrementor('Ydata');
                % filename=['Ydata' nxt '_Pol-' polStr '.mat'];
                b           = datestr(clock,13);
                dirdatestr  = [b(1:2) '-' b(4:5)];% '-' b(7:8)];
                filename    = [spath '\' dirdatestr '_Pol-' polStr '.mat'];
                utils.checkDir(spath);
                save(filename,'YData',...
                    'x',...
                    'deg');  
            else
                filename = [];
                warning('OSCI: No segments');
            end
        end
        
        function fn = scr(self, varargin)
            %% Get a screenshot of current display
            %% Defaults
            defaults = {false, self.scr_path, 'cap', 'png'};
            defaults(1:nargin-1) = varargin;
            ow      = defaults{1};
            spath   = defaults{2};
            fn      = defaults{3};
            ext     = defaults{4};
            if strncmp(ext, '.', 1), ext = ext(2:end); end % remove dot if exists
            %% Get screenshot
            self.iprintf(':DISPlay:DATA? %s', ext)
            screen = self.binblockread('uint8'); self.fread(1);
            %% SAVE to dir
            if isempty(ow) || ~ow
                fn = [fn utils.filenameIncrementor(fullfile(spath, 'cap'), ext)]; % 
            end
            fn = fullfile(spath, [fn, '.', ext]);
            utils.checkDir(spath);
            fid = fopen(fn,'w');
            fwrite(fid,screen,'uint8');
            fclose(fid);
        end
        function varargout = trc(self, varargin)
            %% Get traces from dispaly
            self.stop; self.opc;
            self.iprintf(':WAVEFORM:SOURCE CHAN%d', self.probeCh); self.opc;
            % Get the data back as a WORD (i.e., INT16), other options are ASCII and BYTE
            self.iprintf(':WAVEFORM:FORMAT WORD'); self.opc;
            % Set the byte order on the instrument as well
            self.iprintf(':WAVEFORM:BYTEORDER LSBFirst'); self.opc;
            self.iprintf(':WAVeform:SEGMented:ALL OFF'); self.opc;      % fetch current display only
            self.iprintf(':WAVeform:VIEW MAIN');                       % fetch record of main only
            self.opc;
            self.iprintf(':WAV:DATA?');
            rawData = double(self.binblockread('uint16'));
            self.opc;
            preambleBlock   = self.query(':WAVEFORM:PREAMBLE?');
            waveform = self.parsePreamble( preambleBlock );
            self.opc;
            %% Generate X & Y Data
            x = waveform.XIncrement.*(0:waveform.Points-1) + waveform.XOrigin;
            y = (waveform.YIncrement.*((rawData) - waveform.YReference)) + waveform.YOrigin;
            x = reshape(x, [], 1); y = reshape(y, [], 1); % set as column vectors
            %% Determine varargout format
            if nargout<2
                varargout = {[x, y]}; % single output, return a joint matrix
            else
                varargout = {x, y}; % multiple outputs, return separately
            end
            self.run; self.opc;
        end
    end
    methods(Static)
        function waveform = parsePreamble( preambleBlock )
            %% Preamble parsing
            % The preamble block contains all of the current WAVEFORM settings.  
                % It is returned in the form <preamble_block><NL> where <preamble_block> is:
                %    FORMAT        : int16 - 0 = BYTE, 1 = WORD, 2 = ASCII.
                %    TYPE          : int16 - 0 = NORMAL, 1 = PEAK DETECT, 2 = AVERAGE
                %    POINTS        : int32 - number of data points transferred.
                %    COUNT         : int32 - 1 and is always 1.
                %    XINCREMENT    : float64 - time difference between data points.
                %    XORIGIN       : float64 - always the first data point in memory.
                %    XREFERENCE    : int32 - specifies the data point associated with
                %                            x-origin.
                %    YINCREMENT    : float32 - voltage diff between data points.
                %    YORIGIN       : float32 - value is the voltage at center screen.
                %    YREFERENCE    : int32 - specifies the data point where y-origin
                %                            occurs.
            % Maximum value storable in a INT16
            maxVal = 2^16; 
            %  split the preambleBlock into individual pieces of info
            preambleBlock = regexp(preambleBlock,',','split');
            % store all this information into a waveform structure for later use
            waveform.Format         = str2double(preambleBlock{1});         % This should be 1, since we're specifying INT16 output
            waveform.Type           = str2double(preambleBlock{2});
            waveform.Points         = str2double(preambleBlock{3});
            waveform.Count          = str2double(preambleBlock{4});         % This is always 1
            waveform.XIncrement     = str2double(preambleBlock{5});         % in seconds
            waveform.XOrigin        = str2double(preambleBlock{6});         % in seconds
            waveform.XReference     = str2double(preambleBlock{7});
            waveform.YIncrement     = str2double(preambleBlock{8});         % V
            waveform.YOrigin        = str2double(preambleBlock{9});
            waveform.YReference     = str2double(preambleBlock{10});
            waveform.VoltsPerDiv    = (maxVal * waveform.YIncrement / 8);   % V
            waveform.Offset         = ((maxVal/2 - waveform.YReference) * waveform.YIncrement + waveform.YOrigin);         % V
            waveform.SecPerDiv      = waveform.Points * waveform.XIncrement/10 ; % seconds
            waveform.Delay          = ((waveform.Points/2 - waveform.XReference) * waveform.XIncrement + waveform.XOrigin); % seconds
        end
    end
end

