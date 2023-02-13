function [realCh imagCh] = determineChannels(downloadToChannel)
%DETERMINECHANNELS Determine the real and imaginary channel numbers
    % determine to which channel the real and imaginary parts of the signal
    % will be loaded. Zero means ignore that part of the waveform.
    
    switch (downloadToChannel)
        case 'I+Q to channel 1+2'
            realCh = 1; imagCh = 2;
        case 'I+Q to channel 2+1'
            realCh = 2; imagCh = 1;
        case 'I to channel 1'
            realCh = 1; imagCh = 0;
        case 'I to channel 2'
            realCh = 2; imagCh = 0;
        case 'Q to channel 1'
            realCh = 0; imagCh = 1;
        case 'Q to channel 2'
            realCh = 0; imagCh = 2;
        otherwise
            error(['unexpected value for downloadToChannel argument: ' downloadToChannel]);
    end

end

