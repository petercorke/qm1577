classdef qm1577
    
    properties
        serPort
        debug
        
    end
    
    methods
        
    function dso = qm1577(varargin)
            %Arbotix.Arbotix Create Arbotix interface object
            %
            % DM = Arbotix(OPTIONS) is an object that represents a connection to a chain
            % of Arbotix servos connected via an Arbotix controller and serial link to the
            % host computer.
            %
            % Options::
            %  'port',P      Name of the serial port device, eg. /dev/tty.USB0
            %  'baud',B      Set baud rate (default 38400)
            %  'debug',D     Debug level, show communications packets (default 0)
            %  'nservos',N   Number of servos in the chain
            
            opt.port = '/dev/tty.SLAB_USBtoUART';
            opt.debug = false;
            opt.nservos = [];
            opt.baud = 38400;
            
            opt = tb_optparse(opt, varargin);
            
            dso.serPort = opt.port;
            dso.debug = opt.debug;
            
            % clean up any previous instances of the port, can happen...
            for tty = instrfind('Port', opt.port)
                if ~isempty(tty)
                    disp(['serPort ' tty.port 'is in use.   Closing it.'])
                    fclose(tty);
                    %delete(tty);
                end
            end
            
            if opt.verbose
                disp('Establishing connection to QM-1577 scope/meter...');
            end
            
            dso.serPort = serial(dso.serPort,'BaudRate', opt.baud);
            set(dso.serPort,'InputBufferSize',1000)
            set(dso.serPort, 'Timeout', 20)
            set(dso.serPort, 'Tag', 'Arbotix')
                        
            if opt.verbose
                disp('Opening connection to QM-1577 DMM...');
            end
            
            pause(0.5);
            try
                fopen(dso.serPort);
            catch me
                disp('open failed');
                me.message
                return
            end
            
            %dso.flush();
            
        end
        
        function delete(arb)
            %Arbotix.delete  Close the serial connection
            %
            % delete(DM) closes the serial connection and removes the DM object
            % from the workspace.
            
            tty = instrfind('port', arb.serPort.port);
            fclose(tty);
            delete(tty);
        end 

function [data,t] = dso(s)
    
    timebase = [20 10 5 2 1 0.5 0.2 0.1 50e-3 20e-3 10e-3 5e-3 2e-3 1e-3 ...
        0.5e-3 0.2e-3 0.1e-3 50e-6 20e-6 10e-6 5e-6 2e-6 0.8e-6 0.4e-6 ...
        0.2e-6 0.1e-6 50e-9];
    volts = [200 100 50 20 10 5 2 1 0.5 0.2 0.1 50e-3];
    
    v = dso2vec(s);
    out = dsorecords(v);
    
    settings = out(1,:);
    dt = timebase( settings(1) );
    dv = volts( settings(3) );
    
    data = out(2:17,:);
    data = data(:)';  % into a column vector
    data(data>127) = data(data>127)-256; % to twos complement
    data = data * dv * 4.75;
    if nargout > 1
    t = [0:255]';
    end
    if nargout == 0
        plot(data);
    end
    
end

function out = dsorecords(stream)
    out = [];
    
    % strip leading junk
    strec = find( (stream(1:end-1) == 6) & (stream(2:end) == 3) );
    
    for k=strec
        recnum = stream(k+2);
        rectype = stream(k+3);
        if rectype ~= 127
            
            continue;
        end
        record = stream(k+4:k+19);
        
        out(recnum+1,:) = record;
    end
    out
    
end

        
    function out = dso2vec(s)
    
    out = [];
    while length(s) > 0
        if s(1) == '<'
            out = [out hex2dec(s(2:3))];
            s = s(5:end);
        else
            out = [out double(s(1))];
            s = s(2:end);
        end
    end
    end
    end
end