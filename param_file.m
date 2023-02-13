function [o, v, p, a, ed, shortPumpMarkerDelay, triggerDelay, shift] = param_file(nAverages)
%% Instruments setup parameters
o.srate         = 1e9;      % oscilloscope sampling rate
o.tpos          = 470;      % oscilloscope SEGmented time position (time origin)
o.syncCh        = 4;        % oscilloscope trigger channel
o.trigLvl       = 0.3;      % oscilloscope trigger level
o.probeCh       = 2;        % oscilloscope probe channel
o.pumpCh        = 3;        % oscilloscope pump channel
o.trigLvlRTIM   = 0.03;     % oscilloscope RealTIMe trigger level
o.trigpw        = 45;       % oscilloscope PWidth trigger minimal pulse width
o.tpos_rtime    = 450;      % oscilloscope RealTIMet time position (time origin)
if ~exist('nAverages','var'), nAverages = 32; end
o.nAverages     = nAverages;% oscilloscope RealTIMe average count
v.amp           = 15;   % vsg amplitude

%% Setup - pulses lengths
p.shortPumpLen    = 16e-9;
p.longPumpLen     = 20e-9;
p.diffPumpDelay   = 0e-9; % Delay of launching the long pump pulse

%% Setup - AWG
a.AWG_SAMP_MRK_1        = 1;
a.AWG_SYNC_MRK_1        = 2;
a.AWG_SAMP_MRK_2        = 4;
a.AWG_SYNC_MRK_2        = 8;
% a.fs                    = 8e9;
% a.fs                    = 12e9;
a.segmentMinGrouping    = 1;

shortPumpMarkerDelay    = 0;%modulationDelay + 1/2*tFiber - pulseDelay;
triggerDelay            = 370e-9;%shortPumpMarkerDelay + conversionDelay - sampleDelay+adjusting_trigger_delay;
shift                   = 00000; % 2805;
end

