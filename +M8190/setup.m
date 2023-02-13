function awgConn = setup(arbConfig)

%% Setup the M8190A
downloadToChannel{1} = 'I+Q to channel 1+2';

[realCh, imagCh] = M8190.determineChannels(downloadToChannel{1});

isRev2 = 0;

% Connect to the AWG
f = M8190.iqopen(arbConfig);
if (isempty(f))
    return;
end

% perform instrument reset if it is selected in the configuration
if (isfield(arbConfig,'do_rst') && arbConfig.do_rst)
    if (realCh == 0 || imagCh == 0)
        warndlg({'You have chosen to send a "*RST" command and you are downloading a' ...
                 'waveform to only one channel. This will delete the waveform on the' ...
                 'other channel. If you want to keep the previous waveform, please' ...
                 'un-check the "send *RST" checkbox in the Configuration window.'});
    end
    M8190.xfprintf(f, '*rst');
end

% Assume a two-channels instrument
numChannels = 2;


% stop waveform output
for i = 1:numChannels
    if (realCh == i || imagCh == i); M8190.xfprintf(f, sprintf(':abort%d', i)); end
end

% determine which version of the instrument we have and set parameters
% accordingly
switch (arbConfig.model)
    case 'M8190A_12bit'
        isRev2 = 1;
        for i = 1:numChannels
            if (realCh == i || imagCh == i); M8190.xfprintf(f, sprintf(':trac%d:dwid WSPeed', i)); end
        end
    case 'M8190A_14bit'
        isRev2 = 1;
        if (arbConfig.fs ~= 0)
            % when switching to 14 bit mode, set frequency first
            % in order to avoid an error message when previous
            % frequency setting was > 8 GHz
            M8190.xfprintf(f, sprintf(':freq:rast %.12g', arbConfig.fs));
        end
        for i = 1:numChannels
            if (realCh == i || imagCh == i); M8190.xfprintf(f, sprintf(':trac%d:dwid WPRecision', i)); end
        end
    case { 'M8190A_DUC_x3' 'M8190A_DUC_x12' 'M8190A_DUC_x24' 'M8190A_DUC_x48' }
        isRev2 = 1;
        interpolationFactor = eval(arbConfig.model(13:end));
        arbConfig.fs = arbConfig.fs * interpolationFactor;
        imagCh = realCh;
        if (arbConfig.fs ~= 0)
            % when switching to interpolation mode, set frequency first
            % in order to avoid an error message when previous
            % frequency setting was > 7.2 GHz
            M8190.xfprintf(f, sprintf(':freq:rast %.12g', arbConfig.fs));
        end
        M8190.xfprintf(f, sprintf(':trac%d:dwid INTX%d', realCh, interpolationFactor));
    otherwise
        % older instrument - do not send any command
end

% switch to external sample clock if it is set in configuration
if (isfield(arbConfig,'extClk') && arbConfig.extClk)
    if (arbConfig.fs ~= 0)
        M8190.xfprintf(f, sprintf(':frequency:raster:ext %.12g', arbConfig.fs));
    end
    for i = 1:numChannels
        if (realCh == i || imagCh == i); M8190.xfprintf(f, sprintf(':freq:rast:sour%d ext', i)); end
    end
else
    if (arbConfig.fs ~= 0)
        M8190.xfprintf(f, sprintf(':frequency:raster %.12g', arbConfig.fs));
    end
    for i = 1:numChannels
        if (realCh == i || imagCh == i); M8190.xfprintf(f, sprintf(':freq:rast:sour%d int', i)); end
    end
end

% Set skew parameters
if (isfield(arbConfig,'skew') && isfloat(arbConfig.skew))
    if (arbConfig.skew >= 0)
        M8190.xfprintf(f, sprintf(':arm:del1 %.12g', arbConfig.skew));
        if (numChannels > 1)
            M8190.xfprintf(f, sprintf(':arm:del2 %.12g', 0));
        end
    else
        M8190.xfprintf(f, sprintf(':arm:del1 %.12g', 0));
        if (numChannels > 1)
            M8190.xfprintf(f, sprintf(':arm:del2 %.12g', -1.0 * arbConfig.skew));
        end
    end
end

% Set output amplitude parameters
for chan=1:numChannels
    if (isRev2 && isfield(arbConfig, 'ampType'))
        M8190.xfprintf(f, sprintf(':outp%d:rout %s', chan, arbConfig.ampType));
    end

    if (isfield(arbConfig,'amplitude'))
        M8190.xfprintf(f, sprintf(':volt%d:ampl %g', chan, arbConfig.amplitude(chan)));    
    end

    if (isfield(arbConfig,'ofarbConfig.fset'))
        M8190.xfprintf(f, sprintf(':volt%d:ofarbConfig.fs %g', chan, arbConfig.ofarbConfig.fset(chan)));    
    end
end

% Set functional mode
for i = 1:numChannels
    if (realCh == i || imagCh == i)
        % set arb mode
        M8190.xfprintf(f, sprintf(':func%d:mode arb', i));
        % turn output on
        M8190.xfprintf(f, sprintf(':outp%d on', i));
    end
end

% Set reference frequency
if (isfield(arbConfig,'refClk') && arbConfig.refClk)
    M8190.xfprintf(f, sprintf(':rosc:sour ext'));
    
    refFreq = arbConfig.refClk;
    M8190.xfprintf(f, sprintf(':rosc:freq %g', refFreq));
end

% Set trigger
%M8190.xfprintf(f, sprintf(':arm:sequence:trigger:source internal'));
%M8190.xfprintf(f, sprintf(':arm:sequence:trigger:frequency %d', trigRate));
%M8190.xfprintf(f, sprintf(':init:cont:enable armed'));
%M8190.xfprintf(f, sprintf(':trigger:seq:source:enable event'));

awgConn = f;

end