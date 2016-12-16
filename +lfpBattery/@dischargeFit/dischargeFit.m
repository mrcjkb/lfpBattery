classdef dischargeFit < handle
    %DISCHARGEFIT: Uses Levenberg-Marquardt algorithm to fit a
    %discharge curve of a lithium-ion battery in three parts:
    %1: exponential drop at the beginning of the discharge curve
    %2: according to the nernst-equation
    %3: exponential drop at the end of the discharge curve
    %
    %Syntax:
    %   d = dischargeFit(V, C_dis, C, T);
    %           --> initialization of curve fit params with zeros
    %
    %   d = dischargeFit(V, C_dis, C, T, E0, Ea, Eb, Aex, Bex, Cex, x0, v0, delta);
    %           --> custom initialization of curve fit params
    %
    %Input arguments:
    %   V:              Voltage (V) = f(C_dis) (from data sheet)
    %   C_dis:          Discharge capacity (Ah) (from data sheet)
    %   C:              C-Rate at which curve was measured
    %   T:              Temperature (K) at which curve was mearured
    %
    %Optional input arguments:
    %   E0, Ea, Eb:     Parameters for Nernst fit (initial estimations)
    %   Aex, Bex, Cex:  Parameters for fit of exponential drop at
    %                   the end of the curve (initial estimations)
    %   x0, v0, delta:  Parameters for fit of exponential drop at
    %                   the beginning of the curve (initial estimations)
    %
    % Authors:  Marc Jakobi, Festus Anyangbe, Marc Schmidt,
    % December 2016
    
    properties (SetAccess = 'immutable')
       C; % C-Rate at which curve was measured
    end
    properties (Dependent)
        x; % 3 parameters for f
        xs; % 3 parameters for fs
        xe; % 3 parameters for fe
        mode; % function used for fitting ('fmin' for fminsearch or 'lsq' for lsqcurvefit)
    end
    properties (Dependent, SetAccess = 'protected')
        rmse; % root mean squared error of fit
        dV_mean; % mean difference in voltage between fit and raw data
        dV_max; % max difference in voltage between fit and raw data
    end
    properties (Dependent, Hidden, SetAccess = 'protected', GetAccess = 'protected')
       Cd_raw; % x data (raw discharge capacity) of initial fit curve
       e_tot; % total differences
    end
    properties (Hidden, GetAccess = 'protected', SetAccess = 'protected')
        px; % parameters for f
        fmin = true; % true for fminsearch, false for lsqcurvefit
    end
    properties (Hidden, GetAccess = 'protected', SetAccess = 'immutable')
        f; % Fit function Handle
        dod; % x data (raw DoD) of initial fit curve
        V_raw; % y data (OC voltage) of initial fit curve
        Cdmax; % maximum of discharge capacity (used for conversion between dod & C_dis)
    end
    properties (Constant, Hidden, GetAccess = 'protected')
        sseval = @(x, fdata, ydata) sum((ydata - fdata).^2); % calculation of sum squared error
        fmsoptions = optimset('Algorithm','levenberg-marquardt', ... % fminsearch options
            'Display', 'off', ...
            'MaxFunEvals', 1e10, ... 
            'MaxIter', 1e10);
        lsqoptions = optimoptions('lsqcurvefit', 'Algorithm', 'levenberg-marquardt',... % lsqcurvefit options
            'Display', 'off', ...
            'FiniteDifferenceType', 'central', ... % should be more precise than 'forward'
            'FunctionTolerance', 1e-12, ...
            'MaxIterations', 1e10, ...
            'OptimalityTolerance', 1e-12, ...
            'StepTolerance', 1e-12, ...
            'MaxFunctionEvaluations', 1e10);
        MINARGS = 4; % minumum number of input args for constructor
        MAXARGS = 13; % maximum number of input args for constructor
    end
    methods
        % Constructor
        function d = dischargeFit(V, C_dis, CRate, Temp, E0, Ea, Eb, Aex, Bex, Cex, x0, v0, delta)
            %DISCHARGEFIT: Uses Levenberg-Marquardt algorithm to fit a
            %discharge curve of a lithium-ion battery in three parts:
            %1: exponential drop at the beginning of the discharge curve
            %2: according to the nernst-equation
            %3: exponential drop at the end of the discharge curve
            %
            %Syntax:
            %   d = dischargeFit(V, C_dis, C, T);
            %           --> initialization of curve fit params with zeros
            %
            %   d = dischargeFit(V, C_dis, C, T, E0, Ea, Eb, Aex, Bex, Cex, x0, v0, delta);
            %           --> custom initialization of curve fit params
            %
            %Input arguments:
            %   V:              Voltage (V) = f(C_dis) (from data sheet)
            %   C_dis:          Discharge capacity (Ah) (from data sheet)
            %   C:              C-Rate at which curve was measured
            %   T:              Temperature (K) at which curve was mearured
            %
            %Optional input arguments:
            %   E0, Ea, Eb:     Parameters for Nernst fit (initial estimations)
            %   Aex, Bex, Cex:  Parameters for fit of exponential drop at
            %                   the end of the curve (initial estimations)
            %   x0, v0, delta:  Parameters for fit of exponential drop at
            %                   the beginning of the curve (initial estimations)
            
            if nargin < d.MINARGS
                error('Not enough input arguments')
            else
                d.Cdmax = max(C_dis);
                d.dod = C_dis ./ d.Cdmax; % Conversion to depth of discharge
                d.C = CRate;
                d.V_raw = V;
                d.f = @(x, xdata)(x(1) - (lfpBattery.const.R .* Temp) ... % Nernst
                        ./ (lfpBattery.const.z_Li .* lfpBattery.const.F) ...
                        .* log(xdata./(1-xdata)) + x(2) .* xdata + x(3)) ...
                    + ((x(4) + (x(5) + x(4).*x(6)).*xdata) .* exp(-x(6).*xdata)) ... % exponential drop at the beginning of the discharge curve
                    + (x(7) .* exp(-x(8) .* xdata) + x(9)); % exponential drop at the end of the discharge curve
                % Fit params optional for initialization
                if nargin < d.MAXARGS
                    delta = 0;
                    if nargin < d.MAXARGS - 1
                        v0 = 0;
                        if nargin < d.MAXARGS - 2
                            x0 = 0;
                            if nargin < d.MAXARGS - 3
                                Cex = 0;
                                if nargin < d.MAXARGS - 4
                                    Bex = 0;
                                    if nargin < d.MAXARGS - 5
                                        Aex = 0;
                                        if nargin < d.MAXARGS - 6
                                            Eb = 0;
                                            if nargin < d.MAXARGS - 7
                                                Ea = 0;
                                                if nargin < d.MAXARGS - 8
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
                d.px = [E0; Ea; Eb; Aex; Bex; Cex; x0; v0; delta];
                d.fit;
            end
        end
        function v = subsref(d, S)
            %DISCHARGE: Calculate the voltage for a given discharge capacity
            %
            %Syntax: v = d(C_dis)
            %
            %Input arguments:
            %   d:      dischargeFit object
            %   C_dis:  discharge capacity (Ah)
            %
            %Output arguments:
            %   v:      Resulting open circuit voltage (V)
            if strcmp(S.type, '()')
                if numel(S.subs) > 1
                    error('Cannot index dischargeFit')
                end
                C_dis = S.subs{1};
                DoD = max(0, min(C_dis ./ d.Cdmax, 1)); % conversion to DoD
                v = d.f(d.px, DoD);
            elseif nargout == 1
                v = builtin('subsref', d, S);
            else
                builtin('subsref', d, S);
            end
        end
        function plotResults(d)
            %PLOTRESULTS: Compares a scatter of the raw data with the fit
            %in a figure window.
            C_dis = linspace(min(d.Cd_raw), max(d.Cd_raw), 1000)';
            figure;
            hold on
            scatter(d.Cd_raw, d.V_raw, 'filled', 'MarkerFaceColor', lfpBattery.const.red)
            plot(C_dis, d.f(d.px, C_dis./d.Cdmax), 'Color', lfpBattery.const.green, ...
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
            d.px(1:3) = params(:);
            d.fit;
        end
        function set.xs(d, params)
            assert(numel(params) == 3, 'Wrong number of params')
            d.px(4:6) = params(:);
            d.fit;
        end
        function set.xe(d, params)
            assert(numel(params) == 3, 'Wrong number of params')
            d.px(7:9) = params(:);
            d.fit;
        end
        function set.mode(d, str)
            validatestring(str, {'lsq', 'fmin'});
            if ~strcmp(d.mode, str)
                if strcmp(str, 'fmin')
                    d.fmin = true;
                else
                    d.fmin = false;
                end
                d.fit;
            end
        end
        
        %% Dependent getters
        function m = get.mode(d)
           if d.fmin
               m = 'fmin';
           else
               m = 'lsq';
           end
        end
        function params = get.x(d)
            params = d.px(1:3);
        end
        function params = get.xs(d)
            params = d.px(4:6);
        end
        function params = get.xe(d)
            params = d.px(7:9);
        end
        function r = get.rmse(d)
            % fit errors
            r = sqrt(sum(d.e_tot.^2)); % root mean squared error
        end
        function e = get.e_tot(d)
            e = d.f(d.px, d.dod(1:end-1)) - d.V_raw(1:end-1);
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
    methods (Access = 'protected')
        function d = fit(d)
            if d.fmin
                fun = @(x) d.sseval(x, d.f(x, d.dod(1:end-1)), d.V_raw(1:end-1));
                d.px = fminsearch(fun, d.px, d.fmsoptions);
            else
                d.px = lsqcurvefit(d.f, d.px, d.dod(1:end-1), d.V_raw(1:end-1), [], [], d.lsqoptions);
            end
        end
    end
    
end

