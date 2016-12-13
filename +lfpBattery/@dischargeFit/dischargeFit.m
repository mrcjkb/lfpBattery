classdef dischargeFit < handle
    %DISCHARGEFIT: Uses Levenberg-Marquardt algorithm to fit a
    %discharge curve of a lithium-ion battery in three parts:
    %1: exponential drop at the beginning of the discharge curve
    %2: according to the nernst-equation
    %3: exponential drop at the end of the discharge curve
    %
    %Syntax:
    %   d = dischargeFit(V, C_dis, E0, Ea, Eb, Aex, Bex, Cex, ...
    %                       x0, v0, delta, st, en, C, T);
    %
    %Input arguments:
    %   V:              Voltage (V) = f(C_dis) (from data sheet)
    %   C_dis:          Discharge capacity (Ah) (from data sheet)
    %   E0, Ea, Eb:     Parameters for Nernst fit (initial estimations)
    %   Aex, Bex, Cex:  Parameters for fit of exponential drop at
    %                   the beginning of the curve (initial estimations)
    %   x0, v0, delta:  Parameters for fit of exponential drop at
    %                   the end of the curve (initial estimations)
    %   st:             starting index of the nernst fit
    %   en:             ending index of the nernst fit
    %   C:              C-Rate at which curve was measured
    %   T:              Temperature (K) at which curve was measured
    %
    % Authors:  Marc Jakobi, Festus Anyangbe, Marc Schmidt,
    % December 2016
    
    properties (Dependent)
        x; % 3 parameters for f
        xs; % 3 parameters for fs
        xe; % 3 parameters for fe
        nernstInds; % start and end index of nernst fit range [st, en]
    end
    properties (Dependent, SetAccess = 'protected')
        rmse; % root mean squared error of fit
        dV_mean; % mean difference in voltage between fit and raw data
        dV_max; % max difference in voltage between fit and raw data
    end
    properties (Dependent, Hidden, SetAccess = 'protected', GetAccess = 'protected')
       Cd_raw; % x data (raw discharge capacity) of initial fit curve
       e_f; % nernst differences
       e_fs; % beginning differences
       e_fe; % end differences
       e_tot; % total differences
    end
    properties (Hidden, GetAccess = 'protected', SetAccess = 'protected')
        stD; % DoD at starting index of the nernst fit
        enD; % DoD at ending index of the nernst fit
        stI; % start index of nernst part of curve
        enI; % end index of nernst part of curve
        px; % parameters for f
        pxs; % parameters for fs
        pxe; % parameters for fe
    end
    properties (Hidden, GetAccess = 'protected', SetAccess = 'immutable')
        f; % Nernst-fit (function Handle)
        dod; % x data (raw DoD) of initial fit curve
        V_raw; % y data (OC voltage) of initial fit curve
        Cdmax; % maximum of discharge capacity (used for conversion between dod & C_dis)
        C; % C-Rate at which curve was measured
    end
    properties (Constant, Hidden, GetAccess = 'protected')
        options = optimoptions('lsqcurvefit', 'Algorithm', 'levenberg-marquardt',...
            'Display', 'off'); % lsqcurvefit options
        fs = @(x, xdata)((x(1) + (x(2) + x(1).*x(3)).*xdata) .* exp(-x(3).*xdata)); % exponential drop at the beginning of the discharge curve (function handle)
        fe = @(x, xdata)(x(1) .* exp(-x(2) .* xdata) + x(3)); % exponential drop at the end of the discharge curve (function handle)
        MINARGS = 6; % minumum number of input args for constructor
    end
    methods
        % Constructor
        function d = dischargeFit(V, C_dis, CRate, Temp, st, en, E0, Ea, Eb, Aex, Bex, Cex, x0, v0, delta)
            %DISCHARGEFIT: Uses Levenberg-Marquardt algorithm to fit a
            %discharge curve of a lithium-ion battery in three parts:
            %1: exponential drop at the beginning of the discharge curve
            %2: according to the nernst-equation
            %3: exponential drop at the end of the discharge curve
            %
            %Syntax:
            %   d = dischargeFit(V, C_dis, E0, Ea, Eb, Aex, Bex, Cex, ...
            %                       x0, v0, delta, st, en, C, T);
            %
            %Input arguments:
            %   V:              Voltage (V) = f(C_dis) (from data sheet)
            %   C_dis:          Discharge capacity (Ah) (from data sheet)
            %   E0, Ea, Eb:     Parameters for Nernst fit (initial estimations)
            %   Aex, Bex, Cex:  Parameters for fit of exponential drop at
            %                   the end of the curve (initial estimations)
            %   x0, v0, delta:  Parameters for fit of exponential drop at
            %                   the beginning of the curve (initial estimations)
            %   st:             starting index of the nernst fit
            %   en:             ending index of the nernst fit
            %   C:              C-Rate at which curve was measured
            if nargin < d.MINARGS
                error('Not enough input arguments')
            else
                d.Cdmax = max(C_dis);
                d.dod = C_dis ./ d.Cdmax; % Conversion to depth of discharge
                d.C = CRate;
                d.V_raw = V;
                d.f = @(x, xdata)(x(1) - (lfpBattery.const.R .* Temp) ...
                        ./ (lfpBattery.const.z_Li .* lfpBattery.const.F) ...
                        .* log(xdata./(1-xdata)) + x(2) .* xdata + x(3));
                d.stI = st;
                d.enI = en;
                d.stD = d.dod(st);
                d.enD = d.dod(en);
                % Fit params optional for initialization
                if nargin < 15
                    delta = 0;
                    if nargin < 14
                        v0 = 0;
                        if nargin < 13
                            x0 = 0;
                            if nargin < 12
                                Cex = 0;
                                if nargin < 11
                                    Bex = 0;
                                    if nargin < 10
                                        Aex = 0;
                                        if nargin < 9
                                            Eb = 0;
                                            if nargin < 8
                                                Ea = 0;
                                                if nargin < 7
                                                    E0 = 0;
                                                end
                                            end
                                        end
                                    end
                                end
                            end
                        end
                    end
                end
                d.x = [E0; Ea; Eb];
                d.xe = [Aex; Bex; Cex];
                d.xs = [x0; v0; delta];
            end
        end
        function v = discharge(d, C_dis)
            %DISCHARGE: Calculate the voltage for a given discharge capacity
            %
            %Syntax: v = discharge(d, C_dis)
            %        v = d.discharge(C_dis)
            %
            %Input arguments:
            %   d:      dischargeFit
            %   C_dis:  discharge capacity (Ah)
            %
            %Output arguments:
            %   v:      Resulting open circuit voltage (V)
            
            DoD = C_dis ./ d.Cdmax; % conversion to DoD
            v = nan(size(DoD));
            is = DoD <= d.stD; % exp. drop at beginning
            ie = DoD >= d.enD; % exp. drop at end
            in = DoD > d.stD & DoD < d.enD; % nernst          
            % apply fits
            v(is) = d.fs(d.xs, DoD(is));
            v(ie) = d.fe(d.xe, DoD(ie));
            v(in) = d.f(d.x, DoD(in));
        end
        function plotResults(d)
            %PLOTRESULTS: Compares a scatter of the raw data with the fit
            %in a figure window.
            C_dis = linspace(min(d.Cd_raw), max(d.Cd_raw), 1000);
            figure;
            hold on
            scatter(d.Cd_raw, d.V_raw, 'filled', 'MarkerFaceColor', lfpBattery.const.red)
            plot(C_dis, d.discharge(C_dis), 'Color', lfpBattery.const.green, ...
                'LineWidth', 2)
            legend('raw data', 'fit', 'Location', 'Best')
            xlabel('discharge capacity / Ah')
            ylabel('voltage / V')
            title({['rmse = ', num2str(d.rmse)]; ...
                ['mean(\DeltaV) = ', num2str(d.dV_mean), ' V']; ...
                ['max(\DeltaV) = ', num2str(d.dV_max), ' V']})
            grid on
        end
        %% Dependent setters:
        function set.x(d, params)
            assert(numel(params) == 3, 'Wrong number of params')
            d.px = lsqcurvefit(d.f, params, d.dod(d.stI:d.enI), d.V_raw(d.stI:d.enI), [], [], d.options);
        end
        function set.xs(d, params)
            assert(numel(params) == 3, 'Wrong number of params')
            d.pxs = lsqcurvefit(d.fs, params, d.dod(1:d.stI), d.V_raw(1:d.stI), [], [], d.options);
        end
        function set.xe(d, params)
            assert(numel(params) == 3, 'Wrong number of params')
            d.pxe = lsqcurvefit(d.fe, params, d.dod(d.enI:end), d.V_raw(d.enI:end), [], [], d.options);
        end
        function set.nernstInds(d, inds)
           assert(numel(inds) == 2, 'Wrong number of indexes')
           d.stI = inds(1);
           d.enI = inds(2);
           d.stD = d.dod(inds(1));
           d.enD = d.dod(inds(2));
           d.px = lsqcurvefit(d.f, d.px, d.dod(d.stI:d.enI), d.V_raw(d.stI:d.enI), [], [], d.options);
           d.pxs = lsqcurvefit(d.fs, d.pxs, d.dod(1:d.stI), d.V_raw(1:d.stI), [], [], d.options);
           d.pxe = lsqcurvefit(d.fe, d.pxe, d.dod(d.enI:end), d.V_raw(d.enI:end), [], [], d.options);
        end
        %% Dependent getters
        function params = get.x(d)
            params = d.px;
        end
        function params = get.xs(d)
            params = d.pxs;
        end
        function params = get.xe(d)
            params = d.pxe;
        end
        function inds = get.nernstInds(d)
            inds = [d.stI, d.enI];
        end
        function r = get.rmse(d)
            % fit errors
            r = sqrt(sum(d.e_tot.^2)); % root mean squared error
        end
        function e = get.e_f(d)
            e = d.f(d.x, d.dod(d.stI:d.enI)) - d.V_raw(d.stI:d.enI);
        end
        function e = get.e_fs(d)
            e = d.fs(d.xs, d.dod(1:d.stI)) - d.V_raw(1:d.stI);
        end
        function e = get.e_fe(d)
            e = d.fe(d.xe, d.dod(d.enI:end)) - d.V_raw(d.enI:end);
        end
        function e = get.e_tot(d)
           e = [d.e_f(:); d.e_fs(:); d.e_fe(:)]; 
        end
        function e = get.dV_mean(d)
            e = mean(d.e_tot);
        end
        function e = get.dV_max(d)
            e = max(d.e_tot);
        end
        function c = get.Cd_raw(d)
           c = d.dod .* d.Cdmax; 
        end
    end
    
end

