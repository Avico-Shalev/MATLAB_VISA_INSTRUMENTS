classdef DTG5334 < inst.gen
    % Data Timing Generator
    % by Avico
    properties (Constant)
        fpath           = 'C:\Documents and Settings\Administrator\Desktop\setups'
        int_trig_fn     = '00-Internal-trig 30ns-15ns.500ns_L1500_1GSs_0.3v.dtg';
        ext_trig_fn     = '00-ExtTrig_15ns_L1000_1GSs_0.3v.dtg';
        ext_trig_dpp_fn = '00-ExtTrig_40-43ns_L1000_1GSs_0.3v.dtg';
    end
    
    methods
        %% Constructor
        function self = DTG5334()
            vendor      = 'AGILENT';
            rsrcname    = 'GPIB0::1::0::INSTR'; %% GPIB ADDRESS
            idn         = 'DTG5334';
%             idn         = 'Data Timing Generator';
            self@inst.gen(vendor, rsrcname, idn);
        end
        function load( self , fn)
            %% LOAD settings file
            self.iprintf('MMEMory:LOAD ''%s'';*WAI', fullfile(self.fpath, fn));
            pause(1.5);
        end
        function opc( self )
            self.query('*OPC?');
        end
        function exe( self )
            self.iprintf('TBAS:RUN ON')
            self.opc;
            self.iprintf('OUTPut:STATe:ALL ON');
        end
        function int( self )
            self.load(self.int_trig_fn);
            self.opc;
            self.exe;
        end
        function ext( self )
            self.load(self.ext_trig_fn);
            self.opc;
            self.exe;
        end
        function ext_dpp( self )
            self.load(self.ext_trig_dpp_fn);
            self.opc;
            self.exe;
        end
        function pw( self, T, varargin )
            %% Change pulse-width (of primary pulse starting at i0), compatible with specified settings files
            defaults = {501, 100};
            defaults(1:nargin-2) = varargin;
            n   = defaults{2};
            i0  = defaults{1};
            self.iprintf('BLOCk:SELect "Block1"')
            self.iprintf('VECTor:IOFormat "y2", HEX')
            s = ['"', repmat('1', 1, T), repmat('0', 1, n-T), '"'];
            c = sprintf('VECTor:DATA %d,%d, %s', i0, n, s);
            self.iprintf(c)
        end
    end
    
end

