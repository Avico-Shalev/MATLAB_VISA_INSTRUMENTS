classdef M8190A < inst.gen
    % AWG
    % by Avico
    properties
        cnfg
        fs % sampling rate
        %% Legacy
        shortPumpChannel@double = 1 % SAMPLE marker channel 2
        longPumpChannel@double  = 2 % SAMPLE marker channel 1
        triggerChannel@double   = 4 % SYNC marker channel 1
        scopeChannel@double     = 8 % SYNC marker channel 2
        %% New
        syncMarker1@double      = 2 % SYNC marker channel 1
        sampleMarker1@double    = 1 % SAMPLE marker channel 1
    end
	properties (Constant)
        % (???) To be used later - startCmd starts the AWG, advanceCmd moves from only giving pump pulses to the real measurement
        trigSetCmd 	= struct(   'cmd',      'triggerMode',...
                                'sequence', 'continuous');
        startCmd 	= struct(   'cmd',      'mode',...
                                'sequence', 'stsc');
        advanceCmd  = struct(   'cmd',      'event');
        stopCmd     = struct(   'cmd',      'stop');
        lstCmd      = struct(   'cmd',      'list');
        delCmd      = struct(   'cmd',      'delete');
    end
    
    methods
        %% CONSTRUCTOR
        function self = M8190A(varargin)
            Defaults{1} = struct('fs',  12e9,...
                'AWG_SAMP_MRK_2',       1,...
                'AWG_SAMP_MRK_1',       2,...
                'AWG_SYNC_MRK_1',       4,...
                'AWG_SYNC_MRK_2',       8,...
                'segmentMinGrouping',   1);
            Defaults(1:nargin) = varargin;
            self@inst.gen();
            self.idn = 'M8190A';
            self.cnfg                       = M8190.loadArbConfig(); % Agilent software bundle
            self.fs                         = Defaults{1}.fs; % sampling rate
            self.cnfg.fs                    = Defaults{1}.fs; % sampling rate
            self.shortPumpChannel           = Defaults{1}.AWG_SAMP_MRK_2; % SAMPLE marker channel 2
            self.longPumpChannel            = Defaults{1}.AWG_SAMP_MRK_1; % SAMPLE marker channel 1
            self.triggerChannel             = Defaults{1}.AWG_SYNC_MRK_1; % SYNC marker channel 1
            self.scopeChannel               = Defaults{1}.AWG_SYNC_MRK_2; % SYNC marker channel 2
            self.cnfg.segmentMinGrouping    = Defaults{1}.segmentMinGrouping;
            self = self.open; % open but don't clear memory yet
        end
        %% Common commands
        function self = setup( self )
            %% SETUP AWG connection and clear memory
            self.conn = M8190.setup(self.cnfg); % Agilent software bundle
        end
        function self = open( self )
            %% OPEN connection
            self.conn = M8190.iqopen(self.cnfg); % Agilent software bundle
        end
        function del(self)
            %% DEL, clear memory
            M8190.sequencer.setupScenario(self.conn, self.delCmd);
        end
        function run( self )
        % Run
            M8190.sequencer.setupSequence(self.conn, self.startCmd, 'run', true); % Agilent software bundle
%             M8190.sequencer.setupScenario(self.conn, self.startCmd, 'run', true);
        end
        function stop( self )
        % Stop
            M8190.sequencer.setupSequence(self.conn, self.stopCmd); % Agilent software bundle
        end
        function advance( self )
        % Trigger another sequence
%             M8190.sequencer.setupSequence(self.conn, self.advanceCmd);
            M8190.sequencer.setupScenario(self.conn, self.advanceCmd); % Agilent software bundle
        end
        function contTrig( self )
        % Set trigger
            M8190.sequencer.setupScenario(self.conn, self.trigSetCmd); % Agilent software bundle
        end
        function [l, len] = list(self, quiet)
            %% LIST all segments
            cmd = self.lstCmd;
            if exist('quiet', 'var') % if quiet is true, no dialog box is shown
                cmd.quiet = quiet;
            end
            l = M8190.sequencer.setupSequence(self.conn, cmd);
            len = length(l);
        end
        %% I/Q download
        function iqdownload( self, iqdata, varargin )
            %% I/Q download
            % optional arguments are specified as attribute/value pairs:
            % - 'segmentNumber' - specify the segment number to use (default = 1)
            % - 'normalize' - auto-scale the data to max. DAC range (default = 1)
            % - 'downloadToChannel - string that describes to which AWG channel
            %              the data is downloaded. (see individual download routines)
            % - 'sequence' - description of the sequence table 
            % - 'marker' - vector of integers that must have the same length as iqdata
            %              low order bits correspond to marker outputs
            % - 'arbConfig' - struct as described in loadArbConfig (default: [])
            % - 'keepOpen' - if set to 1, will keep the connection to the AWG open
            %              after downloading the waveform
            % - 'run' - determines if the AWG will be started immediately after
            %              downloading the waveform/sequence. (default: 1)
            M8190.iqdownload(... % Agilent software bundle
            self.cnfg, ...
            self.conn, ...
            iqdata,...
            self.fs,...
            varargin{:});
        end
        %% Sequencing
        function setupSequence(self, seqTable)
        % Setup sequence
            seqCmd.cmd      = 'define';
            seqCmd.sequence = seqTable;
%             M8190.sequencer.setupSequence(self.conn, seqCmd);
            M8190.sequencer.setupScenario(self.conn, seqCmd); % Agilent software bundle
        end
        %% Segment generation tools
        function data = iqtone(self, varargin)
            %% Generate an IQ multitone waveform
            % Parameters are passed as property/value pairs. Properties are:
            % 'numSamples' - number of samples in IQ waveform (optional)
            % 'tone' - vector of tone frequencies in Hz
            % 'magnitude' - vector of relative magnitudes in dB
            % 'phase' - vector of phases in rad or 'Random', 'Zero', 'Increasing',
            %          'Parabolic'
            % 'normalize' - if set to 1 will normalize the output to [-1 ... +1]
            % 'correction' - if set to 1 will apply predistortion
            data = M8190.iqtone('sampleRate', self.fs,'arbconfig',self.cnfg, varargin{:}); % Agilent software bundle
        end
        
        function data = iqfsk(self, varargin)
            %% Generate an IQ FSK waveform (frequency hopping)
            % Parameters are passed as property/value pairs. Properties are:
            % 'tone' - vector of tone frequencies in Hz
            % 'toneTime' - amount of time per tone - can be a scalar or a vector
            %             (will be rounded to integer multiple of 1/sampleRate)
            % 'correction' - if set to 1, will perform amplitude correction
            data = M8190.iqfsk('sampleRate', self.fs,'arbconfig',self.cnfg, varargin{:}); % Agilent software bundle
        end
        
        %% Special segments
        function [data, marker, N] = iqfsk_avico(self, varargin)
            %% Generate an IQ FSK waveform (frequency hopping)
            % Parameters are passed as property/value pairs. Properties are:
            % 'tone' - vector of tone frequencies in Hz
            % 'totalTime' - amount of time of DTG block length
            %             (will be rounded to integer multiple of 1/sampleRate)
            % 'initialPhase' - with 'random' or 'zero' options or scalar value
            %% parse arguments
            totalTime       = 1500e-9;
            fRef            = 11.50e9;
            tone            = linspace(100e6, 1000e6, 3);
            toneTime        = [];
            initialPhase    = 'random';
            syncMarkerLength= 15e-9;
            magnitude       = 1;
            for i = 1:2:nargin-1
                if (ischar(varargin{i}))
                    switch varargin{i}
                        case 'referenceFrequency';      fRef            = varargin{i+1};
                        case 'totalTime';               totalTime       = varargin{i+1};
                        case 'toneTime';                toneTime        = varargin{i+1};
                        case 'tone';                    tone            = varargin{i+1};
                        case 'initialPhase';            initialPhase    = varargin{i+1};
                        case 'syncMarkerLength';        syncMarkerLength= varargin{i+1};
                        case 'magnitude';               magnitude       = varargin{i+1};
                        otherwise, error(['unexpected argument: ' varargin{i}]);
                    end
                end
            end
            if (ischar(initialPhase))
                switch lower(initialPhase)
                    case 'random'
                        initialPhase = rand;
                    case 'zero'
                        initialPhase = 0;
                    otherwise
                        error(['invalid phase: ' initialPhase]);
                end
            end
            if length(initialPhase)>1,
                warning('Initial phase has multiple values, only first value will be used.');
                initialPhase = initialPhase(1);
            end
            len_m = length(magnitude);
            nTone = length(tone);
            if len_m~=1 && len_m~=nTone
                error('Magnitude length doesn''t match tone length and is not a scalar.');
            end
            %% Determine IQ frequency and minimal number of samples
            tone = fRef - tone;
            if ~isequal(tone, round(tone)), warning('Tone values will be rounded.'); tone = round(tone); end
            if isempty(toneTime)
                toneTime = totalTime/nTone;
            end
            toneSamples = ceil(toneTime*self.fs);
            syncMarkerSamples = ceil(syncMarkerLength*self.fs);
            %% 1st method: Fit section to required length (trim edges)
            % N = max(...
            %     utils.ceilto( toneSamples, awg.cnfg.segmentGranularity ), ... % round (ceil) to the next multiple of segment granularity
            %     awg.cnfg.minimumSegmentSize ... % use at least minimum Segment Size
            %     );
            %% 2nd method: Calculate minimal section lengths
            g = gcd(tone, self.fs);
            n = lcm(self.fs./g, self.cnfg.segmentGranularity);
            % Fill required length (w/o trimming)
            m = ceil(toneSamples./n); % number of loops
            N = n.*m;
            %% Generate AWG segments
            dphi    = zeros(1, sum(N));
            marker  = zeros(1, sum(N));
            idx = [1 cumsum(N)];
            if any(syncMarkerSamples>N)
                warning('Sync marker length exceeds length of some/all sections.');
            end
            for i = 1:nTone
                dphi(idx(i):idx(i+1)) = tone(i) / self.fs;
                marker(idx(i):idx(i)+syncMarkerSamples) = self.syncMarker1;
            end
            if len_m>1
                mag = zeros(1, sum(N));
                for i = 1:nTone
                    mag(idx(i):idx(i+1)) = magnitude(i);
                end
            else
                mag = magnitude;
            end
            phi = initialPhase + cumsum(dphi);
            data = mag.*exp(1j* 2*pi * phi);
        end
        %% Special sequences
        function seqTable = seqAllCond(self)
            %% Generate a sequence of all segments (in order) in CONDITIONAL advancment method
            % 'advance' command must be used to proceed from segment to segment
            [l, len] = self.list(true); % get segment list
            if len == 0
                error('There are no defined segments');
            end
            seqTable = struct; % preallocate struct
            for i = 1:len
                seqTable(i).sequenceInit = true;    % both start and
                seqTable(i).sequenceEnd = true;     % end of sequence
                seqTable(i).segmentNumber = l(i);   % segment number
                seqTable(i).segmentLoops = 1;       % number of loops
%                 seqTable(1).segmentAdvance = 'Auto';
                seqTable(i).sequenceAdvance = 'Conditional';
                seqTable(i).markerEnable = true;    % enable markers
            end
            seqTable(len).scenarioEnd = true;       % last sequence concludes the scenario
            self.setupSequence(seqTable);           % send sequence
            self.contTrig;                          % set trigger
            self.run;                               % run
        end
        
        function seqTable = seqAllAuto(self, nAcquires)
            %% Generate a sequence of all segments (in order) in AUTO advancment method
            % loop over first segment until 'advance' command (EDFA consideration)
            if ~exist('nAcquires', 'var')
                nAcquires = 1;
            end
            [l, len] = self.list(true); % get segment list
            if len == 0
                error('There are no defined segments');
            end
            seqTable = struct; % preallocate struct
            for i = 1:len
                seqTable(i).sequenceInit = true;            % both start and
                seqTable(i).sequenceEnd = true;             % end of sequence
                seqTable(i).segmentNumber = l(i);           % segment number
                seqTable(i).segmentLoops = nAcquires;       % number of loops
                seqTable(i).sequenceAdvance = 'Auto';
                seqTable(i).markerEnable = true;            % enable markers
            end
            seqTable(1).sequenceAdvance = 'Conditional';    % loop over first segment
            seqTable(len).scenarioEnd = true;               % last sequence concludes the scenario
            self.setupSequence(seqTable);                   % send sequence
            self.contTrig;                                  % set trigger
            self.run;                                       % run
        end

        %% OBSOLETE
%         function seqTable = seq2(self)
%             seqTable(1).sequenceInit = true;
%             seqTable(1).sequenceEnd = true;
%             seqTable(1).segmentNumber = 1;
%             seqTable(1).segmentLoops = 1;
%             seqTable(1).segmentAdvance = 'Auto';
%             seqTable(1).sequenceAdvance = 'Conditional';
%             seqTable(1).markerEnable = true;
%             seqTable(1).scenarioEnd = false;
%             
%             seqTable(2).sequenceInit = true;
%             seqTable(2).sequenceEnd = true;
%             seqTable(2).segmentNumber = 2;
%             seqTable(2).segmentLoops = 1;
%             seqTable(2).segmentAdvance = 'Auto';
%             seqTable(2).sequenceAdvance = 'Conditional';
%             seqTable(2).markerEnable = true;
%             seqTable(2).scenarioEnd = true;
%             
%             self.setupSequence(seqTable);
%             self.contTrig;
%             self.run;
%         end
%         function seqTable = seq1(self)
%             seqTable(1).sequenceInit = true;
%             seqTable(1).sequenceEnd = true;
%             seqTable(1).segmentNumber = 1;
%             seqTable(1).segmentLoops = 1;
%             seqTable(1).segmentAdvance = 'Conditional';
%             seqTable(1).sequenceAdvance = 'Conditional';
%             seqTable(1).markerEnable = true;
%             seqTable(1).scenarioEnd = true;
%             self.setupSequence(seqTable);
%             self.contTrig;
%             self.run;
%         end
%         function realtime( self )
%             self.iprintf(':STAB1:SCEN:ADV COND');
%             self.iprintf(':STAB2:SCEN:ADV COND');
%             self.advance;
%         end
    end
    
end

