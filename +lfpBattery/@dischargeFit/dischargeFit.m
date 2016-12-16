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
    end
    properties (Hidden, GetAccess = 'protected', SetAccess = 'immutable')
        f; % Nernst-fit (function Handle)
        dod; % x data (raw DoD) of initial fit curve
        V_raw; % y data (OC voltage) of initial fit curve
        Cdmax; % maximum of discharge capacity (used for conversion between dod & C_dis)
    end
    properties (Constant, Hidden, GetAccess = 'protected')
        % lsqcurvefit options
        options = optimoptions('lsqcurvefit', 'Algorithm', 'levenberg-marquardt',...
            'Display', 'off', ... % suppress command window output
            'FiniteDifferenceType', 'central', ... % should be more precise than 'forward'
            'FunctionTolerance', 1e-12, ...
            'MaxIterations', 1e10, ...
            'OptimalityTolerance', 1e-12, ...
            'StepTolerance', 1e-12, ...
            'MaxFunctionEvaluations', 1e10);
        MINARGS = 4; % minumum number of input args for constructor
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
                d.f = @(x, xdata)(x(1) - (lfpBattery.const.R .* Temp) ...
                        ./ (lfpBattery.const.z_Li .* lfpBattery.const.F) ...
                        .* log(xdata./(1-xdata)) + x(2) .* xdata + x(3)) ...
                    + ((x(4) + (x(5) + x(4).*x(6)).*xdata) .* exp(-x(6).*xdata)) ... % exponential drop at the beginning of the discharge curve
                    + (x(7) .* exp(-x(8) .* xdata) + x(9)); % exponential drop at the end of the discharge curve
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
                x = [E0; Ea; Eb; Aex; Bex; Cex; x0; v0; delta];
                d.px = lsqcurvefit(d.f, x, d.dod(1:end-1), d.V_raw(1:end-1), [], [], d.options);
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
            d.px = lsqcurvefit(d.f, d.px, d.dod(1:end-1), d.V_raw(1:end-1), [], [], d.options);
        end
        function set.xs(d, params)
            assert(numel(params) == 3, 'Wrong number of params')
            d.px(4:6) = params(:);
            d.px = lsqcurvefit(d.fs, d.px, d.dod(1:end-1), d.V_raw(1:end-1), [], [], d.options);
        end
        function set.xe(d, params)
            assert(numel(params) == 3, 'Wrong number of params')
            d.px(7:9) = params(:);
            d.px = lsqcurvefit(d.fe, d.px, d.dod(1:end-1), d.V_raw(1:end-1), [], [], d.options);
        end
        
        %% Dependent getters
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
    
end

