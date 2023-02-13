function f = iqopen(cfg)
% open an instrument connection
% argument is expected to be a cell array with the following members:
%  connectionType - 'tcpip', 'visa-tcpip', 'visa-gpib'
%  visaAddr - VISA resource string for all visa-... types
%  ip_address - for tcpip only
%  port - for tcpip only

    f = [];
    if (~exist('cfg'))
        load('arbConfig');
        cfg = arbConfig;
    end

    i_list = instrfind('Type', 'tcpip', 'RemoteHost', cfg.ip_address, 'RemotePort', cfg.port);
    if isempty(i_list)
        try
            f = tcpip(cfg.ip_address, cfg.port);
        catch e
            errordlg(e.message, 'Error');
            f = [];
        end
    else
        f = i_list(1);
    end

    if (~isempty(f) && strcmp(f.Status, 'closed'))
        f.OutputBufferSize = 20000000;
        f.InputBufferSize = 64000;
        f.Timeout = 5; % 20;
        try
            fopen(f);
        catch e
            errordlg({'Could not open connection to the instrument.' ...
                      'Please verify that you specified the correct address' ...
                      'in the "Configure Instrument Connection" dialog.' ...
                      'Verify that you can communicate with the' ...
                      'instrument using the Agilent Connection Expert'}, 'Error');
            f = [];
        end
    end
end
