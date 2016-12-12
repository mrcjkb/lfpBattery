classdef dischargeFit < handle
    %DISCHARGEFIT: Class for fitting discharge curves
    properties
        rmse; % root mean squared error of fit
    end
    properties %(Hidden)%, GetAccess = 'protected', SetAccess = 'protected')
        f; % Nernst-fit (function Handle)
        fs; % exponential drop at the beginning of the discharge curve (function handle)
        fe; % exponential drop at the end of the discharge curve (function handle)
        x; % parameters for f
        xs; % parameters for fs
        xe; % parameters for fe
        stD; % DoD at starting index of the nernst fit
        enD; % DoD at ending index of the nernst fit
        Cmax; % maximum of discharge capacity (used for conversion between dod & C_dis)
        T; % Temperature at which curve was recorded
    end
    methods
        % MTODO: Constructor
        function d = dischargeFit(V, C_dis, E0, Ea, Eb, Aex, Bex, Cex, x0, v0, delta, ...
                st, en, Temp)
            %DISCHARGEFIT: Uses Levenberg-Marquardt algorithm to fit a
            %discharge curve of a lithium-ion battery in three parts:
            %1: exponential drop at the beginning of the discharge curve
            %2: according to the nernst-equation
            %3: exponential drop at the end of the discharge curve
            %
            %Syntax:
            %   d = dischargeFit(V, C_dis, E0, Ea, Eb, Aex, Bex, Cex, x0, v0, delta, st, en)
            %   d = dischargeFit(V, C_dis, E0, Ea, Eb, Aex, Bex, Cex, x0, v0, delta, st, en, Temp)
            %
            %Input arguments:
            %   V:              Voltage = f(C_dis) from data sheet
            %   C_dis:          Discharge capacity (from data sheet)
            %   E0, Ea, Eb:     Parameters for Nernst fit (initial estimations)
            %   Aex, Bex, Cex:  Parameters for fit of exponential drop at
            %                   the beginning of the curve (initial estimations)
            %   x0, v0, delta:  Parameters for fit of exponential drop at
            %                   the end of the curve (initial estimations)
            %   st:             starting index of the nernst fit
            %   en:             ending index of the nernst fit
            %   T:              Temperature at which curve was measured
            %
            % Authors:  Marc Jakobi, Festus Anyangbe, Marc Schmidt,
            % December 2016
            
            if nargin < 12 % Default: room temperature
                d.T = lfpBattery.const.T_room;
            else
                d.T = Temp;
            end
            d.Cmax = max(C_d);
            dod = C_dis ./ d.Cmax; % Conversion to depth of discharge
            options = optimoptions('lsqcurvefit', 'Algorithm', 'levenberg-marquardt');
            %nernst fit
            d.f = @(x, xdata)(x(1) - (lfpBattery.const.R .* d.T) ...
                ./ (lfpBattery.const.z .* lfpBattery.const.F) ...
                .* log(xdata./(1-xdata)) + x(2) .* xdata + x(3));
            % MTODO: disable workspace output
            d.x = lsqcurvefit(f, [E0; Ea; Eb], dod(st:en), V(st:en), [], [], options);
            e_f = d.f(d.x, dod(st:en)) - V(st:en); % fit errors
            % Exponential drop (beginning of curve)
            d.fs = @(x, xdata)((x(1) + (x(2) + x(1).*x(3)).*xdata) .* exp(-x(3).*xdata));
            d.xs = lsqcurvefit(fs, [x0; v0; delta], dod(1:st), V(1:st), [], [], options);
            e_fs = fs(xs, dod(1:st)) - V(1:st);
            % Exponential drop (end of curve)
            d.fe = @(x, xdata)(x(1) .* exp(-x(2) .* xdata) + x(3));
            d.xe = lsqcurvefit(fe, [Aex; Bex; Cex], dod(en:end), V(en:end), [], [], options);
            e_fe = d.fe(d.xe, dod(en:end)) - V(en:end); % fit errors
            d.rmse = sqrt(sum([e_f(:); e_fs(:); e_fe(:)].^2)); % root mean squared error
            d.stD = dod(st);
            d.enD = dod(en);
        end
        % MTODO: apply method
    end
    
end

