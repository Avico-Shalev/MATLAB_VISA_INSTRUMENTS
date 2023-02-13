classdef E8257D < inst.gen
    % PSG Vector Signal Generator
    % by Avico
    properties
        f
        amp
        iOffset
        qOffset
        qSkew
    end
    
    methods
        %% Constructor
        function self = E8257D(varargin)
            Defaults{1} = struct('f',10.85,'amp',15);
            Defaults(2:4) = {23.9e-3, -8.0e-3, 1.2};
            Defaults(1:nargin) = varargin;
            vendor      = 'agilent';
            rsrcname    = 'GPIB0::19::0::INSTR'; %% GPIB ADDRESS
            idn         = 'E8257D';
%             idn         = 'PSG';
            self@inst.gen(vendor, rsrcname, idn);
            self.f      = Defaults{1}.f;
            self.amp    = Defaults{1}.amp;
            self.iOffset= Defaults{2};
            self.qOffset= Defaults{3};
            self.qSkew  = Defaults{4};
        end
        
        function init( self )
        %% Configure PSG's frequency and power and enable RF output
            self.iprintf(':FREQuency %fGHZ',    self.f/1e9)  % set frequency
            self.iprintf(':POW %f DBM',         self.amp);   % set power level
            self.iprintf(':OUTP ON');                        % RF ON
        end
        function iqAdjust( self )
            %% Adjust I/Q in wide mode
            self.iprintf(':WDM:IQAD ON')
            self.iprintf(':WDM:IQADjustment:IOFFset %d',   self.iOffset)
            self.iprintf(':WDM:IQADjustment:QOFFset %d', self.qOffset)
            self.iprintf(':WDM:IQADjustment:QSKew  %d',    self.qSkew)
        end
        %% SET/GET frequency
        function self = freq( self , f )
            if exist('f', 'var')
                self.iprintf(':FREQuency %fGHZ',    f/1e9)  % set frequency
                self.f = f;
            else
                self.iprintf(':FREQuency?')  % get frequency
                self.f = self.iscanf('%.2g');
            end
        end
        %% Configurations
        function setup( self )
        % SETUP PSG for wide I/Q mode
            self.init();
            self.iprintf(':WDM:STAT 1');                           % I/Q ON, I/Q Path Wide
        end
        function realtime( self )
        % SETUP PSG as CW
            self.init();
            self.iprintf(':DM:STAT 0');                             % I/Q OFF
            self.iprintf(':WDM:STAT 0');
        end
    end
    
end

