function iqdownload_M8190A(f, data, marker1, marker2, segmNum, downloadToChannel, run)
    %% Download a waveform to the M8190A
    % It is not intended that this function be called directly, only via iqdownload

    [realCh, imagCh] = M8190.determineChannels(downloadToChannel{1});

    % Assume a two-channels intrument
    numChannels = 2;
    
    % stop waveform output
    for i = 1:numChannels
        if (realCh == i || imagCh == i); M8190.xfprintf(f, sprintf(':abort%d', i)); end
    end
    
    if (realCh ~= 0)
        gen_arb_M8190A(f, realCh, real(data), marker1, segmNum);
    end
    if (imagCh ~= 0)
        gen_arb_M8190A(f, imagCh, imag(data), marker2, segmNum);
    end
    
    % turn on channel coupling only if download to both channels
    % otherwise keep the previous setting. If the user wants de-coupled
    % channels, he has to do that in the SFP or outside this script
    if (realCh + imagCh == 3)
        M8190.xfprintf(f, ':inst:coup:stat on');
        if (run)
            M8190.xfprintf(f, sprintf(':init:imm1'));
        end
    else
        if (run)
            for i = 1:numChannels
                if (realCh == i || imagCh == i);
                    M8190.xfprintf(f, sprintf(':init:imm%d', i));
                end
            end
        end
    end

end


function gen_arb_M8190A(f, chan, data, marker, segm_num)
% download an arbitrary waveform signal to a given channel and segment
    segm_len = length(data);
    if (segm_len > 0)
        % Try to delete the segment, but ignore errors if it does not exist
        % Another approach would be to first find out if it exists and only
        % then delete it, but that takes much longer
        M8190.xfprintf(f, sprintf(':trac%d:del %d', chan, segm_num), 1);
        M8190.xfprintf(f, sprintf(':trac%d:def %d,%d', chan, segm_num, segm_len));
        
        % scale to DAC values - data is assumed to be -1 ... +1
        data = int16(round(8191 * data) * 4);
        if (~isempty(marker))
            if (length(marker) ~= length(data))
                errordlg('length of marker vector and data vector must be the same');
            else
                data = data + int16(bitand(uint16(marker), 3));
            end
        end
        
        % swap MSB and LSB bytes in case of TCP/IP connection
        if (strcmp(f.type, 'tcpip'))
            data = swapbytes(data);
        end
        
        % Download the arbitrary waveform.
        % Split large waveform segments in reasonable chunks
        use_binblockwrite = 1;
        offset = 0;
        while (offset < segm_len)
            if (use_binblockwrite)
                len = min(segm_len - offset, 523200);
                cmd = sprintf(':trac%d:data %d,%d,', chan, segm_num, offset);
                binblockwrite(f, data(1+offset:offset+len), 'int16', cmd);
                M8190.xfprintf(f, '');
            else
                len = min(segm_len - offset, 4800);
                cmd = sprintf(':trac%d:data %d,%d', chan, segm_num, offset);
                cmd = [cmd sprintf(',%d', data(1+offset:offset+len)) '\n'];
                M8190.xfprintf(f, cmd);
            end
            offset = offset + len;
        end
        
        query(f, '*opc?\n');
        
        M8190.xfprintf(f, sprintf(':trac%d:sel %d', chan, segm_num));
    end
    
end
