classdef PC_8169A < inst.gen
    % Polarization Controller
    % by Avico
    properties
        deg_h
        deg_q
        deg_p
    end
    
    methods
        %% Constructor
        function self = PC_8169A()
            vendor      = 'agilent';
            rsrcname    = 'GPIB0::24::0::INSTR';
            idn         = 'PC_8169A';
%             idn         = 'Polarization Controller';
            self@inst.gen(vendor, rsrcname, idn);
            self = self.reset();
        end
        function self = reset( self )
            %% RESET device
            self.iprintf('*rst;*cls');
            self.deg_h = 0; self.deg_q = 0; self.deg_p = 0;
        end
        %% Set/get POLARIZER POSITON, HALF PLATE, QUATER PLATE
        function self = half( self, deg )
        %SET/GET degree of half plate
            if exist('deg', 'var')
                self.iprintf(':POS:HALF %.2f', deg);
                self.deg_h = deg;
            else
                self.iprintf(':POS:HALF?');
                self.deg_h = self.iscanf('%.2f');
            end
        end
        function self = quar( self, deg )
        %SET/GET degree of quarter plate
            if exist('deg', 'var')
                self.iprintf(':POS:QUAR %.2f', deg);
                self.deg_q = deg;
            else
                self.iprintf(':POS:QUAR?');
                self.deg_q = self.iscanf('%.2f');
            end
        end
        function self = pol( self, deg )
        %SET/GET degree of polarizing filter
            if exist('deg', 'var')
                self.iprintf(':POS:POL %.2f', deg);
                self.deg_p = deg;
            else
                self.iprintf(':POS:POL?');
                self.deg_p = self.iscanf('%.2f');
            end
        end
        %% Switch between 2 orthogonal polarizations
        function self = orth( self )
            if self.deg_h == 0
                deg = 45;
            elseif self.deg_h == 45
                deg = 0;
            else
                warning('Current half-plate degree is resetted'); deg = 0;
            end
            self = self.half(deg);
        end
        
        %% POINCARE SPHERE SCANNING
        
        function init(self)
        % Initiate scanning the Poincare sphere
            self.iprintf(':INIT')
        end
        function stop(self)
        % Stop scanning the Poincare sphere
            self.iprintf(':ABORt');
        end
        function setRate(self, goFast)
        % Set scanning speed of the Poincare sphere, 1 for fast and 0 for slow
            self.iprintf(':PSPHere:RATE %d', goFast);
        end
        function answer = getRate(self)
        % Get scanning speed of the Poincare sphere
            answer = self.query(':PSPHere:RATE?');
        end
    end
    
end

